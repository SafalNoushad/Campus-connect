from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt
from database import db
from models import User, Subject
from functools import wraps
import datetime

staff_hod_bp = Blueprint('staff_hod', __name__)

def staff_required(fn):
    @jwt_required()
    @wraps(fn)
    def wrapper(*args, **kwargs):
        claims = get_jwt()
        if claims.get('role') != 'staff':
            return jsonify({'error': 'Staff access required'}), 403
        return fn(*args, **kwargs)
    return wrapper

def hod_required(fn):
    @jwt_required()
    @wraps(fn)
    def wrapper(*args, **kwargs):
        claims = get_jwt()
        if claims.get('role') != 'hod':
            return jsonify({'error': 'HOD access required'}), 403
        return fn(*args, **kwargs)
    return wrapper

@staff_hod_bp.route('/staff/department/users', methods=['GET'])
@staff_required
def get_staff_department_users():
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')
        if not department_code:
            return jsonify({'error': 'Department code not found in token'}), 400
        users = User.query.filter_by(departmentcode=department_code).filter(User.role == 'student').all()
        return jsonify([user.to_dict() for user in users]), 200
    except Exception as e:
        return jsonify({'error': 'Failed to fetch department students', 'details': str(e)}), 500

@staff_hod_bp.route('/hod/department/users', methods=['GET'])
@hod_required
def get_hod_department_users():
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')
        if not department_code:
            return jsonify({'error': 'Department code not found in token'}), 400
        users = User.query.filter_by(departmentcode=department_code).filter(User.role == 'student').all()
        return jsonify([user.to_dict() for user in users]), 200
    except Exception as e:
        return jsonify({'error': 'Failed to fetch department students', 'details': str(e)}), 500

@staff_hod_bp.route('/hod/department/staff', methods=['GET'])
@hod_required
def get_hod_department_staff():
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')
        if not department_code:
            return jsonify({'error': 'Department code not found in token'}), 400
        staff = User.query.filter_by(departmentcode=department_code).filter(User.role == 'staff').all()
        return jsonify([staff_member.to_dict() for staff_member in staff]), 200
    except Exception as e:
        return jsonify({'error': 'Failed to fetch department staff', 'details': str(e)}), 500

@staff_hod_bp.route('/hod/subjects', methods=['GET'])
@hod_required
def get_hod_subjects():
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')
        if not department_code:
            return jsonify({'error': 'Department code not found in token'}), 400
        subjects = Subject.query.filter_by(departmentcode=department_code).all()
        return jsonify([subject.to_dict() for subject in subjects]), 200
    except Exception as e:
        return jsonify({'error': 'Failed to fetch subjects', 'details': str(e)}), 500

@staff_hod_bp.route('/hod/subjects', methods=['POST'])
@hod_required
def add_hod_subject():
    try:
        data = request.get_json()
        semester = data.get('semester')
        subject_code = data.get('subject_code')
        subject_name = data.get('subject_name')
        credits = data.get('credits')
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')

        if not all([semester, subject_code, subject_name, credits, department_code]):
            return jsonify({'error': 'Missing required fields'}), 400

        if semester not in [f'S{i}' for i in range(1, 9)]:
            return jsonify({'error': 'Invalid semester (must be S1 to S8)'}), 400

        credits = int(credits)
        if credits <= 0:
            return jsonify({'error': 'Credits must be positive'}), 400

        if Subject.query.filter_by(subject_code=subject_code).first():
            return jsonify({'error': 'Subject code already exists'}), 409

        new_subject = Subject(
            semester=semester,
            subject_code=subject_code,
            subject_name=subject_name,
            credits=credits,
            departmentcode=department_code
        )
        db.session.add(new_subject)
        db.session.commit()
        return jsonify({'message': 'Subject added successfully', 'subject': new_subject.to_dict()}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to add subject', 'details': str(e)}), 500
@staff_hod_bp.route('/staff/subjects', methods=['GET'])
@staff_required
def get_staff_subjects():
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')
        if not department_code:
            return jsonify({'error': 'Department code not found in token'}), 400
        subjects = Subject.query.filter_by(departmentcode=department_code).all()
        return jsonify([subject.to_dict() for subject in subjects]), 200
    except Exception as e:
        return jsonify({'error': 'Failed to fetch subjects', 'details': str(e)}), 500


@staff_hod_bp.route('/student/subjects', methods=['GET'])
@jwt_required()
def get_student_subjects():
    try:
        current_user = get_jwt()
        department_code = current_user.get('departmentcode')
        batch = current_user.get('batch')
        if not department_code or not batch:
            return jsonify({'error': 'Department code or batch not found in token'}), 400
        if current_user.get('role') != 'student':
            return jsonify({'error': 'Student access required'}), 403
        
        # Parse batch and calculate semester
        current_date = datetime.now()
        current_year = current_date.year
        batch_start = int(batch.split('-')[0])
        years_elapsed = current_year - batch_start  # Full years since start (0-based)
        is_second_half = current_date.month >= 7  # Jul-Dec is second semester
        
        # Correct semester calculation: 2 semesters per year
        semesters_completed = years_elapsed * 2  # Semesters from full years
        current_semester = semesters_completed + (2 if is_second_half else 1)
        semester_number = min(current_semester, 8)  # Cap at S8
        semester = f'S{semester_number}'
        
        # Debug logging
        print(f"Batch: {batch}, Current Date: {current_date}, Years Elapsed: {years_elapsed}, "
              f"Is Second Half: {is_second_half}, Semesters Completed: {semesters_completed}, "
              f"Current Semester: {current_semester}, Calculated Semester: {semester}")
        
        # Fetch subjects
        subjects = Subject.query.filter_by(departmentcode=department_code, semester=semester).all()
        response = [subject.to_dict() for subject in subjects]
        print(f"Subjects fetched for {department_code}, {semester}: {response}")
        
        # Return semester even if no subjects exist
        return jsonify({
            'semester': semester,
            'subjects': response
        }), 200
    except Exception as e:
        print(f"Error: {str(e)}")
        return jsonify({'error': 'Failed to fetch subjects', 'details': str(e)}), 500