from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt
from database import db
from models import User, Subject
from functools import wraps
import bcrypt
import re

admin = Blueprint('admin', __name__)

def admin_required(fn):
    @jwt_required()
    @wraps(fn)
    def wrapper(*args, **kwargs):
        claims = get_jwt()
        if claims.get('role') != 'admin':
            return jsonify({'error': 'Admin access required'}), 403
        return fn(*args, **kwargs)
    return wrapper

# User Management Endpoints (unchanged)
@admin.route('/users', methods=['GET'])
@admin_required
def get_users():
    try:
        users = User.query.all()
        return jsonify([user.to_dict() for user in users]), 200
    except Exception as e:
        return jsonify({'error': 'Failed to fetch users', 'details': str(e)}), 500

@admin.route('/add_user', methods=['POST'])
@admin_required
def register_user():
    try:
        data = request.json
        admission_number = data.get('admission_number')
        username = data.get('username')
        email = data.get('email')
        password = data.get('password')
        role = data.get('role')
        departmentcode = data.get('departmentcode')
        batch = data.get('batch') if role == 'student' else None
        phone_number = data.get('phone_number')

        if not all([admission_number, username, email, password, role, departmentcode]):
            return jsonify({'error': 'Missing required fields'}), 400

        if role not in ['admin', 'hod', 'staff', 'student']:
            return jsonify({'error': 'Invalid role value'}), 400

        if not re.match(r"[^@]+@[^@]+\.[^@]+", email):
            return jsonify({'error': 'Invalid email format'}), 400

        existing_user = User.query.filter(
            (User.admission_number == admission_number) | (User.email == email)
        ).first()
        if existing_user:
            if existing_user.admission_number == admission_number:
                return jsonify({"error": "Admission number already exists"}), 409
            if existing_user.email == email:
                return jsonify({"error": "Email already exists"}), 409

        hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

        new_user = User(
            admission_number=admission_number,
            email=email,
            username=username,
            password=hashed_password,
            phone_number=phone_number,
            role=role,
            batch=batch,
            departmentcode=departmentcode
        )
        db.session.add(new_user)
        db.session.commit()

        return jsonify({
            'message': 'User registered successfully',
            'user': new_user.to_dict()
        }), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to register user', 'details': str(e)}), 500

@admin.route('/update_user/<string:admission_number>', methods=['PUT'])
@admin_required
def update_user(admission_number):
    try:
        data = request.json
        username = data.get('username')
        email = data.get('email')
        role = data.get('role')
        batch = data.get('batch') if data.get('role') == 'student' else None
        departmentcode = data.get('departmentcode')
        phone_number = data.get('phone_number')

        if not all([username, email, role, departmentcode]):
            return jsonify({'error': 'Missing required fields'}), 400

        if role not in ['admin', 'hod', 'staff', 'student']:
            return jsonify({'error': 'Invalid role value'}), 400

        if not re.match(r"[^@]+@[^@]+\.[^@]+", email):
            return jsonify({'error': 'Invalid email format'}), 400

        user = User.query.get(admission_number)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        existing_user = User.query.filter(
            (User.email == email) & (User.admission_number != admission_number)
        ).first()
        if existing_user:
            return jsonify({"error": "Email already exists"}), 409

        user.username = username
        user.email = email
        user.role = role
        user.batch = batch
        user.departmentcode = departmentcode
        user.phone_number = phone_number
        db.session.commit()

        return jsonify({
            'message': 'User updated successfully',
            'user': user.to_dict()
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to update user', 'details': str(e)}), 500

@admin.route('/delete_user/<string:admission_number>', methods=['DELETE'])
@admin_required
def delete_user(admission_number):
    try:
        user = User.query.get(admission_number)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        if user.role == 'admin':
            return jsonify({'error': 'Cannot delete admin users'}), 403

        db.session.delete(user)
        db.session.commit()
        return jsonify({'message': 'User deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to delete user', 'details': str(e)}), 500

# Subject Management Endpoints
@admin.route('/subjects', methods=['GET'])
@admin_required
def get_all_subjects():
    """Fetch all subjects across all departments."""
    try:
        subjects = Subject.query.all()
        return jsonify([subject.to_dict() for subject in subjects]), 200
    except Exception as e:
        return jsonify({'error': 'Failed to fetch subjects', 'details': str(e)}), 500

@admin.route('/subjects', methods=['POST'])
@admin_required
def add_subject():
    """Add a new subject."""
    try:
        data = request.get_json()
        semester = data.get('semester')
        subject_code = data.get('subject_code')
        subject_name = data.get('subject_name')
        credits = data.get('credits')
        departmentcode = data.get('departmentcode')

        if not all([semester, subject_code, subject_name, credits, departmentcode]):
            return jsonify({'error': 'Missing required fields'}), 400

        if semester not in [f'S{i}' for i in range(1, 9)]:
            return jsonify({'error': 'Invalid semester (must be S1 to S8)'}), 400

        credits = int(credits)
        if credits <= 0:
            return jsonify({'error': 'Credits must be positive'}), 400

        if Subject.query.filter_by(subject_code=subject_code).first():
            return jsonify({'error': 'Subject code already exists'}), 409

        new_subject = Subject(
            subject_code=subject_code,
            semester=semester,
            subject_name=subject_name,
            credits=credits,
            departmentcode=departmentcode
        )
        db.session.add(new_subject)
        db.session.commit()

        return jsonify({'message': 'Subject added successfully', 'subject': new_subject.to_dict()}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to add subject', 'details': str(e)}), 500

@admin.route('/subjects/<string:subject_code>', methods=['PUT'])
@admin_required
def edit_subject(subject_code):
    """Edit an existing subject."""
    try:
        data = request.get_json()
        subject = Subject.query.get_or_404(subject_code)

        subject.semester = data.get('semester', subject.semester)
        subject.subject_name = data.get('subject_name', subject.subject_name)
        subject.credits = data.get('credits', subject.credits)
        subject.departmentcode = data.get('departmentcode', subject.departmentcode)

        db.session.commit()
        return jsonify({'message': 'Subject updated successfully', 'subject': subject.to_dict()}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to update subject', 'details': str(e)}), 500

@admin.route('/subjects/<string:subject_code>', methods=['DELETE'])
@admin_required
def delete_subject(subject_code):
    """Delete a subject."""
    try:
        subject = Subject.query.get_or_404(subject_code)
        db.session.delete(subject)
        db.session.commit()
        return jsonify({'message': 'Subject deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to delete subject', 'details': str(e)}), 500