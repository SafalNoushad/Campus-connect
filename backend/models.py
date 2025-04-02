from database import db
from datetime import datetime
from sqlalchemy import Enum
import bcrypt

# User Model (unchanged)
class User(db.Model):
    __tablename__ = 'users'
    admission_number = db.Column(db.String(50), primary_key=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    email = db.Column(db.String(255), unique=True, nullable=False)
    password = db.Column(db.String(255), nullable=False)
    role = db.Column(Enum('admin', 'hod', 'staff', 'student', name='user_roles'), default='student', nullable=False)
    username = db.Column(db.String(100), nullable=False)
    departmentcode = db.Column(db.String(10), db.ForeignKey('departments.departmentcode'), nullable=False)
    semester = db.Column(db.String(2), nullable=True)  # e.g., 'S1', 'S2', nullable for non-students
    phone_number = db.Column(db.String(15), nullable=True)
    batch = db.Column(db.String(10), nullable=True)  # e.g., '2023', nullable for non-students

    def set_password(self, password):
        """Hash and set the user's password."""
        self.password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

    def check_password(self, password):
        """Check if the provided password matches the stored hash."""
        return bcrypt.checkpw(password.encode('utf-8'), self.password.encode('utf-8'))

    def to_dict(self):
        """Convert user object to a dictionary for JSON response."""
        return {
            'admission_number': self.admission_number,
            'email': self.email,
            'role': self.role,
            'username': self.username,
            'departmentcode': self.departmentcode,
            'semester': self.semester,
            'phone_number': self.phone_number,
            'batch': self.batch,
            'created_at': self.created_at.isoformat()
        }

# Department Model (unchanged)
class Department(db.Model):
    __tablename__ = 'departments'
    departmentcode = db.Column(db.String(10), primary_key=True)  # e.g., 'CS', 'ME'
    departmentname = db.Column(db.String(100), nullable=False)  # e.g., 'Computer Science'

    def to_dict(self):
        """Convert department object to a dictionary."""
        return {
            'departmentcode': self.departmentcode,
            'departmentname': self.departmentname
        }

# Subject Model (unchanged)
class Subject(db.Model):
    __tablename__ = 'subjects'
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    semester = db.Column(db.String(2), nullable=False)  # e.g., 'S1', 'S2'
    subject_code = db.Column(db.String(10), unique=True, nullable=False)  # e.g., 'CS101'
    subject_name = db.Column(db.String(100), nullable=False)  # e.g., 'Introduction to Programming'
    credits = db.Column(db.Integer, nullable=False)  # e.g., 4
    departmentcode = db.Column(db.String(10), db.ForeignKey('departments.departmentcode'), nullable=False)
    instructor_id = db.Column(db.String(50), db.ForeignKey('users.admission_number'), nullable=True)  # New column for instructor

    def to_dict(self):
        """Convert subject object to a dictionary."""
        return {
            'id': self.id,
            'semester': self.semester,
            'subject_code': self.subject_code,
            'subject_name': self.subject_name,
            'credits': self.credits,
            'departmentcode': self.departmentcode,
            'instructor_id': self.instructor_id
        }

# Timetable Model (unchanged)
class Timetable(db.Model):
    __tablename__ = 'timetables'
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    semester = db.Column(db.String(2), nullable=False)  # e.g., 'S1', 'S2'
    filename = db.Column(db.String(255), nullable=False)  # e.g., 'S1_CS101_Module1_20231010.xlsx'
    departmentcode = db.Column(db.String(10), db.ForeignKey('departments.departmentcode'), nullable=False)
    uploaded_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    def to_dict(self):
        """Convert timetable object to a dictionary."""
        return {
            'id': self.id,
            'semester': self.semester,
            'filename': self.filename,
            'departmentcode': self.departmentcode,
            'uploaded_at': self.uploaded_at.isoformat()
        }

# Notes Model (unchanged)
class Notes(db.Model):
    __tablename__ = 'notes'
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    semester = db.Column(db.String(2), nullable=False)  # e.g., 'S1', 'S2'
    filename = db.Column(db.String(255), nullable=False)  # e.g., 'S1_CS101_Module1_20231010.pdf'
    departmentcode = db.Column(db.String(10), db.ForeignKey('departments.departmentcode'), nullable=False)
    uploaded_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    def to_dict(self):
        """Convert notes object to a dictionary."""
        return {
            'id': self.id,
            'semester': self.semester,
            'filename': self.filename,
            'departmentcode': self.departmentcode,
            'uploaded_at': self.uploaded_at.isoformat()
        }

# Announcement Model (General) (unchanged)
class Announcement(db.Model):
    __tablename__ = 'announcements'
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    title = db.Column(db.String(100), nullable=False)
    message = db.Column(db.Text, nullable=False)
    category = db.Column(Enum('bus', 'placement', 'class_suspension', 'event', 'general', name='announcement_categories'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    created_by = db.Column(db.String(50), db.ForeignKey('users.admission_number'), nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'message': self.message,
            'category': self.category,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat(),
            'created_by': self.created_by
        }

# Department Announcement Model (unchanged)
class DepartmentAnnouncement(db.Model):
    __tablename__ = 'department_announcements'
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    title = db.Column(db.String(100), nullable=False)
    message = db.Column(db.Text, nullable=False)
    category = db.Column(Enum('bus', 'placement', 'class_suspension', 'event', 'general', name='dept_announcement_categories'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    created_by = db.Column(db.String(50), db.ForeignKey('users.admission_number'), nullable=False)
    departmentcode = db.Column(db.String(10), db.ForeignKey('departments.departmentcode'), nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'message': self.message,
            'category': self.category,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat(),
            'created_by': self.created_by,
            'departmentcode': self.departmentcode
        }

# Assignment Model (unchanged)
class Assignment(db.Model):
    __tablename__ = 'assignments'
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    subject_code = db.Column(db.String(10), db.ForeignKey('subjects.subject_code'), nullable=False)
    staff_name = db.Column(db.String(100), nullable=False)  # Name of the staff assigning it
    assignment_number = db.Column(db.Integer, nullable=False)  # e.g., 1, 2, 3
    instructor_id = db.Column(db.String(50), db.ForeignKey('users.admission_number'), nullable=False)
    departmentcode = db.Column(db.String(10), db.ForeignKey('departments.departmentcode'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    submission_filename = db.Column(db.String(255), nullable=True)
    submitted_by = db.Column(db.String(50), db.ForeignKey('users.admission_number'), nullable=True)
    submitted_at = db.Column(db.DateTime, nullable=True)

    def to_dict(self):
        return {
            'id': self.id,
            'subject_code': self.subject_code,
            'staff_name': self.staff_name,
            'assignment_number': self.assignment_number,
            'instructor_id': self.instructor_id,
            'departmentcode': self.departmentcode,
            'created_at': self.created_at.isoformat(),
            'submission_filename': self.submission_filename,
            'submitted_by': self.submitted_by,
            'submitted_at': self.submitted_at.isoformat() if self.submitted_at else None
        }

# New Requests Model
class Requests(db.Model):
    __tablename__ = 'requests'
    application_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    category = db.Column(Enum('medical_leave', 'duty_leave', name='request_categories'), nullable=False)
    filename = db.Column(db.String(255), nullable=False)  # e.g., 'medical_leave_20250401_123.pdf'
    status = db.Column(Enum('pending', 'approved', 'rejected', name='request_status'), default='pending', nullable=False)
    admission_number = db.Column(db.String(50), db.ForeignKey('users.admission_number'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    def to_dict(self):
        """Convert request object to a dictionary."""
        return {
            'application_id': self.application_id,
            'category': self.category,
            'filename': self.filename,
            'status': self.status,
            'admission_number': self.admission_number,
            'created_at': self.created_at.isoformat()
        }