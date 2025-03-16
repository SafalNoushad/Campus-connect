from flask import Blueprint, jsonify, request
from database import db
from models import Department
from flask_jwt_extended import jwt_required

departments_bp = Blueprint('departments', __name__)

@departments_bp.route('/departments', methods=['GET'])
@jwt_required()
def get_departments():
    try:
        departments = Department.query.all()
        return jsonify([dept.to_dict() for dept in departments]), 200
    except Exception as e:
        return jsonify({"error": "Failed to fetch departments", "details": str(e)}), 500

@departments_bp.route('/departments', methods=['POST'])
@jwt_required()
def create_department():
    try:
        data = request.json
        departmentcode = data.get('departmentcode')
        departmentname = data.get('departmentname')

        if not departmentcode or not departmentname:
            return jsonify({"error": "Missing department code or name"}), 400

        new_dept = Department(departmentcode=departmentcode, departmentname=departmentname)
        db.session.add(new_dept)
        db.session.commit()
        return jsonify({"message": "Department created", "department": new_dept.to_dict()}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": "Failed to create department", "details": str(e)}), 500