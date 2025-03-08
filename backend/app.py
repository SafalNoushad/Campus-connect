from flask import Flask
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from routes.auth import auth_bp
from database import db, migrate
from flask_migrate import Migrate #type:ignore
from config.config import Config
from models import db, User  # ✅ Import User model here

import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Load configurations
app.config.from_object(Config)

# Initialize database and migration
db.init_app(app)
migrate.init_app(app, db)

# Initialize JWT
jwt = JWTManager(app)

# Register Blueprints
app.register_blueprint(auth_bp, url_prefix='/api/auth')

# ✅ Ensure models are recognized before running migrations
with app.app_context():
    db.create_all()  # 🚀 Manually create tables if migration fails

# Run the application
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)
