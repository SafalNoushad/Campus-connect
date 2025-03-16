import requests
import os
from flask import Blueprint, request, jsonify
from flask_cors import CORS
from flask_jwt_extended import jwt_required, get_jwt_identity
from dotenv import load_dotenv
from PyPDF2 import PdfReader
from io import BytesIO
import logging

load_dotenv()

chatbot_bp = Blueprint("chatbot", __name__)
CORS(chatbot_bp, resources={r"/api/chatbot/*": {"origins": os.getenv('FRONTEND_URL', 'http://localhost:5001')}})

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")
if not OPENROUTER_API_KEY:
    raise ValueError("❌ ERROR: OPENROUTER_API_KEY is missing! Please check your .env file.")

HEADERS = {
    "Authorization": f"Bearer {OPENROUTER_API_KEY}",
    "Content-Type": "application/json"
}

def extract_pdf_text(file_data, max_chars=10000):  # Increased for larger files
    """Extract text from a PDF file."""
    try:
        pdf = PdfReader(BytesIO(file_data))
        text = " ".join(page.extract_text() for page in pdf.pages if page.extract_text())
        if not text.strip():
            return "No readable text found in the PDF."
        return text[:max_chars]
    except Exception as e:
        logger.error(f"PDF extraction error: {str(e)}")
        return f"Error extracting PDF text: {str(e)}"

@chatbot_bp.route('/chat', methods=['POST'])
@jwt_required()
def chatbot():
    """Handle chat requests, summarize PDFs, and provide descriptions."""
    logger.info(f"Received request: Content-Type={request.content_type}, Headers={request.headers}")
    
    user_message = None
    pdf_text = None
    file_name = None

    # Handle multipart/form-data for PDF uploads
    if request.content_type.startswith('multipart/form-data'):
        user_message = request.form.get("message")
        file = request.files.get("file")
        if file:
            file_name = file.filename
            file_size = len(file.read())
            file.seek(0)  # Reset pointer after reading
            if file_size > 10 * 1024 * 1024:  # 10MB limit
                logger.warning(f"File {file_name} exceeds 10MB: {file_size} bytes")
                return jsonify({"error": "File size exceeds 10MB limit"}), 400
            if file_name.lower().endswith('.pdf'):
                pdf_text = extract_pdf_text(file.read())
            else:
                return jsonify({"error": "Only PDF files are supported."}), 400
        logger.info(f"Multipart data - Message: {user_message}, File: {file_name}, Size: {file_size if file else 'N/A'} bytes")
    else:
        # Handle JSON input
        data = request.get_json(silent=True)
        user_message = data.get("message") if data else None
        logger.info(f"JSON data - Message: {user_message}")

    # Validate input
    if not user_message and not pdf_text:
        logger.warning("No message or PDF provided")
        return jsonify({"error": "Please provide a message or upload a PDF."}), 400

    try:
        current_user = get_jwt_identity()
        logger.info(f"Authenticated user: {current_user}")

        url = "https://openrouter.ai/api/v1/chat/completions"

        # Construct the prompt based on input
        if pdf_text:
            prompt = (
                f"Analyze the following PDF content:\n\n{pdf_text}\n\n"
                "1. Provide a concise summary (up to 100 words) of the content.\n"
                "2. Give a brief description (up to 50 words) of the key topics or purpose of the document."
            )
            if user_message:
                prompt = f"{user_message}\n\n{prompt}"
        else:
            prompt = user_message

        payload = {
            "model": "openai/gpt-4o",
            "messages": [{"role": "user", "content": prompt}],
            "max_tokens": 500,  # Increased for larger summaries if needed
            "temperature": 0.5
        }

        response = requests.post(url, headers=HEADERS, json=payload)
        response.raise_for_status()

        response_data = response.json()
        ai_response = response_data.get("choices", [{}])[0].get("message", {}).get("content", "").strip()
        logger.info(f"AI response: {ai_response}")

        if not ai_response:
            return jsonify({"error": "No response received from AI."}), 500

        # Parse response for PDF uploads
        if pdf_text:
            lines = ai_response.split("\n")
            summary = ""
            description = ""
            for line in lines:
                if line.strip().startswith("1.") or "summary" in line.lower():
                    summary = line.strip().replace("1.", "").strip()
                elif line.strip().startswith("2.") or "description" in line.lower():
                    description = line.strip().replace("2.", "").strip()
            if not summary or not description:
                summary = ai_response[:200] if len(ai_response) > 200 else ai_response
                description = "Key topics inferred from the summary."
            response_dict = {
                "summary": summary,
                "description": description,
                "file_name": file_name or "Uploaded PDF"
            }
        else:
            response_dict = {"response": ai_response}

        return jsonify(response_dict), 200

    except requests.exceptions.RequestException as e:
        error_msg = str(e)
        if isinstance(e.response, requests.Response):
            try:
                error_data = e.response.json()
                error_msg = error_data.get("error", {}).get("message", error_msg)
            except ValueError:
                pass
        logger.error(f"API request failed: {error_msg}")
        if any(kw in error_msg.lower() for kw in ["token", "unauthorized"]):
            return jsonify({"error": "OpenRouter API token may have expired or is invalid."}), 401
        return jsonify({"error": f"Request failed: {error_msg}"}), 500
    except Exception as e:
        logger.error(f"Server error: {str(e)}")
        return jsonify({"error": f"Server error: {str(e)}"}), 500