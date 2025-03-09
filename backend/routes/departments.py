from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt
from database import db
from models import Department
from functools import wraps

departments_bp = Blueprint('departments', __name__)

def admin_required(fn):
    @jwt_required()
    @wraps(fn)
    def wrapper(*args, **kwargs):
        claims = get_jwt()
        if claims.get('role') != 'admin':
            return jsonify({'error': 'Admin access required'}), 403
        return fn(*args, **kwargs)
    return wrapper

@departments_bp.route('/departments', methods=['GET'])
@admin_required
def get_departments():
    try:
        departments = Department.query.all()
        return jsonify([dept.to_dict() for dept in departments]), 200
    except Exception as e:
        return jsonify({'error': 'Failed to fetch departments', 'details': str(e)}), 500

@departments_bp.route('/departments', methods=['POST'])
@admin_required
def create_department():
    try:
        data = request.json
        code = data.get('departmentcode')
        name = data.get('departmentname')

        if not code or not name:
            return jsonify({'error': 'Missing fields: departmentcode and departmentname are required'}), 400

        existing_dept = Department.query.filter_by(departmentcode=code).first()
        if existing_dept:
            return jsonify({'error': 'Department code already exists'}), 409

        new_dept = Department(departmentcode=code, departmentname=name)
        db.session.add(new_dept)
        db.session.commit()

        return jsonify({'message': 'Department created successfully', 'department': new_dept.to_dict()}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to create department', 'details': str(e)}), 500

@departments_bp.route('/departments/<int:id>', methods=['PUT'])
@admin_required
def update_department(id):
    try:
        data = request.json
        code = data.get('departmentcode')
        name = data.get('departmentname')

        if not code or not name:
            return jsonify({'error': 'Missing fields: departmentcode and departmentname are required'}), 400

        dept = Department.query.get(id)
        if not dept:
            return jsonify({'error': 'Department not found'}), 404

        # Check if the new code is taken by another department
        existing_dept = Department.query.filter_by(departmentcode=code).first()
        if existing_dept and existing_dept.id != id:
            return jsonify({'error': 'Department code already exists'}), 409

        dept.departmentcode = code
        dept.departmentname = name
        db.session.commit()

        return jsonify({'message': 'Department updated successfully', 'department': dept.to_dict()}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to update department', 'details': str(e)}), 500

@departments_bp.route('/departments/<int:id>', methods=['DELETE'])
@admin_required
def delete_department(id):
    try:
        dept = Department.query.get(id)
        if not dept:
            return jsonify({'error': 'Department not found'}), 404

        db.session.delete(dept)
        db.session.commit()
        return jsonify({'message': 'Department deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to delete department', 'details': str(e)}), 500