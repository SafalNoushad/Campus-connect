from flask import Flask, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from routes.auth_routes import auth_bp
from config import Config

app = Flask(__name__)
CORS(app)

app.config.from_object(Config)
app.config["JWT_SECRET_KEY"] = Config.SECRET_KEY
jwt = JWTManager(app)

# Register authentication routes
app.register_blueprint(auth_bp, url_prefix="/api/auth")

# ✅ Add this route to fix the 404 error
@app.route("/")
def home():
    return jsonify({"message": "Campus Connect Backend is Running"})

if __name__ == "__main__":
    app.run(debug=True ,port=5001)
