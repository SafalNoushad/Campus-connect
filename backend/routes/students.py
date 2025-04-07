from flask import Blueprint, jsonify, send_from_directory, request
from flask_jwt_extended import jwt_required, get_jwt
from database import db
from models import User, Notes, Timetable, Subject, Assignment, Requests
from utils.token import role_required
import os
import logging
from werkzeug.utils import secure_filename
from datetime import datetime

students_bp = Blueprint('student', __name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

NOTES_FOLDER = os.path.join(os.path.dirname(__file__), '../uploads/notes')
TIMETABLE_FOLDER = os.path.join(os.path.dirname(__file__), '../uploads/timetable')
ASSIGNMENTS_FOLDER = os.path.join(os.path.dirname(__file__), '../uploads/assignments')
REQUESTS_FOLDER = os.path.join(os.path.dirname(__file__), '../uploads/requests')

# Ensure directories exist
os.makedirs(NOTES_FOLDER, exist_ok=True)
os.makedirs(TIMETABLE_FOLDER, exist_ok=True)
os.makedirs(ASSIGNMENTS_FOLDER, exist_ok=True)
os.makedirs(REQUESTS_FOLDER, exist_ok=True)

@students_bp.route('/notes', methods=['GET'])
@jwt_required()
@role_required('student')
def get_student_notes():
    try:
        current_user = get_jwt()
        admission_number = current_user.get('sub')
        department_code = current_user.get('departmentcode')
        semester = current_user.get('semester')

        logger.info(f"Fetching notes for student {admission_number} with departmentcode={department_code}, semester={semester}")

        if not department_code or not semester:
            logger.warning(f"Student {admission_number} missing departmentcode or semester in JWT: {current_user}")
            return jsonify({'error': 'Department code or semester not set in token'}), 400

        notes = Notes.query.filter_by(departmentcode=department_code, semester=semester).all()
        logger.info(f"Fetched {len(notes)} notes for student {admission_number}")
        return jsonify([note.to_dict() for note in notes]), 200
    except Exception as e:
        logger.error(f"Failed to fetch notes for student {admission_number}: {str(e)}")
        return jsonify({'error': 'Failed to fetch notes', 'details': str(e)}), 500

@students_bp.route('/timetable', methods=['GET'])
@jwt_required()
@role_required('student')
def get_student_timetable():
    try:
        current_user = get_jwt()
        admission_number = current_user.get('sub')
        department_code = current_user.get('departmentcode')
        semester = current_user.get('semester')

        logger.info(f"Fetching timetable for student {admission_number} with departmentcode={department_code}, semester={semester}")

        if not department_code or not semester:
            logger.warning(f"Student {admission_number} missing departmentcode or semester in JWT: {current_user}")
            return jsonify({'error': 'Department code or semester not set in token'}), 400

        timetables = Timetable.query.filter_by(departmentcode=department_code, semester=semester).all()
        logger.info(f"Fetched {len(timetables)} timetables for student {admission_number}")
        return jsonify([timetable.to_dict() for timetable in timetables]), 200
    except Exception as e:
        logger.error(f"Failed to fetch timetables for student {admission_number}: {str(e)}")
        return jsonify({'error': 'Failed to fetch timetables', 'details': str(e)}), 500

@students_bp.route('/subjects', methods=['GET'])
@jwt_required()
@role_required('student')
def get_student_subjects():
    try:
        current_user = get_jwt()
        admission_number = current_user.get('sub')
        department_code = current_user.get('departmentcode')
        semester = current_user.get('semester')

        logger.info(f"Fetching subjects for student {admission_number} with departmentcode={department_code}, semester={semester}")

        if not department_code or not semester:
            logger.warning(f"Student {admission_number} missing departmentcode or semester in JWT: {current_user}")
            return jsonify({'error': 'Department code or semester not set in token'}), 400

        subjects = Subject.query.filter_by(departmentcode=department_code, semester=semester).all()
        logger.info(f"Fetched {len(subjects)} subjects for student {admission_number}")

        if not subjects:
            logger.info(f"No subjects found for departmentcode={department_code}, semester={semester}")
            return jsonify({'message': 'No subjects available for your department/semester', 'subjects': []}), 200

        subject_list = []
        for subject in subjects:
            subject_dict = subject.to_dict()
            if subject.instructor_id:
                instructor = User.query.get(subject.instructor_id)
                subject_dict['instructor_name'] = instructor.username if instructor else 'Not Assigned'
            else:
                subject_dict['instructor_name'] = 'Not Assigned'
            subject_list.append(subject_dict)

        return jsonify(subject_list), 200
    except Exception as e:
        logger.error(f"Failed to fetch subjects for student {admission_number}: {str(e)}")
        return jsonify({'error': 'Failed to fetch subjects', 'details': str(e)}), 500

@students_bp.route('/teachers', methods=['GET'])
@jwt_required()
@role_required('student')
def get_student_teachers():
    try:
        current_user = get_jwt()
        admission_number = current_user.get('sub')
        department_code = current_user.get('departmentcode')

        logger.info(f"Fetching teachers for student {admission_number} with departmentcode={department_code}")

        if not department_code:
            logger.warning(f"Student {admission_number} missing departmentcode in JWT: {current_user}")
            return jsonify({'error': 'Department code not set in token'}), 400

        teachers = User.query.filter(
            User.departmentcode == department_code,
            User.role.in_(['staff', 'hod'])
        ).all()
        logger.info(f"Fetched {len(teachers)} teachers for student {admission_number}")

        if not teachers:
            logger.info(f"No teachers found for departmentcode={department_code}")
            return jsonify({'message': 'No teachers available for your department', 'teachers': []}), 200

        return jsonify([teacher.to_dict() for teacher in teachers]), 200
    except Exception as e:
        logger.error(f"Failed to fetch teachers for student {admission_number}: {str(e)}")
        return jsonify({'error': 'Failed to fetch teachers', 'details': str(e)}), 500

@students_bp.route('/download/notes/<filename>', methods=['GET'])
@jwt_required()
@role_required('student')
def download_note(filename):
    try:
        current_user = get_jwt()
        admission_number = current_user.get('sub')
        department_code = current_user.get('departmentcode')
        semester = current_user.get('semester')

        logger.info(f"Downloading note {filename} for student {admission_number}")

        if not department_code or not semester:
            logger.warning(f"Student {admission_number} missing departmentcode or semester in JWT: {current_user}")
            return jsonify({'error': 'Department code or semester not set in token'}), 400

        note = Notes.query.filter_by(
            filename=filename,
            departmentcode=department_code,
            semester=semester
        ).first()

        if not note:
            logger.warning(f"Note {filename} not found or not authorized for student {admission_number}")
            return jsonify({'error': 'Note not found or not authorized'}), 404

        file_path = os.path.join(NOTES_FOLDER, filename)
        if not os.path.exists(file_path):
            logger.error(f"Note file {file_path} not found on server")
            return jsonify({'error': 'File not found on server'}), 404

        logger.info(f"Student {admission_number} downloaded note {filename}")
        return send_from_directory(NOTES_FOLDER, filename, as_attachment=True)
    except Exception as e:
        logger.error(f"Failed to download note {filename} for student {admission_number}: {str(e)}")
        return jsonify({'error': 'Failed to download note', 'details': str(e)}), 500

@students_bp.route('/download/timetable/<filename>', methods=['GET'])
@jwt_required()
@role_required('student')
def download_timetable(filename):
    try:
        current_user = get_jwt()
        admission_number = current_user.get('sub')
        department_code = current_user.get('departmentcode')
        semester = current_user.get('semester')

        logger.info(f"Downloading timetable {filename} for student {admission_number}")

        if not department_code or not semester:
            logger.warning(f"Student {admission_number} missing departmentcode or semester in JWT: {current_user}")
            return jsonify({'error': 'Department code or semester not set in token'}), 400

        timetable = Timetable.query.filter_by(
            filename=filename,
            departmentcode=department_code,
            semester=semester
        ).first()

        if not timetable:
            logger.warning(f"Timetable {filename} not found or not authorized for student {admission_number}")
            return jsonify({'error': 'Timetable not found or not authorized'}), 404

        file_path = os.path.join(TIMETABLE_FOLDER, filename)
        if not os.path.exists(file_path):
            logger.error(f"Timetable file {file_path} not found on server")
            return jsonify({'error': 'File not found on server'}), 404

        logger.info(f"Student {admission_number} downloaded timetable {filename}")
        return send_from_directory(TIMETABLE_FOLDER, filename, as_attachment=True)
    except Exception as e:
        logger.error(f"Failed to download timetable {filename} for student {admission_number}: {str(e)}")
        return jsonify({'error': 'Failed to download timetable', 'details': str(e)}), 500

@students_bp.route('/profile', methods=['GET'])
@jwt_required()
@role_required('student')
def get_student_profile():
    try:
        current_user = get_jwt()
        admission_number = current_user.get('sub')

        logger.info(f"Fetching profile for student {admission_number}")

        user = User.query.get(admission_number)
        if not user:
            logger.warning(f"Profile not found for student {admission_number}")
            return jsonify({'error': 'User not found'}), 404

        logger.info(f"Fetched profile for student {admission_number}")
        return jsonify(user.to_dict()), 200
    except Exception as e:
        logger.error(f"Failed to fetch profile for student {admission_number}: {str(e)}")
        return jsonify({'error': 'Failed to fetch profile', 'details': str(e)}), 500

@students_bp.route('/assignments', methods=['GET'])
@jwt_required()
@role_required('student')
def get_student_assignments():
    try:
        current_user = get_jwt()
        admission_number = current_user.get('sub')
        department_code = current_user.get('departmentcode')

        logger.info(f"Fetching submitted assignments for student {admission_number} with departmentcode={department_code}")

        if not department_code:
            logger.warning(f"Student {admission_number} missing departmentcode in JWT: {current_user}")
            return jsonify({'error': 'Department code not set in token'}), 400

        # Filter assignments where submitted_by matches the current user's admission_number
        assignments = Assignment.query.filter_by(
            departmentcode=department_code,
            submitted_by=admission_number
        ).all()
        logger.info(f"Fetched {len(assignments)} submitted assignments for student {admission_number}")

        if not assignments:
            logger.info(f"No submitted assignments found for student {admission_number} in departmentcode={department_code}")
            return jsonify({'message': 'No submitted assignments found', 'assignments': []}), 200

        return jsonify({'assignments': [assignment.to_dict() for assignment in assignments]}), 200
    except Exception as e:
        logger.error(f"Failed to fetch assignments for student {admission_number}: {str(e)}")
        return jsonify({'error': 'Failed to fetch assignments', 'details': str(e)}), 500

@students_bp.route('/assignments/create-and-submit', methods=['POST'])
@jwt_required()
@role_required('student')
def create_and_submit_assignment():
    try:
        current_user = get_jwt()
        admission_number = current_user.get('sub')
        department_code = current_user.get('departmentcode')

        data = request.form
        subject_code = data.get('subject_code')
        staff_name = data.get('staff_name')
        assignment_number = data.get('assignment_number')

        logger.info(f"Student {admission_number} attempting to submit assignment: {subject_code}, {assignment_number}")

        if not all([subject_code, staff_name, assignment_number]):
            logger.warning(f"Missing required fields for student {admission_number}")
            return jsonify({'error': 'Missing required fields'}), 400

        if 'file' not in request.files:
            logger.warning(f"No file provided by student {admission_number}")
            return jsonify({'error': 'No file provided'}), 400

        file = request.files['file']
        if not file.filename.endswith('.pdf'):
            logger.warning(f"Invalid file format by student {admission_number}")
            return jsonify({'error': 'Only PDF files allowed'}), 400

        # Check if subject exists
        subject = Subject.query.filter_by(subject_code=subject_code, departmentcode=department_code).first()
        if not subject:
            logger.warning(f"Subject {subject_code} not found for department {department_code}")
            return jsonify({'error': 'Subject not found'}), 404

        # Check if assignment exists
        assignment = Assignment.query.filter_by(
            subject_code=subject_code,
            assignment_number=int(assignment_number),
            departmentcode=department_code
        ).first()

        if not assignment:
            # Create new assignment
            staff = User.query.filter_by(username=staff_name, role='staff').first()
            if not staff:
                logger.warning(f"Staff {staff_name} not found")
                return jsonify({'error': 'Staff not found'}), 404

            assignment = Assignment(
                subject_code=subject_code,
                staff_name=staff_name,
                assignment_number=int(assignment_number),
                instructor_id=staff.admission_number,
                departmentcode=department_code,
                created_at=datetime.utcnow()
            )
            db.session.add(assignment)
            db.session.flush()  # Get assignment ID

        if assignment.submitted_by:
            logger.warning(f"Assignment already submitted by {assignment.submitted_by}")
            return jsonify({'error': 'Assignment already submitted'}), 400

        # Save file
        student = User.query.get(admission_number)
        filename = f"{subject_code}_{student.username}_assignment_{assignment_number}.pdf"
        file_path = os.path.join(ASSIGNMENTS_FOLDER, filename)
        file.save(file_path)

        # Update assignment
        assignment.submission_filename = filename
        assignment.submitted_by = admission_number
        assignment.submitted_at = datetime.utcnow()
        db.session.commit()

        logger.info(f"Student {admission_number} submitted assignment {filename}")
        return jsonify({'message': 'Assignment submitted successfully', 'assignment': assignment.to_dict()}), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to submit assignment for {admission_number}: {str(e)}")
        return jsonify({'error': 'Failed to submit assignment', 'details': str(e)}), 500

@students_bp.route('/download/assignments/<filename>', methods=['GET'])
@jwt_required()
@role_required('student')
def download_assignment(filename):
    try:
        current_user = get_jwt()
        admission_number = current_user.get('sub')
        department_code = current_user.get('departmentcode')

        logger.info(f"Downloading assignment {filename} for student {admission_number}")

        if not department_code:
            logger.warning(f"Student {admission_number} missing departmentcode in JWT: {current_user}")
            return jsonify({'error': 'Department code not set in token'}), 400

        assignment = Assignment.query.filter_by(
            submission_filename=filename,
            departmentcode=department_code
        ).first()

        if not assignment or assignment.submitted_by != admission_number:
            logger.warning(f"Assignment {filename} not found or not authorized for student {admission_number}")
            return jsonify({'error': 'Assignment not found or not authorized'}), 404

        file_path = os.path.join(ASSIGNMENTS_FOLDER, filename)
        if not os.path.exists(file_path):
            logger.error(f"Assignment file {file_path} not found on server")
            return jsonify({'error': 'File not found on server'}), 404

        logger.info(f"Student {admission_number} downloaded assignment {filename}")
        return send_from_directory(ASSIGNMENTS_FOLDER, filename, as_attachment=True)
    except Exception as e:
        logger.error(f"Failed to download assignment {filename} for student {admission_number}: {str(e)}")
        return jsonify({'error': 'Failed to download assignment', 'details': str(e)}), 500

@students_bp.route('/requests/upload', methods=['POST'])
@jwt_required()
@role_required('student')
def upload_request():
    try:
        current_user = get_jwt()
        admission_number = current_user.get('sub')

        logger.info(f"Student {admission_number} attempting to upload a request")

        category = request.form.get('category')
        file = request.files.get('file')

        if not category or not file:
            logger.warning(f"Missing category or file for student {admission_number}")
            return jsonify({'error': 'Missing category or file'}), 400

        if category not in ['medical_leave', 'duty_leave']:
            logger.warning(f"Invalid category {category} for student {admission_number}")
            return jsonify({'error': 'Invalid category'}), 400

        if not file.filename.endswith('.pdf'):
            logger.warning(f"Invalid file format by student {admission_number}")
            return jsonify({'error': 'Only PDF files allowed'}), 400

        # Generate unique filename
        filename = f"{category}_{admission_number}_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.pdf"
        file_path = os.path.join(REQUESTS_FOLDER, filename)
        file.save(file_path)

        # Save request to database
        new_request = Requests(
            category=category,
            filename=filename,
            admission_number=admission_number,
            status='pending',  # Default status
            created_at=datetime.utcnow()
        )
        db.session.add(new_request)
        db.session.commit()

        logger.info(f"Student {admission_number} uploaded request {filename}")
        return jsonify({'message': 'Request uploaded successfully', 'request': new_request.to_dict()}), 201
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to upload request for student {admission_number}: {str(e)}")
        return jsonify({'error': 'Failed to upload request', 'details': str(e)}), 500

@students_bp.route('/requests', methods=['GET'])
@jwt_required()
@role_required('student')
def get_student_requests():
    try:
        current_user = get_jwt()
        admission_number = current_user.get('sub')

        logger.info(f"Fetching requests for student {admission_number}")

        requests = Requests.query.filter_by(admission_number=admission_number).all()
        logger.info(f"Fetched {len(requests)} requests for student {admission_number}")

        if not requests:
            logger.info(f"No requests found for student {admission_number}")
            return jsonify([]), 200

        return jsonify([req.to_dict() for req in requests]), 200
    except Exception as e:
        logger.error(f"Failed to fetch requests for student {admission_number}: {str(e)}")
        return jsonify({'error': 'Failed to fetch requests', 'details': str(e)}), 500

@students_bp.route('/download/requests/<filename>', methods=['GET'])
@jwt_required()
@role_required('student')
def download_request(filename):
    try:
        current_user = get_jwt()
        admission_number = current_user.get('sub')

        logger.info(f"Downloading request {filename} for student {admission_number}")

        request_entry = Requests.query.filter_by(
            filename=filename,
            admission_number=admission_number
        ).first()

        if not request_entry:
            logger.warning(f"Request {filename} not found or not authorized for student {admission_number}")
            return jsonify({'error': 'Request not found or not authorized'}), 404

        file_path = os.path.join(REQUESTS_FOLDER, filename)
        if not os.path.exists(file_path):
            logger.error(f"Request file {file_path} not found on server")
            return jsonify({'error': 'File not found on server'}), 404

        logger.info(f"Student {admission_number} downloaded request {filename}")
        return send_from_directory(REQUESTS_FOLDER, filename, as_attachment=True)
    except Exception as e:
        logger.error(f"Failed to download request {filename} for student {admission_number}: {str(e)}")
        return jsonify({'error': 'Failed to download request', 'details': str(e)}), 500
    
@students_bp.route('/requests/<int:request_id>', methods=['PUT'])
@jwt_required()
@role_required('student')
def edit_request(request_id):
    try:
        current_user = get_jwt()
        admission_number = current_user.get('sub')

        logger.info(f"Student {admission_number} attempting to edit request {request_id}")

        # Check if request exists and belongs to the student
        request_entry = Requests.query.filter_by(application_id=request_id, admission_number=admission_number).first()
        if not request_entry:
            logger.warning(f"Request {request_id} not found or not authorized for student {admission_number}")
            return jsonify({'error': 'Request not found or not authorized'}), 404

        data = request.get_json()
        logger.debug(f"Received data: {data}")
        if not data or 'category' not in data:
            logger.warning(f"Missing category in edit request for student {admission_number}")
            return jsonify({'error': 'Missing category'}), 400

        category = data['category']
        if category not in ['medical_leave', 'duty_leave']:
            logger.warning(f"Invalid category {category} for student {admission_number}")
            return jsonify({'error': 'Invalid category'}), 400

        # Update the request
        request_entry.category = category
        db.session.commit()

        logger.info(f"Student {admission_number} edited request {request_id}")
        return jsonify({'message': 'Request updated successfully', 'request': request_entry.to_dict()}), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to edit request {request_id} for student {admission_number}: {str(e)}", exc_info=True)
        return jsonify({'error': 'Internal Server Error', 'details': str(e)}), 500

@students_bp.route('/requests/<int:request_id>', methods=['DELETE'])
@jwt_required()
@role_required('student')
def delete_request(request_id):
    try:
        current_user = get_jwt()
        admission_number = current_user.get('sub')

        logger.info(f"Student {admission_number} attempting to delete request {request_id}")

        # Check if request exists and belongs to the student
        request_entry = Requests.query.filter_by(application_id=request_id, admission_number=admission_number).first()
        if not request_entry:
            logger.warning(f"Request {request_id} not found or not authorized for student {admission_number}")
            return jsonify({'error': 'Request not found or not authorized'}), 404

        # Delete the file from storage
        file_path = os.path.join(REQUESTS_FOLDER, request_entry.filename)
        if os.path.exists(file_path):
            os.remove(file_path)
            logger.info(f"Deleted request file {file_path} for student {admission_number}")

        # Delete the request from the database
        db.session.delete(request_entry)
        db.session.commit()

        logger.info(f"Student {admission_number} deleted request {request_id}")
        return jsonify({'message': 'Request deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to delete request {request_id} for student {admission_number}: {str(e)}", exc_info=True)
        return jsonify({'error': 'Internal Server Error', 'details': str(e)}), 500