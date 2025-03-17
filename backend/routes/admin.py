from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt
from database import db
from models import User
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
        email = data.get('email')  # Accept email from request instead of generating
        password = data.get('password')  # Accept password from request
        role = data.get('role')
        departmentcode = data.get('departmentcode')
        batch = data.get('batch') if role == 'student' else None
        phone_number = data.get('phone_number')

        # Validate required fields
        if not all([admission_number, username, email, password, role, departmentcode]):
            return jsonify({'error': 'Missing required fields'}), 400

        # Validate role
        if role not in ['admin', 'hod', 'staff', 'student']:
            return jsonify({'error': 'Invalid role value'}), 400

        # Basic email validation
        if not re.match(r"[^@]+@[^@]+\.[^@]+", email):
            return jsonify({'error': 'Invalid email format'}), 400

        # Check for existing user
        existing_user = User.query.filter(
            (User.admission_number == admission_number) | (User.email == email)
        ).first()
        if existing_user:
            if existing_user.admission_number == admission_number:
                return jsonify({"error": "Admission number already exists"}), 409
            if existing_user.email == email:
                return jsonify({"error": "Email already exists"}), 409

        # Hash the provided password
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
        phone_number = data.get('phone_number')  # Added phone_number

        # Validate required fields
        if not all([username, email, role, departmentcode]):
            return jsonify({'error': 'Missing required fields'}), 400

        # Validate role
        if role not in ['admin', 'hod', 'staff', 'student']:
            return jsonify({'error': 'Invalid role value'}), 400

        # Basic email validation
        if not re.match(r"[^@]+@[^@]+\.[^@]+", email):
            return jsonify({'error': 'Invalid email format'}), 400

        user = User.query.get(admission_number)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Check for email conflict with other users
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
        user.phone_number = phone_number  # Update phone_number
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