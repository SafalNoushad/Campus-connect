from database import db
from sqlalchemy import Enum
from datetime import datetime

class User(db.Model):
    __tablename__ = 'users'
    admission_number = db.Column(db.String(50), primary_key=True, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)  # Note: Not nullable=False
    email = db.Column(db.String(255), unique=True, nullable=False)
    password = db.Column(db.String(255), nullable=False)
    phone_number = db.Column(db.String(20), nullable=True)
    role = db.Column(Enum('admin', 'teacher', 'student', name='user_roles'), default='student', nullable=False)
    username = db.Column(db.String(100), nullable=False)

    def to_dict(self):
        return {
            "admission_number": self.admission_number,
            "created_at": self.created_at.strftime('%Y-%m-%d %H:%M:%S') if self.created_at else None,
            "email": self.email,
            "phone_number": self.phone_number,
            "role": self.role,
            "username": self.username
        }

class Department(db.Model):
    __tablename__ = 'departments'
    id = db.Column(db.Integer, primary_key=True)
    departmentcode = db.Column(db.String(10), unique=True, nullable=False)
    departmentname = db.Column(db.String(100), nullable=False)

    def to_dict(self):
        return {
            "id": self.id,
            "departmentcode": self.departmentcode,
            "departmentname": self.departmentname
        }