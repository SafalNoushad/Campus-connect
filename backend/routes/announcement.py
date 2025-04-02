from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt, get_jwt_identity
from database import db
from models import Announcement, User
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

announcement_bp = Blueprint('announcement', __name__)

# Custom decorator to enforce admin access
def admin_required(fn):
    @jwt_required()
    @wraps(fn)
    def wrapper(*args, **kwargs):
        claims = get_jwt()
        if claims.get('role') != 'admin':
            return jsonify({'error': 'Admin access required'}), 403
        return fn(*args, **kwargs)
    return wrapper

# Custom decorator to enforce HOD access
def hod_required(fn):
    @jwt_required()
    @wraps(fn)
    def wrapper(*args, **kwargs):
        claims = get_jwt()
        if claims.get('role') != 'hod':
            return jsonify({'error': 'HOD access required'}), 403
        return fn(*args, **kwargs)
    return wrapper

# Email configuration from .env
SMTP_SERVER = 'smtp.gmail.com'
SMTP_PORT = 587
SMTP_USER = os.getenv('SMTP_EMAIL')
SMTP_PASSWORD = os.getenv('SMTP_PASSWORD')

def send_email(to_emails, subject, body):
    """Send email notifications to a list of recipients."""
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

@announcement_bp.route('', methods=['GET'])
@jwt_required()
def get_announcements():
    """Fetch all announcements for authenticated users."""
    try:
        announcements = Announcement.query.all()
        return jsonify([announcement.to_dict() for announcement in announcements]), 200
    except Exception as e:
        logger.error(f"Failed to fetch announcements: {str(e)}")
        return jsonify({'error': 'Failed to fetch announcements', 'details': str(e)}), 500

@announcement_bp.route('', methods=['POST'])
@admin_required
def create_announcement():
    """Create a new general announcement (admin only)."""
    try:
        data = request.get_json()
        title = data.get('title')
        message = data.get('message')
        category = data.get('category')
        send_email_notification = data.get('send_email', False)
        email_recipients = data.get('email_recipients', {})
        admin_id = get_jwt_identity()

        if not all([title, message, category]):
            return jsonify({'error': 'Missing required fields (title, message, category)'}), 400

        if category not in ['bus', 'placement', 'class_suspension', 'event', 'general']:
            return jsonify({'error': 'Invalid category'}), 400

        new_announcement = Announcement(
            title=title,
            message=message,
            category=category,
            created_by=admin_id
        )
        db.session.add(new_announcement)
        db.session.commit()

        if send_email_notification:
            recipient_emails = []
            roles_to_send = {
                'student': email_recipients.get('students', False),
                'staff': email_recipients.get('staff', False),
                'hod': email_recipients.get('hod', False)
            }
            for role, should_send in roles_to_send.items():
                if should_send:
                    users = User.query.filter_by(role=role).all()
                    recipient_emails.extend([user.email for user in users if user.email])

            if recipient_emails:
                subject = f"Campus Announcement: {title}"
                body = f"{message}\n\nCategory: {category}\nCreated: {new_announcement.created_at}"
                send_email(recipient_emails, subject, body)

        return jsonify({
            'message': 'Announcement created successfully',
            'announcement': new_announcement.to_dict()
        }), 201
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to create announcement: {str(e)}")
        return jsonify({'error': 'Failed to create announcement', 'details': str(e)}), 500

@announcement_bp.route('/department', methods=['POST'])
@hod_required
def create_department_announcement():
    """Create a department-specific announcement (HOD only)."""
    try:
        data = request.get_json()
        title = data.get('title')
        message = data.get('message')
        category = data.get('category', 'general')
        send_email_notification = data.get('send_email', False)
        email_recipients = data.get('email_recipients', {})
        hod_id = get_jwt_identity()

        if not all([title, message]):
            return jsonify({'error': 'Missing required fields (title, message)'}), 400

        if category not in ['bus', 'placement', 'class_suspension', 'event', 'general']:
            return jsonify({'error': 'Invalid category'}), 400

        hod = User.query.filter_by(admission_number=hod_id).first()
        if not hod or not hod.departmentcode:
            return jsonify({'error': 'HOD department not found'}), 400

        new_announcement = Announcement(
            title=title,
            message=message,
            category=category,
            created_by=hod_id
        )
        db.session.add(new_announcement)
        db.session.commit()

        if send_email_notification:
            recipient_emails = []
            roles_to_send = {
                'student': email_recipients.get('students', False),
                'staff': email_recipients.get('staff', False),
            }
            # Filter by department
            for role, should_send in roles_to_send.items():
                if should_send:
                    users = User.query.filter_by(role=role, departmentcode=hod.departmentcode).all()
                    recipient_emails.extend([user.email for user in users if user.email])

            if recipient_emails:
                subject = f"Department Announcement: {title}"
                body = f"{message}\n\nCategory: {category}\nDepartment: {hod.departmentcode}\nCreated: {new_announcement.created_at}"
                send_email(recipient_emails, subject, body)

        return jsonify({
            'message': 'Department announcement created successfully',
            'announcement': new_announcement.to_dict()
        }), 201
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to create department announcement: {str(e)}")
        return jsonify({'error': 'Failed to create department announcement', 'details': str(e)}), 500

@announcement_bp.route('/<int:announcement_id>', methods=['PUT'])
@admin_required
def update_announcement(announcement_id):
    """Update an existing announcement (admin only)."""
    try:
        data = request.get_json()
        announcement = Announcement.query.get_or_404(announcement_id)

        announcement.title = data.get('title', announcement.title)
        announcement.message = data.get('message', announcement.message)
        announcement.category = data.get('category', announcement.category)

        if announcement.category not in ['bus', 'placement', 'class_suspension', 'event', 'general']:
            return jsonify({'error': 'Invalid category'}), 400

        db.session.commit()
        return jsonify({
            'message': 'Announcement updated successfully',
            'announcement': announcement.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to update announcement: {str(e)}")
        return jsonify({'error': 'Failed to update announcement', 'details': str(e)}), 500

@announcement_bp.route('/<int:announcement_id>', methods=['DELETE'])
@admin_required
def delete_announcement(announcement_id):
    """Delete an announcement (admin only)."""
    try:
        announcement = Announcement.query.get_or_404(announcement_id)
        db.session.delete(announcement)
        db.session.commit()
        return jsonify({'message': 'Announcement deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to delete announcement: {str(e)}")
        return jsonify({'error': 'Failed to delete announcement', 'details': str(e)}), 500

@announcement_bp.route('/<int:announcement_id>/broadcast', methods=['POST'])
@admin_required
def broadcast_announcement(announcement_id):
    """Broadcast an announcement to selected recipients (admin only)."""
    try:
        data = request.get_json()
        announcement = Announcement.query.get_or_404(announcement_id)
        send_email_notification = data.get('send_email', False)
        email_recipients = data.get('email_recipients', {})

        if send_email_notification:
            recipient_emails = []
            roles_to_send = {
                'student': email_recipients.get('students', False),
                'staff': email_recipients.get('staff', False),
                'hod': email_recipients.get('hod', False)
            }
            for role, should_send in roles_to_send.items():
                if should_send:
                    users = User.query.filter_by(role=role).all()
                    recipient_emails.extend([user.email for user in users if user.email])

            if not recipient_emails:
                return jsonify({'error': 'No recipients selected or found'}), 404

            subject = f"Campus Announcement: {announcement.title}"
            body = f"{announcement.message}\n\nCategory: {announcement.category}\nCreated: {announcement.created_at}"
            email_sent = send_email(recipient_emails, subject, body)
            if not email_sent:
                return jsonify({'error': 'Failed to send email notifications'}), 500

        return jsonify({
            'message': 'Announcement broadcasted successfully',
            'recipients_count': len(recipient_emails) if send_email_notification else 0,
            'announcement': announcement.to_dict()
        }), 200
    except Exception as e:
        logger.error(f"Failed to broadcast announcement: {str(e)}")
        return jsonify({'error': 'Failed to broadcast announcement', 'details': str(e)}), 500