import os
from flask import Flask, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from config import Config
from database import db, migrate
import logging

# File upload folder configuration
UPLOAD_FOLDER = os.path.join(os.path.dirname(__file__), 'uploads')
TIMETABLE_FOLDER = os.path.join(UPLOAD_FOLDER, 'timetable')
NOTES_FOLDER = os.path.join(UPLOAD_FOLDER, 'notes')

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # Load environment variables with defaults
    app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'your-secret-key')
    app.config['JWT_ACCESS_TOKEN_EXPIRES'] = int(os.getenv('JWT_ACCESS_TOKEN_EXPIRES', 3600))  # 1 hour
    app.config['JWT_REFRESH_TOKEN_EXPIRES'] = int(os.getenv('JWT_REFRESH_TOKEN_EXPIRES', 2592000))  # 30 days
    app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

    # Ensure upload directories exist
    for folder in [UPLOAD_FOLDER, TIMETABLE_FOLDER, NOTES_FOLDER]:
        os.makedirs(folder, exist_ok=True)

    # Configure CORS
    frontend_url = os.getenv('FRONTEND_URL', 'http://localhost:5001')
    CORS(app, resources={
        r"/api/*": {"origins": frontend_url},
        r"/uploads/*": {"origins": frontend_url}
    })

    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)
    jwt = JWTManager(app)

    # Logging setup
    logging.basicConfig(level=logging.DEBUG)
    logger = logging.getLogger(__name__)

    # Create database tables and verify models
    with app.app_context():
        try:
            db.create_all()
            logger.info("Database tables created successfully.")
            from models import User
            logger.debug(f"User model imported: {User}")
        except Exception as e:
            logger.error(f"Error creating database tables: {str(e)}", exc_info=True)
            raise

    # Register blueprints (preserving all originals)
    try:
        from routes.auth import auth_bp
        from routes.admin import admin_bp
        from routes.students import students_bp
        from routes.staff import staff_bp
        from routes.hod import hod_bp
        from routes.profile import profile_bp
        from routes.chatbot import chatbot_bp
        from routes.announcement import announcement_bp  # Already present
        from routes.department_announcement import department_announcement_bp  # New import

        app.register_blueprint(auth_bp, url_prefix='/api/auth')
        app.register_blueprint(admin_bp, url_prefix='/api/admin')
        app.register_blueprint(students_bp, url_prefix='/api/students')
        app.register_blueprint(staff_bp, url_prefix='/api/staff')
        app.register_blueprint(hod_bp, url_prefix='/api/hod')
        app.register_blueprint(profile_bp, url_prefix='/api/users')
        app.register_blueprint(chatbot_bp, url_prefix='/api/chatbot')
        app.register_blueprint(announcement_bp, url_prefix='/api/announcements')
        app.register_blueprint(department_announcement_bp, url_prefix='/api/department_announcements')  # New blueprint

        logger.info("All blueprints registered successfully.")
    except ImportError as e:
        logger.error(f"Failed to import blueprints: {str(e)}")
        raise

    # Token revocation check (placeholder)
    @jwt.token_in_blocklist_loader
    def check_if_token_revoked(jwt_header, jwt_payload):
        jti = jwt_payload['jti']
        return False  # Implement blacklist if needed (e.g., Redis)

    # Global error handler
    @app.errorhandler(Exception)
    def handle_exception(e):
        logger.error(f"Unhandled exception: {str(e)}", exc_info=True)
        return jsonify({"error": "Internal server error", "details": str(e)}), 500

    return app

if __name__ == '__main__':
    app = create_app()
    port = int(os.getenv('PORT', 5001))
    host = os.getenv('HOST', '0.0.0.0')
    debug = os.getenv('FLASK_DEBUG', 'True') == 'True'
    app.run(debug=debug, host=host, port=port)