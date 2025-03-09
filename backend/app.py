from flask import Flask
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from routes.auth import auth_bp
from routes.departments import departments_bp  # New import
from database import db, migrate
from config.config import Config
from models import User, Department
from chatbot_api import chatbot_bp
from routes.admin import admin
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
CORS(app)

app.config.from_object(Config)

db.init_app(app)
migrate.init_app(app, db)

jwt = JWTManager(app)

app.register_blueprint(auth_bp, url_prefix='/api/auth')
app.register_blueprint(chatbot_bp, url_prefix='/api')
app.register_blueprint(admin, url_prefix='/api/admin')  # Prefix for admin routes
app.register_blueprint(departments_bp, url_prefix='/api/admin')  # New blueprint

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)