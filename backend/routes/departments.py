from flask import Blueprint, jsonify, request
from database import db
from models import Department
from flask_jwt_extended import jwt_required, get_jwt
from routes.admin import admin_required  # Import from admin.py
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

departments_bp = Blueprint('departments', __name__)

@departments_bp.route('/departments', methods=['GET'])
@admin_required  # Restrict to admins
def get_departments():
    try:
        departments = Department.query.all()
        logger.info(f"Fetched {len(departments)} departments")
        return jsonify([dept.to_dict() for dept in departments]), 200
    except Exception as e:
        logger.error(f"Failed to fetch departments: {str(e)}")
        return jsonify({"error": "Failed to fetch departments", "details": str(e)}), 500

@departments_bp.route('/departments', methods=['POST'])
@admin_required  # Restrict to admins
def create_department():
    try:
        data = request.get_json()
        departmentcode = data.get('departmentcode')
        departmentname = data.get('departmentname')

        if not departmentcode or not departmentname:
            logger.warning("Missing department code or name in POST request")
            return jsonify({"error": "Missing department code or name"}), 400

        # Check if departmentcode already exists
        if Department.query.filter_by(departmentcode=departmentcode).first():
            logger.warning(f"Department code {departmentcode} already exists")
            return jsonify({"error": "Department code already exists"}), 409

        new_dept = Department(departmentcode=departmentcode, departmentname=departmentname)
        db.session.add(new_dept)
        db.session.commit()
        logger.info(f"Created department: {departmentcode}")
        return jsonify({"message": "Department created", "department": new_dept.to_dict()}), 201
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to create department: {str(e)}")
        return jsonify({"error": "Failed to create department", "details": str(e)}), 500

@departments_bp.route('/departments/<string:departmentcode>', methods=['PUT'])
@admin_required  # Restrict to admins
def update_department(departmentcode):
    try:
        data = request.get_json()
        new_departmentcode = data.get('departmentcode')
        departmentname = data.get('departmentname')

        if not new_departmentcode or not departmentname:
            logger.warning("Missing department code or name in PUT request")
            return jsonify({"error": "Missing department code or name"}), 400

        dept = Department.query.filter_by(departmentcode=departmentcode).first()
        if not dept:
            logger.warning(f"Department {departmentcode} not found for update")
            return jsonify({"error": "Department not found"}), 404

        # Check if new_departmentcode is taken by another department
        if new_departmentcode != departmentcode and Department.query.filter_by(departmentcode=new_departmentcode).first():
            logger.warning(f"New department code {new_departmentcode} already exists")
            return jsonify({"error": "New department code already exists"}), 409

        dept.departmentcode = new_departmentcode
        dept.departmentname = departmentname
        db.session.commit()
        logger.info(f"Updated department from {departmentcode} to {new_departmentcode}")
        return jsonify({"message": "Department updated", "department": dept.to_dict()}), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to update department {departmentcode}: {str(e)}")
        return jsonify({"error": "Failed to update department", "details": str(e)}), 500

@departments_bp.route('/departments/<string:departmentcode>', methods=['DELETE'])
@admin_required  # Restrict to admins
def delete_department(departmentcode):
    try:
        dept = Department.query.filter_by(departmentcode=departmentcode).first()
        if not dept:
            logger.warning(f"Department {departmentcode} not found for deletion")
            return jsonify({"error": "Department not found"}), 404

        dept_data = dept.to_dict()  # Capture data before deletion
        db.session.delete(dept)
        db.session.commit()
        logger.info(f"Deleted department: {departmentcode}")
        return jsonify({"message": "Department deleted", "department": dept_data}), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Failed to delete department {departmentcode}: {str(e)}")
        return jsonify({"error": "Failed to delete department", "details": str(e)}), 500