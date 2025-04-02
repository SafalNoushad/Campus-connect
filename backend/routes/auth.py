from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from database import db
from models import User
import os
from dotenv import load_dotenv
import bcrypt
import secrets
import smtplib
from email.mime.text import MIMEText
from datetime import datetime, timedelta
import logging

load_dotenv()

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

auth_bp = Blueprint('auth', __name__)

# Temporary OTP storage (use Redis/DB in production)
otp_store = {}  # {admission_number: {"otp": "123456", "expires": datetime}}

@auth_bp.route('/login', methods=['POST'])
def login():
    try:
        data = request.json
        admission_number = data.get("admission_number")
        password = data.get("password")

        logger.debug(f"Login attempt for admission_number: {admission_number}")

        if not admission_number or not password:
            logger.warning("Missing admission number or password")
            return jsonify({"error": "Missing admission number or password"}), 400

        user = User.query.filter_by(admission_number=admission_number).first()
        if not user or not user.check_password(password):
            logger.warning(f"Invalid credentials for {admission_number}")
            return jsonify({"error": "Invalid admission number or password"}), 401

        logger.debug(f"User found: {user.admission_number}, Role: {user.role}")
        
        access_token = create_access_token(
            identity=user.admission_number,
            additional_claims={
                "role": user.role,
                "departmentcode": user.departmentcode,
                "semester": user.semester if user.role == 'student' else None
            }
        )

        logger.info(f"Login successful for {admission_number}")
        return jsonify({
            "message": "Login successful",
            "user": user.to_dict(),
            "token": access_token
        }), 200
    except Exception as e:
        logger.error(f"Login error: {str(e)}")
        return jsonify({"error": "Internal Server Error", "details": str(e)}), 500

@auth_bp.route('/request_otp', methods=['POST'])
def request_otp():
    try:
        data = request.json
        admission_number = data.get("admission_number")
        
        user = User.query.filter_by(admission_number=admission_number).first()
        if not user:
            return jsonify({"error": "User not found"}), 404
        
        otp = secrets.token_hex(3).upper()  # 6-character OTP
        expires = datetime.utcnow() + timedelta(minutes=10)
        otp_store[admission_number] = {"otp": otp, "expires": expires}
        
        sender_email = os.getenv("SMTP_EMAIL")
        sender_password = os.getenv("SMTP_PASSWORD")
        if not sender_email or not sender_password:
            return jsonify({"error": "Email configuration missing"}), 500

        msg = MIMEText(f"Your OTP for password reset is: {otp}\nValid for 10 minutes.")
        msg['Subject'] = 'Password Reset OTP'
        msg['From'] = sender_email
        msg['To'] = user.email

        with smtplib.SMTP('smtp.gmail.com', 587) as server:
            server.starttls()
            server.login(sender_email, sender_password)
            server.send_message(msg)

        return jsonify({"message": "OTP sent to your email"}), 200
    except smtplib.SMTPException as e:
        logger.error(f"SMTP error: {str(e)}")
        return jsonify({"error": "Failed to send OTP", "details": f"SMTP error: {str(e)}"}), 500
    except Exception as e:
        logger.error(f"Failed to send OTP: {str(e)}")
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

        if admission_number not in otp_store:
            return jsonify({"error": "OTP not requested or expired"}), 401
        
        stored_otp_data = otp_store[admission_number]
        if stored_otp_data["otp"] != otp or datetime.utcnow() > stored_otp_data["expires"]:
            del otp_store[admission_number]
            return jsonify({"error": "Invalid or expired OTP"}), 401

        user.set_password(new_password)
        db.session.commit()
        del otp_store[admission_number]

        return jsonify({"message": "Password reset successful"}), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to reset password: {str(e)}")
        return jsonify({"error": "Failed to reset password", "details": str(e)}), 500

@auth_bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    try:
        current_user = get_jwt_identity()
        user = User.query.filter_by(admission_number=current_user).first()
        new_access_token = create_access_token(
            identity=current_user,
            additional_claims={
                "role": user.role,
                "departmentcode": user.departmentcode,
                "semester": user.semester if user.role == 'student' else None
            }
        )
        return jsonify({"access_token": new_access_token}), 200
    except Exception as e:
        logger.error(f"Refresh token error: {str(e)}")
        return jsonify({"error": "Invalid refresh token", "details": str(e)}), 401