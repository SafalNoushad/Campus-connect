from flask import Blueprint, jsonify, request, send_from_directory
from flask_jwt_extended import jwt_required, get_jwt
from database import db
from models import User, Subject, Timetable, Notes, Requests
from functools import wraps
from datetime import datetime
import os
import logging

hod_bp = Blueprint('hod', __name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

NOTES_FOLDER = os.path.join(os.path.dirname(__file__), '../uploads/notes')
TIMETABLE_FOLDER = os.path.join(os.path.dirname(__file__), '../uploads/timetable')
REQUESTS_FOLDER = os.path.join(os.path.dirname(__file__), '../uploads/requests')

os.makedirs(NOTES_FOLDER, exist_ok=True)
os.makedirs(TIMETABLE_FOLDER, exist_ok=True)
os.makedirs(REQUESTS_FOLDER, exist_ok=True)

def role_required(*allowed_roles):
    def decorator(fn):
        @jwt_required()
        @wraps(fn)
        def wrapper(*args, **kwargs):
            claims = get_jwt()
            user_role = claims.get('role')
            if user_role not in allowed_roles:
                logger.warning(f"Unauthorized role: {user_role}")
                return jsonify({'error': f"Access restricted to {', '.join(allowed_roles)} roles"}), 403
            return fn(*args, **kwargs)
        return wrapper
    return decorator

# Profile Endpoint
@hod_bp.route('/profile', methods=['GET'])
@role_required('hod')
def get_hod_profile():
    try:
        current_user = get_jwt()
        admission_number = current_user.get('sub')
        user = User.query.get(admission_number)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        return jsonify(user.to_dict()), 200
    except Exception as e:
        logger.error(f"Failed to fetch profile: {str(e)}")
        return jsonify({'error': 'Failed to fetch profile', 'details': str(e)}), 500

@hod_bp.route('/update_profile', methods=['PUT'])
@role_required('hod')
def update_hod_profile():
    try:
        current_user = get_jwt()
        admission_number = current_user.get('sub')
        data = request.get_json()

        user = User.query.get(admission_number)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        user.username = data.get('username', user.username)
        user.phone_number = data.get('phone_number', user.phone_number)

        db.session.commit()
        return jsonify({'message': 'Profile updated successfully', 'user': user.to_dict()}), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to update profile: {str(e)}")
        return jsonify({'error': 'Failed to update profile', 'details': str(e)}), 500

# Subject Endpoints
@hod_bp.route('/subjects', methods=['GET'])
@role_required('hod')
def get_hod_subjects():
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')
        subjects = Subject.query.filter_by(departmentcode=department_code).all()
        return jsonify([s.to_dict() for s in subjects]), 200
    except Exception as e:
        logger.error(f"Failed to fetch subjects: {str(e)}")
        return jsonify({'error': 'Failed to fetch subjects', 'details': str(e)}), 500

@hod_bp.route('/subjects', methods=['POST'])
@role_required('hod', 'admin')
def add_hod_subject():
    try:
        data = request.get_json()
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')
        semester = data.get('semester')
        subject_code = data.get('subject_code')
        subject_name = data.get('subject_name')
        credits = data.get('credits')
        instructor_id = data.get('instructor_id')

        if not all([semester, subject_code, subject_name, credits]) or semester not in [f'S{i}' for i in range(1, 9)] or int(credits) <= 0:
            return jsonify({'error': 'Invalid or missing fields'}), 400

        if Subject.query.filter_by(subject_code=subject_code).first():
            return jsonify({'error': 'Subject code already exists'}), 409

        if instructor_id and not User.query.filter(
            User.admission_number == instructor_id,
            User.departmentcode == department_code,
            User.role.in_(['staff', 'hod'])
        ).first():
            return jsonify({'error': 'Invalid instructor ID or not in department'}), 400

        new_subject = Subject(
            semester=semester,
            subject_code=subject_code,
            subject_name=subject_name,
            credits=credits,
            departmentcode=department_code,
            instructor_id=instructor_id
        )
        db.session.add(new_subject)
        db.session.commit()
        return jsonify({'message': 'Subject added successfully', 'subject': new_subject.to_dict()}), 201
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to add subject: {str(e)}")
        return jsonify({'error': 'Failed to add subject', 'details': str(e)}), 500

@hod_bp.route('/subjects/<string:subject_code>', methods=['DELETE'])
@role_required('hod')
def delete_hod_subject(subject_code):
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')
        subject = Subject.query.filter_by(subject_code=subject_code, departmentcode=department_code).first()
        if not subject:
            return jsonify({'error': 'Subject not found or not in your department'}), 404

        db.session.delete(subject)
        db.session.commit()
        return jsonify({'message': 'Subject deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to delete subject: {str(e)}")
        return jsonify({'error': 'Failed to delete subject', 'details': str(e)}), 500

# Department Users Endpoints
@hod_bp.route('/department/users', methods=['GET'])
@role_required('hod')
def get_hod_department_users():
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')
        users = User.query.filter_by(departmentcode=department_code, role='student').all()
        return jsonify([user.to_dict() for user in users]), 200
    except Exception as e:
        logger.error(f"Failed to fetch department students: {str(e)}")
        return jsonify({'error': 'Failed to fetch department students', 'details': str(e)}), 500

@hod_bp.route('/department/users/<string:admission_number>', methods=['PUT'])
@role_required('hod')
def update_hod_department_user(admission_number):
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')
        data = request.get_json()
        
        user = User.query.filter_by(admission_number=admission_number, departmentcode=department_code, role='student').first()
        if not user:
            return jsonify({'error': 'Student not found or not in your department'}), 404

        user.username = data.get('username', user.username)
        user.email = data.get('email', user.email)
        user.phone_number = data.get('phone_number', user.phone_number)
        user.batch = data.get('batch', user.batch)
        
        db.session.commit()
        return jsonify({'message': 'Student updated successfully', 'user': user.to_dict()}), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to update student: {str(e)}")
        return jsonify({'error': 'Failed to update student', 'details': str(e)}), 500

@hod_bp.route('/department/users/<string:admission_number>', methods=['DELETE'])
@role_required('hod')
def delete_hod_department_user(admission_number):
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')
        
        user = User.query.filter_by(admission_number=admission_number, departmentcode=department_code, role='student').first()
        if not user:
            return jsonify({'error': 'Student not found or not in your department'}), 404

        db.session.delete(user)
        db.session.commit()
        return jsonify({'message': 'Student deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to delete student: {str(e)}")
        return jsonify({'error': 'Failed to delete student', 'details': str(e)}), 500

# Timetable Endpoints
@hod_bp.route('/timetable', methods=['GET'])
@role_required('hod')
def get_hod_timetable():
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')
        timetables = Timetable.query.filter_by(departmentcode=department_code).all()
        return jsonify([t.to_dict() for t in timetables]), 200
    except Exception as e:
        logger.error(f"Failed to fetch timetable: {str(e)}")
        return jsonify({'error': 'Failed to fetch timetable', 'details': str(e)}), 500

@hod_bp.route('/timetable/upload', methods=['POST'])
@role_required('hod')
def upload_timetable():
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')
        if 'semester' not in request.form or 'file' not in request.files:
            return jsonify({'error': 'Missing semester or file'}), 400

        file = request.files['file']
        semester = request.form['semester']

        if semester not in [f'S{i}' for i in range(1, 9)] or not file.filename.endswith('.xlsx'):
            return jsonify({'error': 'Invalid semester or file type'}), 400

        filename = f"{semester}_timetable_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.xlsx"
        file_path = os.path.join(TIMETABLE_FOLDER, filename)
        file.save(file_path)

        new_timetable = Timetable(semester=semester, filename=filename, departmentcode=department_code)
        db.session.add(new_timetable)
        db.session.commit()

        return jsonify({'message': 'Timetable uploaded successfully', 'timetable': new_timetable.to_dict()}), 201
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to upload timetable: {str(e)}")
        return jsonify({'error': 'Failed to upload timetable', 'details': str(e)}), 500

@hod_bp.route('/timetable/<int:timetable_id>', methods=['DELETE'])
@role_required('hod')
def delete_hod_timetable(timetable_id):
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')
        timetable = Timetable.query.filter_by(id=timetable_id, departmentcode=department_code).first()
        if not timetable:
            return jsonify({'error': 'Timetable not found'}), 404

        file_path = os.path.join(TIMETABLE_FOLDER, timetable.filename)
        if os.path.exists(file_path):
            os.remove(file_path)

        db.session.delete(timetable)
        db.session.commit()
        return jsonify({'message': 'Timetable deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to delete timetable: {str(e)}")
        return jsonify({'error': 'Failed to delete timetable', 'details': str(e)}), 500

# Notes Endpoints
@hod_bp.route('/notes', methods=['GET'])
@role_required('hod')
def get_hod_notes():
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')
        notes = Notes.query.filter_by(departmentcode=department_code).all()
        return jsonify([n.to_dict() for n in notes]), 200
    except Exception as e:
        logger.error(f"Failed to fetch notes: {str(e)}")
        return jsonify({'error': 'Failed to fetch notes', 'details': str(e)}), 500

@hod_bp.route('/notes/upload', methods=['POST'])
@role_required('hod')
def upload_notes():
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')
        if not all(key in request.form for key in ['semester', 'subject_name', 'module_number']) or 'file' not in request.files:
            return jsonify({'error': 'Missing required fields or file'}), 400

        file = request.files['file']
        semester = request.form['semester']
        subject_name = request.form['subject_name']
        module_number = request.form['module_number']

        if semester not in [f'S{i}' for i in range(1, 9)] or not file.filename.endswith('.pdf') or int(module_number) <= 0:
            return jsonify({'error': 'Invalid semester, file type, or module number'}), 400

        subject = Subject.query.filter_by(departmentcode=department_code, semester=semester, subject_name=subject_name).first()
        if not subject:
            return jsonify({'error': 'Subject not found'}), 404

        filename = f"{semester}_{subject_name}_Module{module_number}_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.pdf"
        file_path = os.path.join(NOTES_FOLDER, filename)
        file.save(file_path)

        new_note = Notes(semester=semester, filename=filename, departmentcode=department_code)
        db.session.add(new_note)
        db.session.commit()

        return jsonify({'message': 'Notes uploaded successfully', 'note': new_note.to_dict()}), 201
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to upload notes: {str(e)}")
        return jsonify({'error': 'Failed to upload notes', 'details': str(e)}), 500

@hod_bp.route('/notes/<int:note_id>', methods=['DELETE'])
@role_required('hod')
def delete_hod_note(note_id):
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')
        note = Notes.query.filter_by(id=note_id, departmentcode=department_code).first()
        if not note:
            return jsonify({'error': 'Note not found or not authorized'}), 404

        file_path = os.path.join(NOTES_FOLDER, note.filename)
        if os.path.exists(file_path):
            os.remove(file_path)

        db.session.delete(note)
        db.session.commit()
        return jsonify({'message': 'Note deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to delete note: {str(e)}")
        return jsonify({'error': 'Failed to delete note', 'details': str(e)}), 500

# Staff Management Endpoints
@hod_bp.route('/staff/list', methods=['GET'])
@role_required('hod')
def list_staff():
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')
        staff = User.query.filter(
            User.departmentcode == department_code,
            User.role.in_(['staff', 'hod'])
        ).all()
        return jsonify([s.to_dict() for s in staff]), 200
    except Exception as e:
        logger.error(f"Failed to fetch staff: {str(e)}")
        return jsonify({'error': 'Failed to fetch staff', 'details': str(e)}), 500

@hod_bp.route('/staff/add', methods=['POST'])
@role_required('hod')
def add_staff():
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')
        data = request.get_json()
        staff = User(
            admission_number=data['admission_number'],
            email=data['email'],
            username=data['username'],
            role='staff',
            departmentcode=department_code,
            semester=data.get('semester'),
            phone_number=data.get('phone_number'),
            batch=data.get('batch')
        )
        staff.set_password(data['password'])
        db.session.add(staff)
        db.session.commit()
        return jsonify({'message': 'Staff added successfully', 'staff': staff.to_dict()}), 201
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to add staff: {str(e)}")
        return jsonify({'error': 'Failed to add staff', 'details': str(e)}), 500

# Request Management Endpoints
@hod_bp.route('/requests', methods=['GET'])
@role_required('hod')
def get_department_requests():
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')

        if not department_code:
            logger.warning(f"HOD missing departmentcode in JWT: {current_user}")
            return jsonify({'error': 'Department code not set in token'}), 400

        pending_requests = Requests.query.join(User).filter(
            User.departmentcode == department_code,
            Requests.status == 'pending'
        ).all()
        
        approved_requests = Requests.query.join(User).filter(
            User.departmentcode == department_code,
            Requests.status.in_(['approved', 'rejected'])
        ).all()

        response = {
            'pending': [req.to_dict() for req in pending_requests],
            'approved': [req.to_dict() for req in approved_requests]
        }
        logger.info(f"Fetched {len(pending_requests)} pending and {len(approved_requests)} approved/rejected requests for HOD in department {department_code}")
        return jsonify(response), 200
    except Exception as e:
        logger.error(f"Failed to fetch requests for HOD: {str(e)}")
        return jsonify({'error': 'Failed to fetch requests', 'details': str(e)}), 500

@hod_bp.route('/requests/<int:application_id>/update', methods=['PUT'])
@role_required('hod')
def update_request_status(application_id):
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')

        data = request.get_json()
        status = data.get('status')
        logger.info(f"Received update request for application_id {application_id} with status {status}")

        if status not in ['approved', 'rejected']:
            logger.warning(f"Invalid status {status} for application_id {application_id}")
            return jsonify({'error': 'Invalid status'}), 400

        request_entry = Requests.query.join(User).filter(
            Requests.application_id == application_id,
            User.departmentcode == department_code
        ).first()

        if not request_entry:
            logger.warning(f"Request {application_id} not found or not in HOD's department")
            return jsonify({'error': 'Request not found or not authorized'}), 404

        if request_entry.status != 'pending':
            logger.warning(f"Request {application_id} is already {request_entry.status}")
            return jsonify({'error': 'Request already processed'}), 400

        request_entry.status = status
        db.session.commit()
        logger.info(f"HOD updated request {application_id} to {status}")
        return jsonify({'message': f'Request {status} successfully', 'request': request_entry.to_dict()}), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to update request {application_id}: {str(e)}")
        return jsonify({'error': 'Failed to update request', 'details': str(e)}), 500

@hod_bp.route('/download/requests/<filename>', methods=['GET'])
@role_required('hod')
def download_request(filename):
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')

        request_entry = Requests.query.join(User).filter(
            Requests.filename == filename,
            User.departmentcode == department_code
        ).first()

        if not request_entry:
            logger.warning(f"Request file {filename} not found or not authorized for HOD in department {department_code}")
            return jsonify({'error': 'File not found or not authorized'}), 404

        file_path = os.path.join(REQUESTS_FOLDER, filename)
        if not os.path.exists(file_path):
            logger.warning(f"Request file {filename} not found on server")
            return jsonify({'error': 'File not found on server'}), 404

        logger.info(f"Serving file {filename} for download")
        return send_from_directory(REQUESTS_FOLDER, filename, as_attachment=True)
    except Exception as e:
        logger.error(f"Failed to download request file {filename}: {str(e)}")
        return jsonify({'error': 'Failed to download file', 'details': str(e)}), 500