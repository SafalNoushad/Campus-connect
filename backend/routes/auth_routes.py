from flask import Flask, Blueprint, request, jsonify
from flask_jwt_extended import create_access_token
import mysql.connector
import os
from dotenv import load_dotenv
import bcrypt
from flask_cors import CORS

load_dotenv()

app = Flask(__name__)
CORS(app)  # Enabling CORS for all routes (for cross-origin requests)

auth_bp = Blueprint('auth', __name__)

def get_db_connection():
    try:
        db = mysql.connector.connect(
            host=os.getenv("MYSQL_HOST"),
            user=os.getenv("MYSQL_USER"),
            password=os.getenv("MYSQL_PASSWORD"),
            database=os.getenv("MYSQL_DB")
        )
        return db
    except mysql.connector.Error as err:
        print(f"Database Connection Error: {err}")
        raise

@auth_bp.route('/signup', methods=['POST'])
def signup():
    """Handles manual signup and stores user details in the database."""
    try:
        data = request.json
        admission_number = data.get("admission_number")
        email = data.get("email")
        username = data.get("username")
        password = data.get("password")
        phone_number = data.get("phone_number")

        if not all([admission_number, email, username, password, phone_number]):
            return jsonify({"error": "Missing required fields"}), 400

        hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

        db = get_db_connection()
        cursor = db.cursor()

        cursor.execute("SELECT admission_number FROM users WHERE admission_number = %s", (admission_number,))
        if cursor.fetchone():
            cursor.close()
            db.close()
            return jsonify({"error": "Admission number already exists"}), 409

        cursor.execute("SELECT email FROM users WHERE email = %s", (email,))
        if cursor.fetchone():
            cursor.close()
            db.close()
            return jsonify({"error": "Email already exists"}), 409

        cursor.execute(
            "INSERT INTO users (admission_number, email, username, password, phone_number) VALUES (%s, %s, %s, %s, %s)",
            (admission_number, email, username, hashed_password, phone_number)
        )
        db.commit()
        print(f"New user {email} added to database with admission_number: {admission_number}")

        cursor.close()
        db.close()

        response_data = {
            "message": "Signup successful",
            "user": {
                "admission_number": admission_number,
                "email": email,
                "username": username,
                "phone_number": phone_number
            }
        }
        return jsonify(response_data), 201

    except mysql.connector.Error as db_err:
        print(f"Database Error: {db_err}")
        return jsonify({"error": "Database error", "details": str(db_err)}), 500
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"error": "Internal Server Error", "details": str(e)}), 500

@auth_bp.route('/login', methods=['POST'])
def login():
    """Handles user login and authenticates against the database."""
    try:
        data = request.json
        admission_number = data.get("admission_number")
        password = data.get("password")

        if not all([admission_number, password]):
            return jsonify({"error": "Missing admission number or password"}), 400

        db = get_db_connection()
        cursor = db.cursor(dictionary=True)  # Use dictionary for easier JSON mapping

        cursor.execute("SELECT admission_number, email, username, password, phone_number FROM users WHERE admission_number = %s", (admission_number,))
        user = cursor.fetchone()

        cursor.close()
        db.close()

        if not user:
            return jsonify({"error": "Invalid admission number or password"}), 401

        # Verify password
        if not bcrypt.checkpw(password.encode('utf-8'), user['password'].encode('utf-8')):
            return jsonify({"error": "Invalid admission number or password"}), 401

        # Successful login
        response_data = {
            "message": "Login successful",
            "user": {
                "admission_number": user['admission_number'],
                "email": user['email'],
                "username": user['username'],
                "phone_number": user['phone_number']
            }
        }
        print(f"User {admission_number} logged in successfully")
        return jsonify(response_data), 200

    except mysql.connector.Error as db_err:
        print(f"Database Error: {db_err}")
        return jsonify({"error": "Database error", "details": str(db_err)}), 500
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"error": "Internal Server Error", "details": str(e)}), 500

app.register_blueprint(auth_bp, url_prefix='/api/auth')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)
