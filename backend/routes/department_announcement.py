from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt, get_jwt_identity
from database import db
from models import DepartmentAnnouncement, User, Department
from functools import wraps
import logging
import smtplib
from email.mime.text import MIMEText
from dotenv import load_dotenv
import os

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# Blueprint definition
department_announcement_bp = Blueprint('department_announcement', __name__)

# Custom decorator to enforce HOD or Admin access
def hod_or_admin_required(fn):
    @jwt_required()
    @wraps(fn)
    def wrapper(*args, **kwargs):
        claims = get_jwt()
        role = claims.get('role')
        if role not in ['hod', 'admin']:
            return jsonify({'error': 'HOD or Admin access required'}), 403
        return fn(*args, **kwargs)
    return wrapper

# Email configuration
SMTP_SERVER = 'smtp.gmail.com'
SMTP_PORT = 587
SMTP_USER = os.getenv('SMTP_EMAIL')
SMTP_PASSWORD = os.getenv('SMTP_PASSWORD')

def send_email(to_emails, subject, body):
    """Send email notifications to specified recipients."""
    if not all([SMTP_SERVER, SMTP_PORT, SMTP_USER, SMTP_PASSWORD]):
        logger.error("SMTP configuration missing in .env")
        return False
    try:
        msg = MIMEText(body)
        msg['Subject'] = subject
        msg['From'] = SMTP_USER
        msg['To'] = ", ".join(to_emails)
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_USER, SMTP_PASSWORD)
            server.send_message(msg)
        logger.info(f"Email sent to {len(to_emails)} recipients")
        return True
    except Exception as e:
        logger.error(f"Failed to send email: {str(e)}")
        return False

@department_announcement_bp.route('', methods=['GET'])
@jwt_required()
def get_department_announcements():
    """Fetch department announcements based on user's department."""
    try:
        user_id = get_jwt_identity()
        user = User.query.filter_by(admission_number=user_id).first()
        if not user or not user.departmentcode:
            return jsonify({'error': 'User department not found'}), 400

        # Admins can see all dept announcements; others see only their dept
        claims = get_jwt()
        if claims.get('role') == 'admin':
            announcements = DepartmentAnnouncement.query.all()
        else:
            announcements = DepartmentAnnouncement.query.filter_by(departmentcode=user.departmentcode).all()
        return jsonify([announcement.to_dict() for announcement in announcements]), 200
    except Exception as e:
        logger.error(f"Failed to fetch department announcements: {str(e)}", exc_info=True)
        return jsonify({'error': 'Failed to fetch department announcements', 'details': str(e)}), 500

@department_announcement_bp.route('', methods=['POST'])
@hod_or_admin_required
def create_department_announcement():
    """Create a department-specific announcement (HOD or Admin)."""
    try:
        data = request.get_json()
        title = data.get('title')
        message = data.get('message')
        category = data.get('category', 'general')
        departmentcode = data.get('departmentcode')  # Required for admin, optional for HOD
        send_email_notification = data.get('send_email', False)
        email_recipients = data.get('email_recipients', {})
        user_id = get_jwt_identity()

        if not all([title, message]):
            return jsonify({'error': 'Missing required fields (title, message)'}), 400

        if category not in ['bus', 'placement', 'class_suspension', 'event', 'general']:
            return jsonify({'error': 'Invalid category'}), 400

        user = User.query.filter_by(admission_number=user_id).first()
        if not user:
            return jsonify({'error': 'User not found'}), 400

        # HOD uses their own department; Admin must specify
        claims = get_jwt()
        if claims.get('role') == 'hod':
            if not user.departmentcode:
                return jsonify({'error': 'HOD department not found'}), 400
            effective_dept = user.departmentcode
        else:  # Admin
            if not departmentcode:
                return jsonify({'error': 'Department code required for admin'}), 400
            if not Department.query.filter_by(departmentcode=departmentcode).first():
                return jsonify({'error': 'Invalid department code'}), 400
            effective_dept = departmentcode

        new_announcement = DepartmentAnnouncement(
            title=title,
            message=message,
            category=category,
            created_by=user_id,
            departmentcode=effective_dept
        )
        db.session.add(new_announcement)
        db.session.commit()

        if send_email_notification:
            recipient_emails = []
            roles_to_send = {
                'student': email_recipients.get('students', False),
                'staff': email_recipients.get('staff', False),
            }
            for role, should_send in roles_to_send.items():
                if should_send:
                    users = User.query.filter_by(role=role, departmentcode=effective_dept).all()
                    recipient_emails.extend([user.email for user in users if user.email])

            if recipient_emails:
                subject = f"Department Announcement: {title}"
                body = f"{message}\n\nCategory: {category}\nDepartment: {effective_dept}\nCreated: {new_announcement.created_at}"
                send_email(recipient_emails, subject, body)

        return jsonify({
            'message': 'Department announcement created successfully',
            'announcement': new_announcement.to_dict()
        }), 201
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to create department announcement: {str(e)}", exc_info=True)
        return jsonify({'error': 'Failed to create department announcement', 'details': str(e)}), 500

@department_announcement_bp.route('/<int:announcement_id>', methods=['PUT'])
@hod_or_admin_required
def update_department_announcement(announcement_id):
    """Update a department announcement (HOD or Admin)."""
    try:
        data = request.get_json()
        user_id = get_jwt_identity()
        announcement = DepartmentAnnouncement.query.get_or_404(announcement_id)

        claims = get_jwt()
        if claims.get('role') == 'hod' and announcement.created_by != user_id:
            return jsonify({'error': 'Unauthorized to update this announcement'}), 403

        # Admin can update departmentcode; HOD cannot
        departmentcode = data.get('departmentcode')
        if claims.get('role') == 'admin' and departmentcode:
            if not Department.query.filter_by(departmentcode=departmentcode).first():
                return jsonify({'error': 'Invalid department code'}), 400
            announcement.departmentcode = departmentcode

        announcement.title = data.get('title', announcement.title)
        announcement.message = data.get('message', announcement.message)
        announcement.category = data.get('category', announcement.category)

        if announcement.category not in ['bus', 'placement', 'class_suspension', 'event', 'general']:
            return jsonify({'error': 'Invalid category'}), 400

        db.session.commit()
        return jsonify({
            'message': 'Department announcement updated successfully',
            'announcement': announcement.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to update department announcement: {str(e)}", exc_info=True)
        return jsonify({'error': 'Failed to update department announcement', 'details': str(e)}), 500

@department_announcement_bp.route('/<int:announcement_id>', methods=['DELETE'])
@hod_or_admin_required
def delete_department_announcement(announcement_id):
    """Delete a department announcement (HOD or Admin)."""
    try:
        user_id = get_jwt_identity()
        announcement = DepartmentAnnouncement.query.get_or_404(announcement_id)

        claims = get_jwt()
        if claims.get('role') == 'hod' and announcement.created_by != user_id:
            return jsonify({'error': 'Unauthorized to delete this announcement'}), 403

        db.session.delete(announcement)
        db.session.commit()
        return jsonify({'message': 'Department announcement deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to delete department announcement: {str(e)}", exc_info=True)
        return jsonify({'error': 'Failed to delete department announcement', 'details': str(e)}), 500