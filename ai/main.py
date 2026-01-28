import websocket  # websocket-client
import uuid
import json
import urllib.request
import urllib.parse
import random
from PIL import Image
import io
from termcolor import colored
from dotenv import load_dotenv
import os
from flask import Flask, request, send_file, jsonify
from flask_cors import CORS
import requests
import base64

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Step 1: Initialize the connection settings and load environment variables
print(colored("Step 1: Initialize the connection settings and load environment variables.", "cyan"))
print(colored("Loading configuration from the .env file.", "yellow"))
load_dotenv()

# Get server address from environment variable, default to "localhost:8188" if not set
server_address = os.getenv('COMFYUI_SERVER_ADDRESS', 'localhost:8188')
client_id = str(uuid.uuid4())

# Display the server address and client ID for transparency
print(colored(f"Server Address: {server_address}", "magenta"))
print(colored(f"Generated Client ID: {client_id}", "magenta"))

# Queue prompt function
def queue_prompt(prompt):
    p = {"prompt": prompt, "client_id": client_id}
    data = json.dumps(p, indent=4).encode('utf-8')  # Prettify JSON for print
    try:
        req = urllib.request.Request(f"http://{server_address}/prompt", data=data)
        return json.loads(urllib.request.urlopen(req).read())
    except Exception as e:
        print(colored(f"Error executing prompt: {e}", "red"))
        return None

# Get image function
def get_image(filename, subfolder, folder_type):
    data = {"filename": filename, "subfolder": subfolder, "type": folder_type}
    url_values = urllib.parse.urlencode(data)
    
    print(colored(f"Fetching image from the server: {server_address}/view", "cyan"))
    with urllib.request.urlopen(f"http://{server_address}/view?{url_values}") as response:
        return response.read()

# Get history for a prompt ID
def get_history(prompt_id):
    print(colored(f"Fetching history for prompt ID: {prompt_id}.", "cyan"))
    with urllib.request.urlopen(f"http://{server_address}/history/{prompt_id}") as response:
        return json.loads(response.read())

# Get images from the workflow
def get_images(ws, prompt, socket_id=None):
    prompt_response = queue_prompt(prompt)
    if not prompt_response:
        return None
    prompt_id = prompt_response['prompt_id']
    output_images = {}

    print(colored("Step 6: Start listening for progress updates via the WebSocket connection.", "cyan"))

    while True:
        out = ws.recv()
        if isinstance(out, str):
            message = json.loads(out)
            if message['type'] == 'progress':
                data = message['data']
                current_progress = data['value']
                max_progress = data['max']
                percentage = int((current_progress / max_progress) * 100)
                print(colored(f"Progress: {percentage}% in node {data['node']}", "yellow"))

            elif message['type'] == 'executing':
                data = message['data']
                if data['node'] is None and data['prompt_id'] == prompt_id:
                    print(colored("Execution complete.", "green"))
                    break  # Execution is done
                    break  # Execution is done
        else:
            if socket_id:
               # Handle binary preview
               try:
                  if isinstance(out, bytes):
                        print(colored(f"🔹 [AI Server] Received binary data: {len(out)} bytes", "magenta"))
                        # The first 8 bytes are the type (PREVIEW_IMAGE)
                        # We can just assume it's an image for now if we know config
                        # Actually Comfy returns JPEG preview in bytes
                        # Let's skip first 8 bytes if they are header (int type + int size?)
                        # Standard ComfyUI websocket preview format:
                        # 4 bytes type (1=preview)
                        # 4 bytes size
                        # json header... logic is complex.
                        # BUT default behavior simplifies to just sending the blob.
                        
                        # Simplified Check: Just converting bytes to base64 and sending
                        # ComfyUI sends: Type (4 bytes) + Size (4 bytes) + JSON (Size bytes) + JPEG
                        
                        # Let's try to just be simple: if it's binary, it might be the preview image directly or wrapped.
                        # For now, let's just ignore the complex parsing and try to send "something" if it looks like an image,
                        # OR, safer: relied on the fact that ComfyUI usually saves previews to temp folder and notifies path?
                        # No, default is binary stream.
                        
                        # Let's use a simpler approach: Just send "generating..." event if we can't parse easily?
                        # No user wants to see image.
                        
                        # Let's try to slice the header.
                        # If we assume it is the standard binary preview:
                        offset = 8 # Type + Image Type
                        # Actually, let's just try to base64 encode the whole thing minus first 8 bytes if it fails.
                        # A better way is to see existing implementations.
                        # For now, we will try to just base64 encode the raw bytes.
                        # If it fails on frontend, we can refine.
                        
                        # Correct offset for a standard jpeg preview from ComfyUI WS:
                        # 4 bytes BE integer = type (1)
                        image_data = out[8:]
                        
                        try:
                            # Downscale for efficiency
                            img = Image.open(io.BytesIO(image_data))
                            img.thumbnail((256, 256))
                            buffered = io.BytesIO()
                            img.save(buffered, format="JPEG", quality=70)
                            b64_image = base64.b64encode(buffered.getvalue()).decode('utf-8')
                            
                            print(colored(f"📤 [AI Server] Sending downscaled preview to relay for socket: {socket_id}", "magenta"))
                            requests.post("http://localhost:5001/relay", json={
                                "socketId": socket_id,
                                "event": "preview",
                                "data": {"image": f"data:image/jpeg;base64,{b64_image}"}
                            })
                        except Exception as e:
                            # Fallback to original if PIL fails
                            print(colored(f"⚠️ PIL downscale failed, falling back to raw: {e}", "yellow"))
                            b64_image = base64.b64encode(image_data).decode('utf-8')
                            requests.post("http://localhost:5001/relay", json={
                                "socketId": socket_id,
                                "event": "preview",
                                "data": {"image": f"data:image/jpeg;base64,{b64_image}"}
                            })
                  else:
                       # pass
                       pass
               except Exception as e:
                   print(colored(f"Error streaming preview: {e}", "red"))
            continue

    # Fetch history and images after completion
    print(colored("Step 7: Fetch the history and download the images after execution completes.", "cyan"))

    history = get_history(prompt_id)[prompt_id]
    for o in history['outputs']:
        for node_id in history['outputs']:
            node_output = history['outputs'][node_id]
            if 'images' in node_output:
                images_output = []
                for image in node_output['images']:
                    print(colored(f"Downloading image: {image['filename']} from the server.", "yellow"))
                    image_data = get_image(image['filename'], image['subfolder'], image['type'])
                    images_output.append(image_data)
                output_images[node_id] = images_output

    return output_images

# Generate images function with customizable input
def generate_images(positive_prompt, negative_prompt="", steps=25, resolution=(512, 512), socket_id=None):
    # Step 3: Establish WebSocket connection
    ws = websocket.WebSocket()
    ws_url = f"ws://{server_address}/ws?clientId={client_id}"
    print(colored(f"Step 3: Establishing WebSocket connection to {ws_url}", "cyan"))
    try:
        ws.connect(ws_url)
    except Exception as e:
        print(colored(f"Failed to connect to WebSocket: {e}", "red"))
        return None, None

    # Step 4: Load workflow from file
    print(colored("Step 4: Loading the image generation workflow from 'workflow.json'.", "cyan"))
    try:
        with open("workflow.json", "r", encoding="utf-8") as f:
            workflow_data = f.read()
    except FileNotFoundError:
        print(colored("workflow.json not found.", "red"))
        return None, None

    workflow = json.loads(workflow_data)

    # Customize workflow based on inputs
    print(colored("Step 5: Customizing the workflow with the provided inputs.", "cyan"))
    
    # Update nodes with prompts
    # NOTE: You might need to adjust these IDs based on your specific workflow.json
    workflow["42"]["inputs"]["text"] = positive_prompt
    # workflow["7"]["inputs"]["text"] = negative_prompt

    workflow["41"]["inputs"]["steps"] = steps

    workflow["45"]["inputs"]["width"] = resolution[0]
    workflow["45"]["inputs"]["height"] = resolution[1]

    # Set a random seed for the KSampler node
    seed = random.randint(1, 1000000000)
    print(colored(f"Setting random seed for generation: {seed}", "yellow"))
    workflow["41"]["inputs"]["seed"] = seed

    # Fetch generated images
    images = get_images(ws, workflow, socket_id)

    # Step 8: Close WebSocket connection after fetching the images
    print(colored(f"Step 8: Closing WebSocket connection to {ws_url}", "cyan"))
    ws.close()

    return images, seed

# NEW: Iterative Generation Function
def generate_images_iterative(positive_prompt, negative_prompt="", total_steps=4, resolution=(512, 512), socket_id=None):
    # Establish WebSocket connection
    ws = websocket.WebSocket()
    ws_url = f"ws://{server_address}/ws?clientId={client_id}"
    print(colored(f"Establishing WebSocket connection to {ws_url}", "cyan"))
    try:
        ws.connect(ws_url)
    except Exception as e:
        print(colored(f"Failed to connect to WebSocket: {e}", "red"))
        return None, None

    # --- Step 1: Txt2Img (1 step) ---
    print(colored(">>> Starting Step 1: Txt2Img (1 step)", "blue"))
    try:
        with open("workflow.json", "r", encoding="utf-8") as f:
            workflow = json.load(f)
    except FileNotFoundError:
        print(colored("workflow.json not found.", "red"))
        return None, None

    # Customizing Txt2Img
    workflow["42"]["inputs"]["text"] = positive_prompt
    workflow["41"]["inputs"]["steps"] = 1 # Force 1 step
    workflow["45"]["inputs"]["width"] = resolution[0]
    workflow["45"]["inputs"]["height"] = resolution[1]
    
    seed = random.randint(1, 1000000000)
    workflow["41"]["inputs"]["seed"] = seed

    # Run Txt2Img
    images_output = get_images(ws, workflow, socket_id) # Need to handle socket_id inside get_images for intermediate previews if any
    
    if not images_output:
        print(colored("Txt2Img failed.", "red"))
        ws.close()
        return None, None

    # Extract the image from Txt2Img
    # Assuming the first output node has the image
    first_node = list(images_output.keys())[0]
    current_image_data = images_output[first_node][0] # Binary data
    
    # Send this intermediate result as a preview to frontend
    if socket_id:
        try:
             # Downscale for efficiency
             img = Image.open(io.BytesIO(current_image_data))
             img.thumbnail((256, 256))
             buffered = io.BytesIO()
             img.save(buffered, format="PNG") # Use PNG since it's likely a PNG from Comfy
             b64_image = base64.b64encode(buffered.getvalue()).decode('utf-8')
             
             requests.post("http://localhost:5001/relay", json={
                "socketId": socket_id,
                "event": "preview",
                "data": {"image": f"data:image/png;base64,{b64_image}"}
             })
             print(colored(f"Sent downscaled Txt2Img result as preview for socket: {socket_id}", "magenta"))
        except Exception as e:
             print(colored(f"Error sending preview: {e}", "red"))

    # Only continue if we have more steps
    if total_steps > 1:
        # Load Img2Img Workflow
        try:
            with open("img2img_workflow.json", "r", encoding="utf-8") as f:
                img2img_workflow_template = json.load(f)
        except FileNotFoundError:
            print(colored("img2img_workflow.json not found.", "red"))
            ws.close()
            return images_output, seed

        # Loop for refinement
        # We did 1 step (Txt2Img). Remaining: total_steps - 1.
        # Denoise range: 0.8 -> 0.0 (approx)
        
        remaining_steps = total_steps - 1
        
        for i in range(remaining_steps):
            print(colored(f">>> Starting Refinement Step {i+1}/{remaining_steps}", "blue"))
            
            # 1. Upload current image
            # We need to save binary to a temp file or upload directly? 
            # upload_image accepts bytes?
            # My upload_image impl:
            # files = {"image": (filename, image_data)}
            # It expects 'image_data' as bytes.
            
            temp_filename = f"temp_refine_{client_id}_{i}.png"
            upload_resp = upload_image(current_image_data, temp_filename)
            if not upload_resp:
                print(colored("Failed to upload intermediate image.", "red"))
                break
            
            uploaded_filename = upload_resp.get("name") # ComfyUI might rename it
            
            # 2. Configure Img2Img
            workflow = img2img_workflow_template.copy() # Shallow copy might be enough
            
            # Update Prompt
            workflow["42"]["inputs"]["text"] = positive_prompt
            
            # Update Input Image
            workflow["101"]["inputs"]["image"] = uploaded_filename
            
            # Update Steps (Request said "use 1 step" initially, maybe 1 step for refinement too?)
            # Let's use 2 steps for refinement to be safe, or 1 if user wants speed.
            # "each image step should be passed" implies we want to see change.
            workflow["41"]["inputs"]["steps"] = 1 # Keep it fast
            
            # Calculate Denoise
            # if remaining_steps = 1 (total 2), i=0. Denoise = 0.8?
            # i ranges 0 to remaining_steps-1.
            # We want start 0.8, end ~0.1
            
            if remaining_steps == 1:
                denoise = 0.5 # Single refinement
            else:
                progress = i / (remaining_steps - 1)
                # Linear interpolation: 0.8 -> 0.1
                denoise = 0.8 - (0.7 * progress)
            
            # Ensure it's not 0
            denoise = max(0.1, denoise)
            
            workflow["41"]["inputs"]["denoise"] = denoise
            workflow["41"]["inputs"]["seed"] = random.randint(1, 1000000000)

            print(colored(f"   Denoise: {denoise:.2f}", "yellow"))

            # 3. Run Img2Img
            images_output = get_images(ws, workflow, socket_id)
            if not images_output:
                print(colored("Img2Img failed.", "red"))
                break
                
            # 4. Get Result
            first_node = list(images_output.keys())[0]
            current_image_data = images_output[first_node][0]
            
            # 5. Send Preview
            if socket_id:
                try:
                     # Downscale for efficiency
                     img = Image.open(io.BytesIO(current_image_data))
                     img.thumbnail((256, 256))
                     buffered = io.BytesIO()
                     img.save(buffered, format="PNG")
                     b64_image = base64.b64encode(buffered.getvalue()).decode('utf-8')
                     
                     requests.post("http://localhost:5001/relay", json={
                        "socketId": socket_id,
                        "event": "preview",
                        "data": {"image": f"data:image/png;base64,{b64_image}"}
                     })
                     print(colored(f"Sent downscaled Refinement {i+1} result as preview.", "magenta"))
                except Exception as e:
                     print(colored(f"Error sending preview: {e}", "red"))

    ws.close()
    
    # Return the final images structure (mimicking original return)
    # Refactor to return dict expected by caller
    # caller expects: images, seed
    # images is dict {node_id: [bytes]}
    # We should return the LAST output
    
    return images_output, seed

# Legacy wrapper to keep signature if needed, or update caller to use generate_images_iterative
# Actually, I should replace the original function content with this logic?
# Or just call this from the route.

# Upload image to ComfyUI server
def upload_image(image_data, filename):
    print(colored(f"Uploading image: {filename} to {server_address}", "cyan"))
    try:
        files = {"image": (filename, image_data)}
        response = requests.post(f"http://{server_address}/upload/image", files=files)
        if response.status_code == 200:
            return response.json()
        else:
            print(colored(f"Failed to upload image: {response.status_code} - {response.text}", "red"))
            return None
    except Exception as e:
        print(colored(f"Error uploading image: {e}", "red"))
        return None

# Generate inpaint images function
def generate_inpaint_images(prompt, image_filename, mask_filename, steps=25):
    # Establish WebSocket connection
    ws = websocket.WebSocket()
    ws_url = f"ws://{server_address}/ws?clientId={client_id}"
    print(colored(f"Step 3: Establishing WebSocket connection to {ws_url}", "cyan"))
    try:
        ws.connect(ws_url)
    except Exception as e:
        print(colored(f"Failed to connect to WebSocket: {e}", "red"))
        return None, None

    # Load workflow from file
    print(colored("Step 4: Loading the inpaint workflow from 'inpaint_workflow.json'.", "cyan"))
    try:
        with open("inpaint_workflow.json", "r", encoding="utf-8") as f:
            workflow_data = f.read()
    except FileNotFoundError:
        print(colored("inpaint_workflow.json not found.", "red"))
        return None, None

    workflow = json.loads(workflow_data)

    # Customize workflow
    print(colored("Step 5: Customizing the inpaint workflow with the provided inputs.", "cyan"))

    # Update Node 45 (Positive Prompt)
    if "45" in workflow and "inputs" in workflow["45"]:
        workflow["45"]["inputs"]["text"] = prompt
    
    # Update Node 59 (Load Image)
    if "59" in workflow and "inputs" in workflow["59"]:
        workflow["59"]["inputs"]["image"] = image_filename
    
    # Update Node 97 (Load Mask)
    if "97" in workflow and "inputs" in workflow["97"]:
        workflow["97"]["inputs"]["image"] = mask_filename

    # Update Node 83 (KSampler)
    if "83" in workflow:
        seed = random.randint(1, 1000000000)
        print(colored(f"Setting random seed for generation: {seed}", "yellow"))
        workflow["83"]["inputs"]["seed"] = seed
        workflow["83"]["inputs"]["steps"] = steps
    else:
        seed = 0 # Default if KSampler missing? Should not happen if workflow is correct.
        print(colored("Warning: KSampler node 83 not found.", "red"))

    # Fetch generated images
    images = get_images(ws, workflow)

    # Close WebSocket connection
    print(colored(f"Step 8: Closing WebSocket connection to {ws_url}", "cyan"))
    ws.close()

    return images, seed

@app.route('/inpaint-image', methods=['POST'])
def generate_inpaint_route():
    print("!!! [AI Server] RECEIVED REQUEST ON /inpaint-image !!!")
    try:
        print(colored("🚀 [AI Server] Received request on /inpaint-image", "green", attrs=["bold"]))
        
        image_data = None
        mask_data = None
        image_filename = None
        mask_filename = None

        if request.is_json:
            print(colored("📝 [AI Server] Processing JSON request", "cyan"))
            data = request.json
            prompt = data.get('prompt')
            steps = int(data.get('steps', 25))
            
            image_input = data.get('image')
            mask_input = data.get('mask')

            if not image_input or not mask_input:
                 print(colored("❌ [AI Server] Error: Image or mask missing in JSON", "red"))
                 return jsonify({"error": "Image and mask are required"}), 400

            # 1. Process Image First (URL or Base64) to get size
            try:
                if image_input.startswith("http"):
                    print(colored(f"⬇️ [AI Server] Downloading image from URL: {image_input}", "cyan"))
                    img_resp = requests.get(image_input)
                    if img_resp.status_code != 200:
                         return jsonify({"error": "Failed to download image from URL"}), 400
                    image_data = img_resp.content
                else:
                    if "," in image_input:
                        image_input = image_input.split(",")[1]
                    image_data = base64.b64decode(image_input)
                
                image_filename = f"image_{uuid.uuid4()}.png"
                
                # Get Image Size for Mask Resizing
                pil_img = Image.open(io.BytesIO(image_data))
                img_width, img_height = pil_img.size
                print(colored(f"📸 [AI Server] Image Size: {img_width}x{img_height}", "blue"))

            except Exception as e:
                print(colored(f"❌ [AI Server] Error processing image: {e}", "red"))
                return jsonify({"error": "Invalid image input"}), 400

            # 2. Process Mask (Base64) and Resize
            try:
                if "," in mask_input:
                    mask_input = mask_input.split(",")[1]
                mask_data_raw = base64.b64decode(mask_input)
                
                # Convert transparent mask to white-on-black (grayscale)
                try:
                    pil_mask = Image.open(io.BytesIO(mask_data_raw))
                    print(colored(f"🎭 [AI Server] Original Mask Mode: {pil_mask.mode}, Size: {pil_mask.size}", "blue"))
                    
                    if pil_mask.mode == 'RGBA':
                        # Use alpha channel as the mask
                        pil_mask = pil_mask.split()[-1] 
                    elif pil_mask.mode == 'LA':
                        pil_mask = pil_mask.split()[-1]
                    else:
                        pil_mask = pil_mask.convert("L")
                    
                    # RESIZE MASK TO MATCH IMAGE
                    if pil_mask.size != (img_width, img_height):
                        print(colored(f"📐 [AI Server] Resizing mask from {pil_mask.size} to {img_width}x{img_height}", "yellow"))
                        pil_mask = pil_mask.resize((img_width, img_height), Image.Resampling.LANCZOS)
                        
                    output_buffer = io.BytesIO()
                    pil_mask.save(output_buffer, format="PNG")
                    mask_data = output_buffer.getvalue()
                except Exception as img_err:
                     print(colored(f"⚠️ [AI Server] Mask processing failed, using raw: {img_err}", "yellow"))
                     mask_data = mask_data_raw

                mask_filename = f"mask_{uuid.uuid4()}.png"
            except Exception as e:
                print(colored(f"❌ [AI Server] Error decoding mask: {e}", "red"))
                return jsonify({"error": "Invalid mask base64"}), 400
                
        else:
            # Multipart/Form-Data
            if 'image' not in request.files or 'mask' not in request.files:
                 print(colored("❌ [AI Server] Error: Image or mask file missing", "red"))
                 return jsonify({"error": "Image and mask files are required"}), 400
                 
            image_file = request.files['image']
            mask_file = request.files['mask']
            prompt = request.form.get('prompt')
            steps = int(request.form.get('steps', 25))
            
            image_data = image_file.read()
            mask_data_raw = mask_file.read()
            image_filename = image_file.filename
            mask_filename = mask_file.filename

            # Get image size
            pil_img = Image.open(io.BytesIO(image_data))
            img_width, img_height = pil_img.size
            
            # Process mask (reuse same logic as above)
            try:
                pil_mask = Image.open(io.BytesIO(mask_data_raw))
                if pil_mask.mode == 'RGBA' or pil_mask.mode == 'LA':
                    pil_mask = pil_mask.split()[-1]
                else:
                    pil_mask = pil_mask.convert("L")
                
                if pil_mask.size != (img_width, img_height):
                    pil_mask = pil_mask.resize((img_width, img_height), Image.Resampling.LANCZOS)
                
                output_buffer = io.BytesIO()
                pil_mask.save(output_buffer, format="PNG")
                mask_data = output_buffer.getvalue()
            except Exception as e:
                mask_data = mask_data_raw
        
        #共通 debug saving
        # Debug: Save input image & mask to disk
        try:
            with open("debug_image.png", "wb") as f:
                f.write(image_data)
            with open("debug_mask.png", "wb") as f:
                f.write(mask_data)
            print(colored("💾 [AI Server] Saved debug images (image.png & mask.png)", "magenta"))
        except Exception as e:
            print(colored(f"⚠️ [AI Server] Failed to save debug images: {e}", "yellow"))
        
        image_upload_resp = upload_image(image_data, image_filename)
        mask_upload_resp = upload_image(mask_data, mask_filename)

        if not image_upload_resp or not mask_upload_resp:
             return jsonify({"error": "Failed to upload images to ComfyUI"}), 500
             
        comfy_image_name = image_upload_resp.get("name")
        comfy_mask_name = mask_upload_resp.get("name")

        print(colored(f"🎨 [AI Server] Inpainting: prompt='{prompt}', steps={steps}", "blue"))

        images, seed = generate_inpaint_images(prompt, comfy_image_name, comfy_mask_name, steps)

        if not images:
            print(colored("❌ [AI Server] Error: Failed to generate images", "red"))
            return jsonify({"error": "Failed to generate images"}), 500

        # Retrieve the first image found
        for node_id in images:
            for image_data in images[node_id]:
                print(colored(f"✅ [AI Server] Sending generated image back (seed: {seed})", "green"))
                return send_file(
                    io.BytesIO(image_data),
                    mimetype='image/png',
                    as_attachment=False,
                    download_name=f"inpainted-{seed}.png"
                )

        print(colored("❌ [AI Server] Error: No images found in output", "red"))
        return jsonify({"error": "No images generated"}), 500

    except Exception as e:
        print(colored(f"🔥 [AI Server] UNEXPECTED CRITICAL ERROR: {str(e)}", "red", attrs=["bold"]))
        import traceback
        traceback.print_exc()
        return jsonify({"error": f"Internal server error: {str(e)}"}), 500

@app.route('/generate-image', methods=['POST'])
def generate_image_route():
    print("!!! [AI Server] RECEIVED REQUEST ON /generate-image !!!")
    try:
        print(colored("🚀 [AI Server] Received request on /generate-image", "green", attrs=["bold"]))
        data = request.json
        print(colored(f"📦 [AI Server] Request data: {json.dumps(data, indent=2)}", "white"))

        if not data or 'prompt' not in data:
            print(colored("❌ [AI Server] Error: No prompt provided", "red"))
            return jsonify({"error": "No prompt provided"}), 400

        positive_prompt = data['prompt']
        negative_prompt = data.get('negative_prompt', "")
        steps = data.get('steps', 25)
        width = data.get('width', 512)
        height = data.get('height', 512)
        socket_id = data.get('socketId') # Optional socket ID for streaming

        print(colored(f"🎨 [AI Server] Generating image: prompt='{positive_prompt}', steps={steps}, res={width}x{height}, socket={socket_id}", "blue"))

        # Use new iterative function
        images, seed = generate_images_iterative(positive_prompt, negative_prompt, steps, (width, height), socket_id)

        if not images:
            print(colored("❌ [AI Server] Error: Failed to generate images (images object is empty or None)", "red"))
            return jsonify({"error": "Failed to generate images"}), 500

        # Retrieve the first image found
        for node_id in images:
            for image_data in images[node_id]:
                print(colored(f"✅ [AI Server] Sending generated image back (seed: {seed})", "green"))
                # Returns the first image found
                return send_file(
                    io.BytesIO(image_data),
                    mimetype='image/png',
                    as_attachment=False,
                    download_name=f"generated-{seed}.png"
                )

        print(colored("❌ [AI Server] Error: No images found in the output collection", "red"))
        return jsonify({"error": "No images generated"}), 500
    except Exception as e:
        print(colored(f"🔥 [AI Server] UNEXPECTED CRITICAL ERROR: {str(e)}", "red", attrs=["bold"]))
        import traceback
        traceback.print_exc()
        return jsonify({"error": f"Internal server error: {str(e)}"}), 500

if __name__ == "__main__":
    port = int(os.getenv('PORT', 3000))
    print(colored(f"Starting Flask server on port {port}...", "green"))
    app.run(host='0.0.0.0', port=port)