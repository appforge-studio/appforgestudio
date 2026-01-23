import requests
import time
import sys

def test_generate_image():
    url = "http://localhost:5000/generate-image"
    payload = {
        "prompt": "A futuristic city with flying cars, cyberpunk style",
        "steps": 1,
        "width": 512,
        "height": 512
    }
    print(f"Sending POST request to {url}...")
    try:
        response = requests.post(url, json=payload, timeout=300)
        if response.status_code == 200:
            print("Success! Image received.")
            with open("test_output.png", "wb") as f:
                f.write(response.content)
            print("Saved to test_output.png")
            return True
        else:
            print(f"Failed: {response.status_code}")
            print(response.text)
            return False
    except Exception as e:
        print(f"Exception: {e}")
        return False

if __name__ == "__main__":
    # Wait a bit for server to start if running immediately
    time.sleep(5) 
    if test_generate_image():
        sys.exit(0)
    else:
        sys.exit(1)
