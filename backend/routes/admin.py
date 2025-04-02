from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt
from database import db
from models import User, Subject, Department, Timetable, Notes, Assignment, Requests
from functools import wraps
import bcrypt
import re
import logging
import os

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

admin_bp = Blueprint('admin', __name__)

# Directory for uploaded files
ASSIGNMENTS_FOLDER = os.path.join(os.path.dirname(__file__), '../uploads/assignments')
REQUESTS_FOLDER = os.path.join(os.path.dirname(__file__), '../uploads/requests')
os.makedirs(ASSIGNMENTS_FOLDER, exist_ok=True)
os.makedirs(REQUESTS_FOLDER, exist_ok=True)

# Custom decorator to enforce admin access
def admin_required(fn):
    @jwt_required()
    @wraps(fn)
    def wrapper(*args, **kwargs):
        claims = get_jwt()
        if claims.get('role') != 'admin':
            logger.warning(f"Unauthorized access attempt to {fn.__name__} by non-admin")
            return jsonify({'error': 'Admin access required'}), 403
        return fn(*args, **kwargs)
    return wrapper

# Fetch all users (excluding admins)
@admin_bp.route('/users', methods=['GET'])
@admin_required
def get_users():
    try:
        users = User.query.filter(User.role != 'admin').all()
        logger.info(f"Fetched {len(users)} non-admin users")
        return jsonify([user.to_dict() for user in users]), 200
    except Exception as e:
        logger.error(f"Failed to fetch users: {str(e)}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

# Fetch users grouped by department (critical for instructor dropdown)
@admin_bp.route('/users_by_department', methods=['GET'])
@admin_required
def get_users_by_department():
    """
    Returns a JSON object with users grouped by department code.
    Ensures every department has an entry, even if staff or students are empty.
    Used by frontend to populate instructor dropdown.
    """
    try:
        departments = Department.query.all()
        if not departments:
            logger.warning("No departments found in the database")
            return jsonify({'error': 'No departments available'}), 404

        result = {}
        for dept in departments:
            staff = User.query.filter(
                User.departmentcode == dept.departmentcode,
                User.role.in_(['staff', 'hod'])
            ).all()
            students = User.query.filter(
                User.departmentcode == dept.departmentcode,
                User.role == 'student'
            ).all()
            result[dept.departmentcode] = {
                'staff': [user.to_dict() for user in staff],  # Always a list, even if empty
                'students': [user.to_dict() for user in students]  # Always a list, even if empty
            }
            logger.debug(f"Department {dept.departmentcode}: {len(staff)} staff, {len(students)} students")

        logger.info(f"Successfully fetched users for {len(departments)} departments")
        return jsonify(result), 200
    except Exception as e:
        logger.error(f"Failed to fetch users by department: {str(e)}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

# Add a new user
@admin_bp.route('/add_user', methods=['POST'])
@admin_required
def register_user():
    """
    Adds a new user to the system. Validates all fields and ensures department exists.
    Used to populate staff for instructor dropdown.
    """
    try:
        data = request.get_json()
        if not data:
            logger.warning("No JSON data provided in request")
            return jsonify({'error': 'No JSON data provided'}), 400

        admission_number = data.get('admission_number')
        username = data.get('username')
        email = data.get('email')
        password = data.get('password')
        role = data.get('role')
        departmentcode = data.get('departmentcode')
        batch = data.get('batch') if role == 'student' else None
        semester = data.get('semester') if role == 'student' else None
        phone_number = data.get('phone_number')

        required_fields = {
            'admission_number': admission_number,
            'username': username,
            'email': email,
            'password': password,
            'role': role,
            'departmentcode': departmentcode
        }
        missing_fields = [field for field, value in required_fields.items() if not value]
        if missing_fields:
            logger.warning(f"Missing fields: {', '.join(missing_fields)}")
            return jsonify({'error': f'Missing required fields: {", ".join(missing_fields)}'}), 400

        valid_roles = ['hod', 'staff', 'student']
        if role not in valid_roles:
            logger.warning(f"Invalid role: {role}")
            return jsonify({'error': f'Invalid role. Must be one of: {", ".join(valid_roles)}'}), 400

        if not re.match(r"[^@]+@[^@]+\.[^@]+", email):
            logger.warning(f"Invalid email format: {email}")
            return jsonify({'error': 'Invalid email format'}), 400

        if phone_number and (not phone_number.isdigit() or len(phone_number) < 10):
            logger.warning(f"Invalid phone number: {phone_number}")
            return jsonify({'error': 'Phone number must be at least 10 digits'}), 400

        if role == 'student':
            if not batch:
                logger.warning("Batch missing for student role")
                return jsonify({'error': 'Batch is required for students'}), 400
            valid_semesters = [f'S{i}' for i in range(1, 9)]
            if semester not in valid_semesters:
                logger.warning(f"Invalid semester: {semester}")
                return jsonify({'error': f'Semester must be one of: {", ".join(valid_semesters)}'}), 400

        existing_user = User.query.filter(
            (User.admission_number == admission_number) | (User.email == email)
        ).first()
        if existing_user:
            if existing_user.admission_number == admission_number:
                logger.warning(f"Admission number {admission_number} already exists")
                return jsonify({'error': 'Admission number already exists'}), 409
            if existing_user.email == email:
                logger.warning(f"Email {email} already exists")
                return jsonify({'error': 'Email already exists'}), 409

        if not Department.query.filter_by(departmentcode=departmentcode).first():
            logger.warning(f"Invalid department code: {departmentcode}")
            return jsonify({'error': 'Invalid department code'}), 400

        new_user = User(
            admission_number=admission_number,
            email=email,
            username=username,
            password=bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8'),
            phone_number=phone_number,
            role=role,
            batch=batch,
            semester=semester,
            departmentcode=departmentcode
        )
        db.session.add(new_user)
        db.session.commit()

        logger.info(f"User {admission_number} registered successfully")
        return jsonify({
            'message': 'User registered successfully',
            'user': new_user.to_dict()
        }), 201

    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to register user: {str(e)}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

# Update an existing user
@admin_bp.route('/update_user/<string:admission_number>', methods=['PUT'])
@admin_required
def update_user(admission_number):
    try:
        data = request.json
        username = data.get('username')
        email = data.get('email')
        role = data.get('role')
        departmentcode = data.get('departmentcode')
        phone_number = data.get('phone_number')
        batch = data.get('batch') if role == 'student' else None
        semester = data.get('semester') if role == 'student' else None

        if not all([username, email, role, departmentcode]):
            logger.warning(f"Missing required fields for user {admission_number}")
            return jsonify({'error': 'Missing required fields'}), 400

        if role not in ['hod', 'staff', 'student']:
            logger.warning(f"Invalid role for user {admission_number}: {role}")
            return jsonify({'error': 'Invalid role value'}), 400

        if role == 'student' and semester is not None and semester not in [f'S{i}' for i in range(1, 9)]:
            logger.warning(f"Invalid semester for user {admission_number}: {semester}")
            return jsonify({'error': 'Semester must be between S1 and S8 for students'}), 400

        if not re.match(r"[^@]+@[^@]+\.[^@]+", email):
            logger.warning(f"Invalid email format for user {admission_number}: {email}")
            return jsonify({'error': 'Invalid email format'}), 400

        user = User.query.get(admission_number)
        if not user:
            logger.warning(f"User {admission_number} not found")
            return jsonify({'error': 'User not found'}), 404

        existing_user = User.query.filter(
            (User.email == email) & (User.admission_number != admission_number)
        ).first()
        if existing_user:
            logger.warning(f"Email {email} already exists for another user")
            return jsonify({"error": "Email already exists"}), 409

        if not Department.query.filter_by(departmentcode=departmentcode).first():
            logger.warning(f"Invalid department code for user {admission_number}: {departmentcode}")
            return jsonify({'error': 'Invalid department code'}), 400

        user.username = username
        user.email = email
        user.role = role
        user.departmentcode = departmentcode
        user.phone_number = phone_number
        user.batch = batch
        user.semester = semester
        db.session.commit()

        logger.info(f"User {admission_number} updated successfully")
        return jsonify({
            'message': 'User updated successfully',
            'user': user.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to update user {admission_number}: {str(e)}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

# Delete a user with cleanup of dependent records
@admin_bp.route('/delete_user/<string:admission_number>', methods=['DELETE'])
@admin_required
def delete_user(admission_number):
    try:
        user = User.query.get(admission_number)
        if not user:
            logger.warning(f"User {admission_number} not found for deletion")
            return jsonify({'error': 'User not found'}), 404

        if user.role == 'admin':
            logger.warning(f"Attempt to delete admin user {admission_number}")
            return jsonify({'error': 'Cannot delete admin users'}), 403

        if user.role == 'student':
            assignments = Assignment.query.filter_by(submitted_by=admission_number).all()
            for assignment in assignments:
                file_path = os.path.join(ASSIGNMENTS_FOLDER, assignment.submission_filename)
                if os.path.exists(file_path):
                    os.remove(file_path)
                db.session.delete(assignment)

            requests = Requests.query.filter_by(admission_number=admission_number).all()
            for req in requests:
                file_path = os.path.join(REQUESTS_FOLDER, req.filename)
                if os.path.exists(file_path):
                    os.remove(file_path)
                db.session.delete(req)

        elif user.role in ['staff', 'hod']:
            subjects = Subject.query.filter_by(instructor_id=admission_number).all()
            for subject in subjects:
                subject.instructor_id = None

            assignments = Assignment.query.filter_by(instructor_id=admission_number).all()
            for assignment in assignments:
                file_path = os.path.join(ASSIGNMENTS_FOLDER, assignment.submission_filename)
                if os.path.exists(file_path):
                    os.remove(file_path)
                db.session.delete(assignment)

        user_data = user.to_dict()
        db.session.delete(user)
        db.session.commit()

        logger.info(f"Deleted user {admission_number} and associated records")
        return jsonify({
            'message': 'User deleted successfully',
            'user': user_data
        }), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to delete user {admission_number}: {str(e)}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

# Fetch all subjects
@admin_bp.route('/subjects', methods=['GET'])
@admin_required
def get_all_subjects():
    try:
        subjects = Subject.query.all()
        logger.info(f"Fetched {len(subjects)} subjects")
        return jsonify([subject.to_dict() for subject in subjects]), 200
    except Exception as e:
        logger.error(f"Failed to fetch subjects: {str(e)}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

# Add a new subject
@admin_bp.route('/subjects', methods=['POST'])
@admin_required
def add_subject():
    """
    Adds a new subject with validation. Ensures instructor_id is valid for the department.
    """
    try:
        data = request.get_json()
        semester = data.get('semester')
        subject_code = data.get('subject_code')
        subject_name = data.get('subject_name')
        credits = data.get('credits')
        departmentcode = data.get('departmentcode')
        instructor_id = data.get('instructor_id')

        if not all([semester, subject_code, subject_name, credits, departmentcode]):
            logger.warning("Missing required fields for new subject")
            return jsonify({'error': 'Missing required fields'}), 400

        if semester not in [f'S{i}' for i in range(1, 9)]:
            logger.warning(f"Invalid semester: {semester}")
            return jsonify({'error': 'Invalid semester (must be S1 to S8)'}), 400

        credits = int(credits)
        if credits <= 0:
            logger.warning(f"Invalid credits: {credits}")
            return jsonify({'error': 'Credits must be positive'}), 400

        if Subject.query.filter_by(subject_code=subject_code).first():
            logger.warning(f"Subject code {subject_code} already exists")
            return jsonify({'error': 'Subject code already exists'}), 409

        if not Department.query.filter_by(departmentcode=departmentcode).first():
            logger.warning(f"Invalid department code: {departmentcode}")
            return jsonify({'error': 'Invalid department code'}), 400

        if instructor_id and not User.query.filter(
            User.admission_number == instructor_id,
            User.departmentcode == departmentcode,
            User.role.in_(['staff', 'hod'])
        ).first():
            logger.warning(f"Invalid instructor ID {instructor_id} for department {departmentcode}")
            return jsonify({'error': 'Invalid instructor ID or not in department'}), 400

        new_subject = Subject(
            semester=semester,
            subject_code=subject_code,
            subject_name=subject_name,
            credits=credits,
            departmentcode=departmentcode,
            instructor_id=instructor_id
        )
        db.session.add(new_subject)
        db.session.commit()

        logger.info(f"Subject {subject_code} added successfully")
        return jsonify({'message': 'Subject added successfully', 'subject': new_subject.to_dict()}), 201
    except ValueError:
        logger.warning(f"Invalid credits value: {credits}")
        return jsonify({'error': 'Credits must be a positive integer'}), 400
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to add subject: {str(e)}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

# Update an existing subject
@admin_bp.route('/subjects/<string:subject_code>', methods=['PUT'])
@admin_required
def edit_subject(subject_code):
    """
    Updates a subject with validation. Ensures instructor_id matches department.
    """
    try:
        data = request.get_json()
        subject = Subject.query.filter_by(subject_code=subject_code).first()
        if not subject:
            logger.warning(f"Subject {subject_code} not found")
            return jsonify({'error': 'Subject not found'}), 404

        semester = data.get('semester', subject.semester)
        subject_name = data.get('subject_name', subject.subject_name)
        credits = data.get('credits', subject.credits)
        departmentcode = data.get('departmentcode', subject.departmentcode)
        instructor_id = data.get('instructor_id', subject.instructor_id)

        if not all([semester, subject_name, credits, departmentcode]):
            logger.warning(f"Missing required fields for subject {subject_code}")
            return jsonify({'error': 'Missing required fields'}), 400

        if semester not in [f'S{i}' for i in range(1, 9)]:
            logger.warning(f"Invalid semester for subject {subject_code}: {semester}")
            return jsonify({'error': 'Invalid semester (must be S1 to S8)'}), 400

        credits = int(credits)
        if credits <= 0:
            logger.warning(f"Invalid credits for subject {subject_code}: {credits}")
            return jsonify({'error': 'Credits must be positive'}), 400

        if not Department.query.filter_by(departmentcode=departmentcode).first():
            logger.warning(f"Invalid department code for subject {subject_code}: {departmentcode}")
            return jsonify({'error': 'Invalid department code'}), 400

        if instructor_id and not User.query.filter(
            User.admission_number == instructor_id,
            User.departmentcode == departmentcode,
            User.role.in_(['staff', 'hod'])
        ).first():
            logger.warning(f"Invalid instructor ID {instructor_id} for department {departmentcode}")
            return jsonify({'error': 'Invalid instructor ID or not in department'}), 400

        subject.semester = semester
        subject.subject_name = subject_name
        subject.credits = credits
        subject.departmentcode = departmentcode
        subject.instructor_id = instructor_id
        db.session.commit()

        logger.info(f"Subject {subject_code} updated successfully")
        return jsonify({'message': 'Subject updated successfully', 'subject': subject.to_dict()}), 200
    except ValueError:
        logger.warning(f"Invalid credits value for subject {subject_code}: {credits}")
        return jsonify({'error': 'Credits must be a positive integer'}), 400
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to update subject {subject_code}: {str(e)}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

# Delete a subject
@admin_bp.route('/subjects/<string:subject_code>', methods=['DELETE'])
@admin_required
def delete_subject(subject_code):
    try:
        subject = Subject.query.filter_by(subject_code=subject_code).first()
        if not subject:
            logger.warning(f"Subject {subject_code} not found for deletion")
            return jsonify({'error': 'Subject not found'}), 404

        db.session.delete(subject)
        db.session.commit()
        logger.info(f"Subject {subject_code} deleted successfully")
        return jsonify({'message': 'Subject deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to delete subject {subject_code}: {str(e)}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

# Fetch timetable entries grouped by department
@admin_bp.route('/timetable', methods=['GET'])
@admin_required
def get_timetable():
    try:
        departments = Department.query.all()
        result = {}
        for dept in departments:
            timetable_entries = Timetable.query.filter_by(departmentcode=dept.departmentcode).all()
            result[dept.departmentcode] = [entry.to_dict() for entry in timetable_entries]
        logger.info(f"Fetched timetable for {len(departments)} departments")
        return jsonify(result), 200
    except Exception as e:
        logger.error(f"Failed to fetch timetable: {str(e)}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

# Delete a timetable entry
@admin_bp.route('/timetable/<int:timetable_id>', methods=['DELETE'])
@admin_required
def delete_timetable(timetable_id):
    try:
        timetable = Timetable.query.get_or_404(timetable_id)
        db.session.delete(timetable)
        db.session.commit()
        logger.info(f"Timetable {timetable_id} deleted successfully")
        return jsonify({'message': 'Timetable deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to delete timetable {timetable_id}: {str(e)}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

# Fetch notes grouped by department
@admin_bp.route('/notes', methods=['GET'])
@admin_required
def get_notes():
    try:
        departments = Department.query.all()
        result = {}
        for dept in departments:
            notes = Notes.query.filter_by(departmentcode=dept.departmentcode).all()
            result[dept.departmentcode] = [note.to_dict() for note in notes]
        logger.info(f"Fetched notes for {len(departments)} departments")
        return jsonify(result), 200
    except Exception as e:
        logger.error(f"Failed to fetch notes: {str(e)}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

# Delete a note
@admin_bp.route('/notes/<int:note_id>', methods=['DELETE'])
@admin_required
def delete_note(note_id):
    try:
        note = Notes.query.get_or_404(note_id)
        db.session.delete(note)
        db.session.commit()
        logger.info(f"Note {note_id} deleted successfully")
        return jsonify({'message': 'Note deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to delete note {note_id}: {str(e)}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

# Fetch all departments
@admin_bp.route('/departments', methods=['GET'])
@admin_required
def get_departments():
    """
    Returns all departments for the frontend department dropdown.
    """
    try:
        departments = Department.query.all()
        logger.info(f"Fetched {len(departments)} departments")
        return jsonify([dept.to_dict() for dept in departments]), 200
    except Exception as e:
        logger.error(f"Failed to fetch departments: {str(e)}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

# Create a new department
@admin_bp.route('/departments', methods=['POST'])
@admin_required
def create_department():
    try:
        data = request.get_json()
        departmentcode = data.get('departmentcode')
        departmentname = data.get('departmentname')

        if not departmentcode or not departmentname:
            logger.warning("Missing department code or name in POST request")
            return jsonify({'error': 'Missing department code or name'}), 400

        if Department.query.filter_by(departmentcode=departmentcode).first():
            logger.warning(f"Department code {departmentcode} already exists")
            return jsonify({'error': 'Department code already exists'}), 409

        new_dept = Department(departmentcode=departmentcode, departmentname=departmentname)
        db.session.add(new_dept)
        db.session.commit()

        logger.info(f"Created department: {departmentcode}")
        return jsonify({
            'message': 'Department created successfully',
            'department': new_dept.to_dict()
        }), 201
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to create department: {str(e)}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

# Update an existing department
@admin_bp.route('/departments/<string:departmentcode>', methods=['PUT'])
@admin_required
def update_department(departmentcode):
    try:
        data = request.get_json()
        new_departmentcode = data.get('departmentcode')
        departmentname = data.get('departmentname')

        if not new_departmentcode or not departmentname:
            logger.warning("Missing department code or name in PUT request")
            return jsonify({'error': 'Missing department code or name'}), 400

        dept = Department.query.filter_by(departmentcode=departmentcode).first()
        if not dept:
            logger.warning(f"Department {departmentcode} not found for update")
            return jsonify({'error': 'Department not found'}), 404

        if new_departmentcode != departmentcode and Department.query.filter_by(departmentcode=new_departmentcode).first():
            logger.warning(f"New department code {new_departmentcode} already exists")
            return jsonify({'error': 'New department code already exists'}), 409

        dept.departmentcode = new_departmentcode
        dept.departmentname = departmentname
        db.session.commit()

        logger.info(f"Updated department from {departmentcode} to {new_departmentcode}")
        return jsonify({
            'message': 'Department updated successfully',
            'department': dept.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to update department {departmentcode}: {str(e)}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

# Delete a department
@admin_bp.route('/departments/<string:departmentcode>', methods=['DELETE'])
@admin_required
def delete_department(departmentcode):
    try:
        dept = Department.query.filter_by(departmentcode=departmentcode).first()
        if not dept:
            logger.warning(f"Department {departmentcode} not found for deletion")
            return jsonify({'error': 'Department not found'}), 404

        dept_data = dept.to_dict()
        db.session.delete(dept)
        db.session.commit()

        logger.info(f"Deleted department: {departmentcode}")
        return jsonify({
            'message': 'Department deleted successfully',
            'department': dept_data
        }), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to delete department {departmentcode}: {str(e)}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500