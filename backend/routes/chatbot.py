import os
import asyncio
import aiohttp
import certifi
import ssl
from flask import Blueprint, request, jsonify
from flask_cors import CORS
from flask_jwt_extended import jwt_required, get_jwt_identity
from dotenv import load_dotenv
from PyPDF2 import PdfReader
from io import BytesIO
import logging

# Import db and models at the top, assuming app.py initializes db first
from database import db
from models import User, Department, Notes, Timetable, Subject

load_dotenv()

chatbot_bp = Blueprint("chatbot", __name__)
CORS(chatbot_bp, resources={r"/api/chatbot/*": {"origins": os.getenv('FRONTEND_URL', 'http://localhost:5001')}})

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")
if not OPENROUTER_API_KEY:
    raise ValueError("❌ ERROR: OPENROUTER_API_KEY is missing! Please check your .env file.")

HEADERS = {
    "Authorization": f"Bearer {OPENROUTER_API_KEY}",
    "Content-Type": "application/json"
}

def extract_pdf_text(file_data, max_chars=5000):
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

def fetch_database_context(user_message):
    """Fetch relevant campus data based on the user's query."""
    try:
        if not db.session:
            logger.error("Database session not initialized")
            return "Database not available."

        message_lower = user_message.lower()
        campus_keywords = ["hod", "staff", "department", "student", "subject", "notes", "timetable", "campus", "college"]
        
        if not any(keyword in message_lower for keyword in campus_keywords):
            return None  # No campus context needed

        context_lines = ["Campus Database Context:"]

        # Extract department code if mentioned
        dept_code = None
        for code in ["cs", "sc", "ee", "me"]:
            if code in message_lower:
                dept_code = code.upper()
                break

        if "hod" in message_lower:
            hods = User.query.filter_by(role='hod')
            if dept_code:
                hods = hods.filter_by(departmentcode=dept_code)
            hods = hods.limit(1).all()
            if hods:
                hod_info = "\n".join(
                    [f"HOD of {h.departmentcode}: {h.username} (ID: {h.admission_number}, Email: {h.email})" for h in hods]
                )
                context_lines.append("Heads of Departments:")
                context_lines.append(hod_info)
            else:
                context_lines.append(f"No HOD found for {dept_code or 'any department'}.")

        if "staff" in message_lower:
            staff = User.query.filter(User.role.in_(['staff', 'hod']))
            if dept_code:
                staff = staff.filter_by(departmentcode=dept_code)
            staff = staff.limit(3).all()
            staff_info = "\n".join(
                [f"Staff: {s.username} (ID: {s.admission_number}, Role: {s.role}, Dept: {s.departmentcode}, Email: {s.email})" for s in staff]
            )
            context_lines.append("Staff (Sample):")
            context_lines.append(staff_info)

        if "department" in message_lower and "hod" not in message_lower:
            departments = Department.query
            if dept_code:
                departments = departments.filter_by(departmentcode=dept_code)
            departments = departments.limit(3).all()
            dept_info = "\n".join([f"Department: {d.departmentcode}, Name: {d.departmentname}" for d in departments])
            context_lines.append("Departments:")
            context_lines.append(dept_info)

        if "student" in message_lower:
            students = User.query.filter_by(role='student')
            if dept_code:
                students = students.filter_by(departmentcode=dept_code)
            students = students.limit(3).all()
            student_info = "\n".join(
                [f"Student: {s.username} (ID: {s.admission_number}, Dept: {s.departmentcode}, Semester: {s.semester or 'N/A'}, Batch: {s.batch or 'N/A'})" for s in students]
            )
            context_lines.append("Students (Sample):")
            context_lines.append(student_info)

        if "subject" in message_lower:
            subjects = Subject.query
            if dept_code:
                subjects = subjects.filter_by(departmentcode=dept_code)
            subjects = subjects.limit(3).all()
            subject_info = "\n".join(
                [f"Subject: {s.subject_code}, Name: {s.subject_name}, Dept: {s.departmentcode}, Semester: {s.semester}, Credits: {s.credits}" for s in subjects]
            )
            context_lines.append("Subjects (Sample):")
            context_lines.append(subject_info)

        if "notes" in message_lower:
            notes = Notes.query
            if dept_code:
                notes = notes.filter_by(departmentcode=dept_code)
            notes = notes.limit(3).all()
            notes_info = "\n".join([f"Note: {n.filename}, Semester: {n.semester}, Uploaded: {n.uploaded_at}" for n in notes])
            context_lines.append("Notes (Sample):")
            context_lines.append(notes_info)

        if "timetable" in message_lower:
            timetables = Timetable.query
            if dept_code:
                timetables = timetables.filter_by(departmentcode=dept_code)
            timetables = timetables.limit(3).all()
            timetable_info = "\n".join([f"Timetable: {t.filename}, Semester: {t.semester}, Uploaded: {t.uploaded_at}" for t in timetables])
            context_lines.append("Timetables (Sample):")
            context_lines.append(timetable_info)

        context = "\n".join(context_lines)
        logger.info(f"Database context generated (size: {len(context)} chars): {context}")
        return context
    except Exception as e:
        logger.error(f"Database fetch error: {str(e)}")
        return f"Error fetching database context: {str(e)}"

async def async_post_to_openrouter(payload):
    """Asynchronously post to OpenRouter API with a timeout."""
    timeout = aiohttp.ClientTimeout(total=15)
    ssl_context = ssl.create_default_context(cafile=certifi.where())
    connector = aiohttp.TCPConnector(ssl=ssl_context)
    async with aiohttp.ClientSession(connector=connector) as session:
        try:
            start_time = asyncio.get_event_loop().time()
            async with session.post(
                "https://openrouter.ai/api/v1/chat/completions",
                headers=HEADERS,
                json=payload,
                timeout=timeout
            ) as response:
                response.raise_for_status()
                data = await response.json()
                end_time = asyncio.get_event_loop().time()
                logger.info(f"OpenRouter API responded in {end_time - start_time:.2f} seconds")
                return data
        except asyncio.TimeoutError:
            logger.error("OpenRouter API request timed out after 15 seconds")
            raise Exception("Sorry, the request took too long. Try again!")
        except aiohttp.ClientError as e:
            logger.error(f"OpenRouter API error: {str(e)}")
            raise Exception(f"API request failed: {str(e)}")

@chatbot_bp.route('/chat', methods=['POST'])
@jwt_required()
async def chatbot():
    """Handle chat requests as a general chatbot with campus query support."""
    logger.info(f"Received request: Content-Type={request.content_type}, Headers={request.headers}")
    
    user_message = None
    pdf_text = None
    file_name = None

    try:
        if request.content_type.startswith('multipart/form-data'):
            user_message = request.form.get("message")
            file = request.files.get("file")
            if file:
                file_name = file.filename
                file_size = len(file.read())
                file.seek(0)
                if file_size > 10 * 1024 * 1024:
                    logger.warning(f"File {file_name} exceeds 10MB: {file_size} bytes")
                    return jsonify({"error": "File size exceeds 10MB limit"}), 400
                if file_name.lower().endswith('.pdf'):
                    pdf_text = extract_pdf_text(file.read())
                else:
                    return jsonify({"error": "Only PDF files are supported."}), 400
            logger.info(f"Multipart data - Message: {user_message}, File: {file_name}, Size: {file_size if file else 'N/A'} bytes")
        else:
            data = request.get_json(silent=True)
            user_message = data.get("message") if data else None
            logger.info(f"JSON data - Message: {user_message}")

        if not user_message and not pdf_text:
            logger.warning("No message or PDF provided")
            return jsonify({"error": "Please say something or upload a PDF!"}), 400

        current_user = get_jwt_identity()
        logger.info(f"Authenticated user: {current_user}")

        db_context = fetch_database_context(user_message) if user_message else None

        if pdf_text:
            prompt = (
                f"Analyze this PDF content:\n\n{pdf_text}\n\n"
                "1. Summarize it in up to 50 words.\n"
                "2. Describe key topics in up to 25 words."
            )
            if user_message:
                prompt = f"{user_message}\n\n{prompt}"
        elif db_context:
            prompt = (
                f"Answer based on this campus database:\n\n{db_context}\n\n"
                f"Question: {user_message}\n\n"
                "Keep it concise. Say 'Not enough info' if unclear."
            )
        else:
            prompt = user_message

        payload = {
            "model": "openai/gpt-4o",
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "You are a friendly chatbot. Respond naturally to any input. "
                        "For campus-related questions (e.g., HODs, staff, departments, students, subjects, notes, timetables), "
                        "use the provided database context and keep responses accurate and educational. Otherwise, chat casually!"
                    )
                },
                {"role": "user", "content": prompt}
            ],
            "max_tokens": 300,
            "temperature": 0.7
        }

        logger.info(f"Sending payload to OpenRouter (size: {len(str(payload))} chars)")
        response_data = await async_post_to_openrouter(payload)

        ai_response = response_data.get("choices", [{}])[0].get("message", {}).get("content", "").strip()
        logger.info(f"AI response: {ai_response}")

        if not ai_response:
            logger.warning("Empty response from OpenRouter")
            return jsonify({"error": "Oops, no response from the AI. Try again?"}), 500

        if pdf_text:
            lines = ai_response.split("\n")
            summary = next((l.replace("1.", "").strip() for l in lines if l.strip().startswith("1.") or "summar" in l.lower()), "")
            description = next((l.replace("2.", "").strip() for l in lines if l.strip().startswith("2.") or "descrip" in l.lower()), "")
            if not summary or not description:
                summary = ai_response[:100] if len(ai_response) > 100 else ai_response
                description = "Key topics inferred."
            response_dict = {
                "summary": summary,
                "description": description,
                "file_name": file_name or "Uploaded PDF"
            }
        else:
            response_dict = {"response": ai_response}

        return jsonify(response_dict), 200

    except Exception as e:
        logger.error(f"Server error: {str(e)}", exc_info=True)
        return jsonify({"error": f"Sorry, something went wrong: {str(e)}"}), 500