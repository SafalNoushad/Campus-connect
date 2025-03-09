from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt
from database import db
from models import User
from functools import wraps

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
    """
    Fetch all users from the database.
    Returns a JSON list of user dictionaries.
    """
    try:
        users = User.query.all()
        return jsonify([user.to_dict() for user in users]), 200
    except Exception as e:
        return jsonify({'error': 'Failed to fetch users', 'details': str(e)}), 500

@admin.route('/update_user/<string:admission_number>', methods=['PUT'])
@admin_required
def update_user(admission_number):
    """
    Update a user's details based on admission_number.
    Expects JSON body with 'username', 'email', and 'role'.
    """
    try:
        data = request.json
        username = data.get('username')
        email = data.get('email')
        role = data.get('role')

        if not username or not email or not role:
            return jsonify({'error': 'Missing fields: username, email, and role are required'}), 400

        if role not in ['admin', 'teacher', 'student']:
            return jsonify({'error': 'Invalid role value'}), 400

        user = User.query.get(admission_number)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Prevent changing admin role manually via this endpoint (optional security measure)
        if user.role == 'admin' and role != 'admin':
            return jsonify({'error': 'Cannot change admin role via this endpoint'}), 403

        user.username = username
        user.email = email
        user.role = role
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
    """
    Delete a user based on admission_number.
    """
    try:
        user = User.query.get(admission_number)
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Prevent deleting admin users (optional security measure)
        if user.role == 'admin':
            return jsonify({'error': 'Cannot delete admin users'}), 403

        db.session.delete(user)
        db.session.commit()
        return jsonify({'message': 'User deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Failed to delete user', 'details': str(e)}), 500