from flask import Flask, Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, JWTManager
import os
from dotenv import load_dotenv
import bcrypt
from flask_cors import CORS
from database import db
from models import User
import secrets
import smtplib
from email.mime.text import MIMEText
from datetime import datetime, timedelta

load_dotenv()

app = Flask(__name__)
CORS(app)

app.config["JWT_SECRET_KEY"] = os.getenv("SECRET_KEY")
jwt = JWTManager(app)

auth_bp = Blueprint('auth', __name__)

# Temporary in-memory storage for OTPs (use a database or Redis in production)
otp_store = {}  # Format: {admission_number: {"otp": "123456", "expires": datetime}}

@auth_bp.route('/login', methods=['POST'])
def login():
    try:
        data = request.json
        admission_number = data.get("admission_number")
        password = data.get("password")

        if not admission_number or not password:
            return jsonify({"error": "Missing admission number or password"}), 400

        user = User.query.filter_by(admission_number=admission_number).first()
        if not user:
            return jsonify({"error": "Invalid admission number or password"}), 401
        
        if user.role == 'admin' and user.password is None:
            return jsonify({"error": "Admin must set a password via profile"}), 403
        
        if not bcrypt.checkpw(password.encode('utf-8'), user.password.encode('utf-8')):
            return jsonify({"error": "Invalid admission number or password"}), 401

        access_token = create_access_token(identity=user.admission_number, additional_claims={"role": user.role})

        return jsonify({
            "message": "Login successful",
            "user": user.to_dict(),
            "token": access_token
        }), 200

    except Exception as e:
        return jsonify({"error": "Internal Server Error", "details": str(e)}), 500

@auth_bp.route('/request_otp', methods=['POST'])
def request_otp():
    try:
        data = request.json
        admission_number = data.get("admission_number")
        
        user = User.query.filter_by(admission_number=admission_number).first()
        if not user:
            return jsonify({"error": "User not found"}), 404
        
        # Generate OTP
        otp = secrets.token_hex(3).upper()  # 6-character OTP
        expires = datetime.utcnow() + timedelta(minutes=10)
        
        # Store OTP
        otp_store[admission_number] = {"otp": otp, "expires": expires}
        
        # Send OTP via email
        sender_email = os.getenv("SMTP_EMAIL")
        sender_password = os.getenv("SMTP_PASSWORD")
        if not sender_email or not sender_password:
            return jsonify({"error": "Email configuration missing"}), 500

        msg = MIMEText(f"Your OTP for password reset is: {otp}\nThis OTP is valid for 10 minutes.")
        msg['Subject'] = 'Password Reset OTP'
        msg['From'] = sender_email
        msg['To'] = user.email

        with smtplib.SMTP('smtp.gmail.com', 587) as server:
            server.starttls()
            server.login(sender_email, sender_password)
            server.send_message(msg)

        return jsonify({"message": "OTP sent to your email"}), 200
    except smtplib.SMTPException as e:
        return jsonify({"error": "Failed to send OTP", "details": f"SMTP error: {str(e)}"}), 500
    except Exception as e:
        return jsonify({"error": "Failed to send OTP", "details": str(e)}), 500
    
    
@auth_bp.route('/reset_password', methods=['POST'])
def reset_password():
    try:
        data = request.json
        admission_number = data.get("admission_number")
        otp = data.get("otp")
        new_password = data.get("new_password")

        if not all([admission_number, otp, new_password]):
            return jsonify({"error": "Missing required fields"}), 400

        user = User.query.filter_by(admission_number=admission_number).first()
        if not user:
            return jsonify({"error": "User not found"}), 404

        # Verify OTP
        if admission_number not in otp_store:
            return jsonify({"error": "OTP not requested or expired"}), 401
        
        stored_otp_data = otp_store[admission_number]
        if stored_otp_data["otp"] != otp:
            return jsonify({"error": "Invalid OTP"}), 401
        
        if datetime.utcnow() > stored_otp_data["expires"]:
            del otp_store[admission_number]  # Clean up expired OTP
            return jsonify({"error": "OTP has expired"}), 401

        # OTP is valid, reset password
        hashed_password = bcrypt.hashpw(new_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        user.password = hashed_password
        db.session.commit()

        # Clean up OTP after successful reset
        del otp_store[admission_number]

        return jsonify({"message": "Password reset successful"}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": "Failed to reset password", "details": str(e)}), 500

if __name__ == '__main__':
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.run(debug=True, host='0.0.0.0', port=5001)