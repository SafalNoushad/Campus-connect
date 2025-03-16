from app import create_app, db
from models import User, Department
import bcrypt

app = create_app()

with app.app_context():
    # Ensure a department exists
    if not Department.query.filter_by(departmentcode='CS').first():
        dept = Department(departmentcode='CS', departmentname='Computer Science')
        db.session.add(dept)
        db.session.commit()
        print("Department 'CS' created.")

    # Create initial admin if not exists
    if not User.query.filter_by(admission_number='admin001').first():
        hashed_password = bcrypt.hashpw("mbcpeermade".encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        admin = User(
            admission_number='admin001',
            username='AdminUser',
            email='admin001@mbcpeermade.com',
            password=hashed_password,
            role='admin',
            departmentcode='CS'
        )
        db.session.add(admin)
        db.session.commit()
        print("Initial admin user created successfully with password 'mbcpeermade'!")
    else:
        print("Admin user already exists.")