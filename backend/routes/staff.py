from flask import Blueprint, jsonify, request, send_file
from flask_jwt_extended import jwt_required, get_jwt
from database import db
from models import User, Subject, Timetable, Notes, Assignment  # Ensure Assignment is imported
from functools import wraps
from datetime import datetime
import os
import logging

staff_bp = Blueprint('staff', __name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

NOTES_FOLDER = os.path.join(os.path.dirname(__file__), '../uploads/notes')
TIMETABLE_FOLDER = os.path.join(os.path.dirname(__file__), '../uploads/timetable')
ASSIGNMENTS_FOLDER = os.path.join(os.path.dirname(__file__), '../uploads/assignments')

os.makedirs(NOTES_FOLDER, exist_ok=True)
os.makedirs(TIMETABLE_FOLDER, exist_ok=True)
os.makedirs(ASSIGNMENTS_FOLDER, exist_ok=True)

def role_required(*allowed_roles):
    def decorator(fn):
        @jwt_required()
        @wraps(fn)
        def wrapper(*args, **kwargs):
            claims = get_jwt()
            user_role = claims.get('role')
            if user_role not in allowed_roles:
                return jsonify({'error': f"Access restricted to {', '.join(allowed_roles)} roles"}), 403
            return fn(*args, **kwargs)
        return wrapper
    return decorator

# Profile Endpoint
@staff_bp.route('/profile', methods=['GET'])
@role_required('staff')
def get_staff_profile():
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

@staff_bp.route('/update_profile', methods=['PUT'])
@role_required('staff')
def update_staff_profile():
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

# Department Users Endpoint
@staff_bp.route('/department/users', methods=['GET'])
@role_required('staff')
def get_staff_department_users():
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')
        users = User.query.filter_by(departmentcode=department_code, role='student').all()
        return jsonify([user.to_dict() for user in users]), 200
    except Exception as e:
        logger.error(f"Failed to fetch department students: {str(e)}")
        return jsonify({'error': 'Failed to fetch department students', 'details': str(e)}), 500

# Subject Endpoint
@staff_bp.route('/subjects', methods=['GET'])
@role_required('staff')
def get_staff_subjects():
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')
        subjects = Subject.query.filter_by(departmentcode=department_code).all()
        return jsonify([subject.to_dict() for subject in subjects]), 200
    except Exception as e:
        logger.error(f"Failed to fetch subjects: {str(e)}")
        return jsonify({'error': 'Failed to fetch subjects', 'details': str(e)}), 500

# Timetable Endpoint
@staff_bp.route('/timetable', methods=['GET'])
@role_required('staff')
def get_staff_timetable():
    try:
        current_user = get_jwt()
        departmentcode = current_user.get('departmentcode')  # Consistent naming
        timetables = Timetable.query.filter_by(departmentcode=departmentcode).all()
        return jsonify([timetable.to_dict() for timetable in timetables]), 200
    except Exception as e:
        logger.error(f"Failed to fetch timetables: {str(e)}")
        return jsonify({'error': 'Failed to fetch timetables', 'details': str(e)}), 500

# Notes Endpoints
@staff_bp.route('/notes/upload', methods=['POST'])
@role_required('staff')
def upload_staff_notes():
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

        new_notes = Notes(semester=semester, filename=filename, departmentcode=department_code)
        db.session.add(new_notes)
        db.session.commit()

        return jsonify({'message': 'Notes uploaded successfully', 'notes': new_notes.to_dict()}), 201
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to upload notes: {str(e)}")
        return jsonify({'error': 'Failed to upload notes', 'details': str(e)}), 500

@staff_bp.route('/notes', methods=['GET'])
@role_required('staff')
def get_staff_notes():
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')
        notes = Notes.query.filter_by(departmentcode=department_code).all()
        return jsonify([note.to_dict() for note in notes]), 200
    except Exception as e:
        logger.error(f"Failed to fetch notes: {str(e)}")
        return jsonify({'error': 'Failed to fetch notes', 'details': str(e)}), 500

@staff_bp.route('/notes/<int:note_id>', methods=['DELETE'])
@role_required('staff')
def delete_staff_note(note_id):
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



@staff_bp.route('/assignments', methods=['GET'])
@role_required('staff')
def get_staff_assignments():
    try:
        current_user = get_jwt()
        instructor_id = current_user.get('sub')  # Use admission_number from JWT
        logger.info(f"Fetching assignments for instructor_id: {instructor_id}")
        assignments = Assignment.query.filter_by(instructor_id=instructor_id).all()
        logger.info(f"Found {len(assignments)} assignments")
        return jsonify({'assignments': [assignment.to_dict() for assignment in assignments]}), 200
    except Exception as e:
        logger.error(f"Failed to fetch assignments: {str(e)}")
        return jsonify({'error': 'Failed to fetch assignments', 'details': str(e)}), 500

@staff_bp.route('/assignments/download/<filename>', methods=['GET'])
@role_required('staff')
def download_assignment(filename):
    try:
        current_user = get_jwt()
        instructor_id = current_user.get('sub')
        assignment = Assignment.query.filter_by(instructor_id=instructor_id, submission_filename=filename).first()
        if not assignment:
            return jsonify({'error': 'Assignment not found or not authorized'}), 404

        file_path = os.path.join(ASSIGNMENTS_FOLDER, filename)
        if not os.path.exists(file_path):
            return jsonify({'error': 'File not found on server'}), 404

        return send_file(file_path, as_attachment=True, download_name=filename)
    except Exception as e:
        logger.error(f"Failed to download assignment: {str(e)}")
        return jsonify({'error': 'Failed to download assignment', 'details': str(e)}), 500