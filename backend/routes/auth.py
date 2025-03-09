from flask import Flask, Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, JWTManager
import os
from dotenv import load_dotenv
import bcrypt
from flask_cors import CORS
from database import db  # Import db from database.py
from models import User  # User uses db from database.py

load_dotenv()

app = Flask(__name__)
CORS(app)

app.config["JWT_SECRET_KEY"] = os.getenv("JWT_SECRET_KEY", "supersecretkey")
jwt = JWTManager(app)

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/signup', methods=['POST'])
def signup():
    try:
        data = request.json
        admission_number = data.get("admission_number")
        email = data.get("email")
        username = data.get("name")
        password = data.get("password")
        phone = data.get("phone_number")

        if not all([admission_number, email, username, password, phone]):
            return jsonify({"error": "Missing required fields"}), 400

        if email.startswith("admin@mbcpeermade.com"):
            return jsonify({"error": "Admin accounts cannot be created manually"}), 403

        if email.endswith("@mbcpeermade.com") and email.split("@")[0].isdigit():
            role = "student"
        elif email.endswith("@mbcpeermade.com"):
            role = "teacher"
        else:
            return jsonify({"error": "Invalid email format"}), 400

        hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

        existing_user = User.query.filter(
            (User.admission_number == admission_number) | (User.email == email)
        ).first()
        if existing_user:
            if existing_user.admission_number == admission_number:
                return jsonify({"error": "Admission number already exists"}), 409
            if existing_user.email == email:
                return jsonify({"error": "Email already exists"}), 409

        new_user = User(
            admission_number=admission_number,
            email=email,
            username=username,
            password=hashed_password,
            phone_number=phone,
            role=role
        )
        db.session.add(new_user)
        db.session.commit()

        return jsonify({
            "message": "Signup successful",
            "user": new_user.to_dict()
        }), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({"error": "Internal Server Error", "details": str(e)}), 500

@auth_bp.route('/login', methods=['POST'])
def login():
    try:
        data = request.json
        admission_number = data.get("admission_number")
        password = data.get("password")

        if not admission_number or not password:
            return jsonify({"error": "Missing admission number or password"}), 400

        user = User.query.filter_by(admission_number=admission_number).first()
        if not user or not bcrypt.checkpw(password.encode('utf-8'), user.password.encode('utf-8')):
            return jsonify({"error": "Invalid admission number or password"}), 401

        access_token = create_access_token(identity=user.admission_number, additional_claims={"role": user.role})

        return jsonify({
            "message": "Login successful",
            "user": user.to_dict(),
            "token": access_token
        }), 200

    except Exception as e:
        return jsonify({"error": "Internal Server Error", "details": str(e)}), 500

if __name__ == '__main__':
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.run(debug=True, host='0.0.0.0', port=5001)