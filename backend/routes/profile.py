from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, User  # Adjust import based on your project structure
from http import HTTPStatus

profile_bp = Blueprint('profile', __name__, url_prefix='/api/users')

@profile_bp.route('/update_profile', methods=['PUT'])
@jwt_required()
def update_profile():
    """
    Update user profile (username and phone_number) in the database.
    Expects JSON payload with 'admission_number', 'username', and 'phone_number'.
    """
    current_user_id = get_jwt_identity()  # Get the admission_number from JWT
    data = request.get_json()

    if not data or 'admission_number' not in data:
        return jsonify({"error": "Admission number is required"}), HTTPStatus.BAD_REQUEST

    # Verify the admission_number matches the authenticated user
    if data['admission_number'] != current_user_id:
        return jsonify({"error": "Unauthorized to update this profile"}), HTTPStatus.FORBIDDEN

    # Fetch the user from the database
    user = User.query.filter_by(admission_number=data['admission_number']).first()
    if not user:
        return jsonify({"error": "User not found"}), HTTPStatus.NOT_FOUND

    # Update fields if provided in the request
    if 'username' in data:
        user.username = data['username']
    if 'phone_number' in data:
        user.phone_number = data['phone_number']

    try:
        db.session.commit()
        return jsonify({
            "message": "Profile updated successfully",
            "user": {
                "admission_number": user.admission_number,
                "username": user.username,
                "phone_number": user.phone_number,
                "email": user.email,
                "role": user.role
            }
        }), HTTPStatus.OK
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Failed to update profile: {str(e)}"}), HTTPStatus.INTERNAL_SERVER_ERROR
