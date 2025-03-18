import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from flask_jwt_extended import JWTManager, create_access_token, create_refresh_token, jwt_required, get_jwt_identity
from config import Config
from database import db , migrate
from routes.auth import auth_bp
from routes.admin import admin
from routes.profile import profile_bp
from routes.departments import departments_bp
from routes.staff_hod import staff_hod_bp
from routes.chatbot import chatbot_bp
import logging

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # Load environment variables for flexibility
    app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'your-secret-key')  # Set in .env
    app.config['JWT_ACCESS_TOKEN_EXPIRES'] = int(os.getenv('JWT_ACCESS_TOKEN_EXPIRES', 3600))  # 1 hour
    app.config['JWT_REFRESH_TOKEN_EXPIRES'] = int(os.getenv('JWT_REFRESH_TOKEN_EXPIRES', 2592000))  # 30 days

    # Configure CORS with specific origins
    CORS(app, resources={r"/api/*": {"origins": os.getenv('FRONTEND_URL', 'http://localhost:5001')}})

    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)  # Initialize Migrate with app and db
    jwt = JWTManager(app)
    # Set up logging
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)

    # Create database tables
    with app.app_context():
        try:
            db.create_all()
            logger.info("Database tables created successfully.")
        except Exception as e:
            logger.error(f"Error creating database tables: {str(e)}")

    # Register blueprints
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(admin, url_prefix='/api/admin')
    app.register_blueprint(departments_bp, url_prefix='/api/departments')
    app.register_blueprint(chatbot_bp, url_prefix='/api/chatbot')
    app.register_blueprint(staff_hod_bp, url_prefix='/api')
    app.register_blueprint(profile_bp, url_prefix='/api/users')

    # Login endpoint (placeholder, replace with real authentication)
    @app.route('/api/auth/login', methods=['POST'])
    def login():
        try:
            data = request.get_json()
            user_id = data.get('user_id')
            password = data.get('password')  # Add password field

            if not user_id or not password:
                return jsonify({"error": "Missing user_id or password"}), 400

            # Placeholder: Replace with real user validation (e.g., check against db)
            # Example: user = User.query.filter_by(user_id=user_id).first()
            # if not user or not user.check_password(password):
            #     return jsonify({"error": "Invalid credentials"}), 401

            access_token = create_access_token(identity=user_id)
            refresh_token = create_refresh_token(identity=user_id)
            logger.info(f"User {user_id} logged in successfully.")
            return jsonify({
                "access_token": access_token,
                "refresh_token": refresh_token
            }), 200
        except Exception as e:
            logger.error(f"Login error: {str(e)}")
            return jsonify({"error": "Internal server error"}), 500

    # Refresh endpoint
    @app.route('/api/auth/refresh', methods=['POST'])
    @jwt_required(refresh=True)
    def refresh():
        try:
            current_user = get_jwt_identity()
            new_access_token = create_access_token(identity=current_user)
            logger.info(f"Token refreshed for user {current_user}.")
            return jsonify({"access_token": new_access_token}), 200
        except Exception as e:
            logger.error(f"Refresh error: {str(e)}")
            return jsonify({"error": "Invalid refresh token"}), 401

    # Token revocation check (placeholder for blacklist)
    @jwt.token_in_blocklist_loader
    def check_if_token_revoked(jwt_header, jwt_payload):
        jti = jwt_payload['jti']
        # Example: Check against a blacklist (e.g., Redis or DB)
        # blacklist = redis_client.get(jti)
        # return blacklist is not None
        return False  # No revocation implemented yet

    # Global error handler for uncaught exceptions
    @app.errorhandler(Exception)
    def handle_exception(e):
        logger.error(f"Unhandled exception: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500

    return app

if __name__ == '__main__':
    app = create_app()
    port = int(os.getenv('PORT', 5001))  # Default to 5001
    host = os.getenv('HOST', '0.0.0.0')  # Default to 0.0.0.0
    app.run(debug=os.getenv('FLASK_DEBUG', 'True') == 'True', host=host, port=port)