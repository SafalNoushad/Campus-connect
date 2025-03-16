import requests
import os
from flask import Blueprint, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv

# ✅ Load .env file
load_dotenv()

# ✅ Define Blueprint
chatbot_bp = Blueprint("chatbot", __name__)
CORS(chatbot_bp)

# ✅ Get API Key
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")
print("API Key:", OPENROUTER_API_KEY)  # Debug line
headers = {
    "Authorization": f"Bearer {OPENROUTER_API_KEY}",
    "Content-Type": "application/json"
}

if not OPENROUTER_API_KEY:
    raise ValueError("❌ ERROR: OPENROUTER_API_KEY is missing! Please check your .env file.")

@chatbot_bp.route('/chat', methods=['POST'])
def chatbot():
    user_message = request.json.get("message")
    if not user_message:
        return jsonify({"response": "Please enter a message."}), 400

    try:
        url = "https://openrouter.ai/api/v1/chat/completions"
        headers = {
            "Authorization": f"Bearer {OPENROUTER_API_KEY}",  # ✅ Pass API Key
            "Content-Type": "application/json"
        }
        payload = {
            "model": "openai/gpt-4o",  # ✅ Use Free GPT-4o Model
            "messages": [{"role": "user", "content": user_message}],
            "max_tokens": 500  # Increase token limit for longer responses
        }

        response = requests.post(url, headers=headers, json=payload)

        # ✅ Check if response is JSON
        try:
            response_data = response.json()
        except requests.exceptions.JSONDecodeError:
            return jsonify({"response": f"Invalid response from API: {response.text}"}), response.status_code

        if response.status_code == 200:
            ai_response = response_data.get("choices", [{}])[0].get("message", {}).get("content", "").strip()
            if not ai_response:
                return jsonify({"response": "No response received from AI."}), 500
            return jsonify({"response": ai_response})
        else:
            return jsonify({"response": f"API Error: {response_data}"}), response.status_code

    except requests.exceptions.RequestException as e:
        return jsonify({"response": f"Request Error: {str(e)}"}), 500
    except Exception as e:
        return jsonify({"response": f"Server Error: {str(e)}"}), 500
