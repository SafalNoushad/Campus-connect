from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt
from database import db
from models import User
from functools import wraps

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

        # Only return students (exclude admin, hod, staff)
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

        # Only return students (exclude admin, hod, staff)
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

        # Only return staff (exclude admin, hod, student)
        staff = User.query.filter_by(departmentcode=department_code).filter(User.role == 'staff').all()
        return jsonify([staff_member.to_dict() for staff_member in staff]), 200
    except Exception as e:
        return jsonify({'error': 'Failed to fetch department staff', 'details': str(e)}), 500