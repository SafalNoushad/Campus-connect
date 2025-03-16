import requests
import os
from dotenv import load_dotenv

load_dotenv()
api_key = os.getenv("OPENROUTER_API_KEY")
url = "https://openrouter.ai/api/v1/chat/completions"
headers = {"Authorization": f"Bearer {api_key}"}
payload = {
    "model": "mistralai/mixtral-8x7b-instruct",
    "messages": [{"role": "user", "content": "Hello"}]
}
response = requests.post(url, json=payload, headers=headers)
print(response.status_code)
print(response.text)