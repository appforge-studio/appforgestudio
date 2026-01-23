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
def get_images(ws, prompt):
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
        else:
            continue  # Previews are binary data

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
def generate_images(positive_prompt, negative_prompt="", steps=25, resolution=(512, 512)):
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
    images = get_images(ws, workflow)

    # Step 8: Close WebSocket connection after fetching the images
    print(colored(f"Step 8: Closing WebSocket connection to {ws_url}", "cyan"))
    ws.close()

    return images, seed

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

        print(colored(f"🎨 [AI Server] Generating image: prompt='{positive_prompt}', steps={steps}, res={width}x{height}", "blue"))

        images, seed = generate_images(positive_prompt, negative_prompt, steps, (width, height))

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
    port = int(os.getenv('PORT', 5000))
    print(colored(f"Starting Flask server on port {port}...", "green"))
    app.run(host='0.0.0.0', port=port)