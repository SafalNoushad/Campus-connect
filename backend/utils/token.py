from flask_jwt_extended import get_jwt, jwt_required
from functools import wraps
from flask import jsonify

def role_required(*allowed_roles):
    def decorator(fn):
        @jwt_required()
        @wraps(fn)
        def wrapper(*args, **kwargs):
            claims = get_jwt()
            user_role = claims.get('role')
            if user_role not in allowed_roles:
                return jsonify({'error': f'Access restricted to {allowed_roles}'}), 403
            return fn(*args, **kwargs)
        return wrapper
    return decorator