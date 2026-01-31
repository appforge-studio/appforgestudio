import requests
import json

url = "http://localhost:3000/generate-image"
data = {
    "prompt": "a simple red apple",
    "steps": 1,
    "width": 512,
    "height": 512
}

print(f"Sending request to {url}...")
try:
    response = requests.post(url, json=data)
    print(f"Status Code: {response.status_code}")
    if response.status_code == 200:
        with open("test_gen.png", "wb") as f:
            f.write(response.content)
        print("Success! Image saved as test_gen.png")
        
        # Check resolution
        try:
            from PIL import Image
            img = Image.open("test_gen.png")
            print(f"Generated Image Resolution: {img.size[0]}x{img.size[1]}")
            if img.size[0] >= 1024 or img.size[1] >= 1024:
                print("✅ Resolution optimization confirmed (scaled up to target).")
            if img.size[0] % 64 == 0 and img.size[1] % 64 == 0:
                print("✅ Multi-64 alignment confirmed.")
        except ImportError:
            print("PIL not installed, skipping resolution check.")
    else:
        print(f"Error: {response.text}")
except Exception as e:
    print(f"Failed: {e}")
