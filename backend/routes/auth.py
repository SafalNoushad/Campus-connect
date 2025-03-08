from flask import Flask, Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, JWTManager
import os
from dotenv import load_dotenv
import bcrypt
from flask_cors import CORS
from config.db import get_db_connection  # ✅ Correct Import

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app)  # ✅ Enable CORS for all routes

# ✅ Set JWT Secret Key
app.config["JWT_SECRET_KEY"] = os.getenv("JWT_SECRET_KEY", "supersecretkey")
jwt = JWTManager(app)

auth_bp = Blueprint('auth', __name__)
@auth_bp.route('/signup', methods=['POST'])
def signup():
    """Handles user registration and stores user details in the database."""
    try:
        data = request.json
        admission_number = data.get("admission_number")
        email = data.get("email")
        username = data.get("name")
        password = data.get("password")
        phone = data.get("phone_number")

        if not all([admission_number, email, username, password, phone]):
            return jsonify({"error": "Missing required fields"}), 400

        # ✅ Check if email belongs to an admin and prevent signup
        if email.startswith("admin@mbcpeermade.com"):
            return jsonify({"error": "Admin accounts cannot be created manually"}), 403  # ❌ Forbidden

        # ✅ Determine the role from email
        if email.endswith("@mbcpeermade.com") and email.split("@")[0].isdigit():
            role = "student"  # ✅ If email starts with numbers, it's a student
        elif email.endswith("@mbcpeermade.com"):
            role = "teacher"  # ✅ Otherwise, it's a teacher
        else:
            return jsonify({"error": "Invalid email format"}), 400  # ❌ Invalid email domain

        hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

        db = get_db_connection()
        try:
            with db.cursor(dictionary=True) as cursor:
                cursor.execute("SELECT admission_number, email FROM users WHERE admission_number = %s OR email = %s",
                               (admission_number, email))
                existing_user = cursor.fetchone()

                if existing_user:
                    if existing_user["admission_number"] == admission_number:
                        return jsonify({"error": "Admission number already exists"}), 409
                    if existing_user["email"] == email:
                        return jsonify({"error": "Email already exists"}), 409

                cursor.execute(
                    "INSERT INTO users (admission_number, email, username, password, phone_number, role) VALUES (%s, %s, %s, %s, %s, %s)",
                    (admission_number, email, username, hashed_password, phone, role)
                )
                db.commit()
        finally:
            db.close()

        return jsonify({
            "message": "Signup successful",
            "user": {
                "admission_number": admission_number,
                "email": email,
                "name": username,
                "phone_number": phone,
                "role": role
            }
        }), 201

    except Exception as e:
        return jsonify({"error": "Internal Server Error", "details": str(e)}), 500


@auth_bp.route('/login', methods=['POST'])
def login():
    try:
        data = request.json
        admission_number = data.get("admission_number")
        password = data.get("password")

        if not admission_number or not password:
            return jsonify({"error": "Missing admission number or password"}), 400

        db = get_db_connection()
        with db.cursor(dictionary=True) as cursor:
            cursor.execute("SELECT admission_number, username, email, phone_number, password, role FROM users WHERE admission_number = %s", (admission_number,))
            user = cursor.fetchone()

        if not user or not bcrypt.checkpw(password.encode('utf-8'), user['password'].encode('utf-8')):
            return jsonify({"error": "Invalid admission number or password"}), 401

        access_token = create_access_token(identity=user["admission_number"], additional_claims={"role": user["role"]})

        return jsonify({
            "message": "Login successful",
            "user": {
                "admission_number": user["admission_number"],
                "name": user["username"],
                "email": user["email"],
                "phone_number": user.get("phone_number", "N/A"),  # ✅ Handle admin (no phone)
                "role": user["role"]
            },
            "token": access_token
        }), 200

    except Exception as e:
        return jsonify({"error": "Internal Server Error", "details": str(e)}), 500
        
if __name__ == '__main__':
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.run(debug=True, host='0.0.0.0', port=5001)
