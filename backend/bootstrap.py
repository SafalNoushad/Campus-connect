from app import create_app, db
from models import User, Department
import bcrypt
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Admin credentials
ADMIN_ADMISSION_NUMBER = 'admin001'
ADMIN_USERNAME = 'AdminUser'
ADMIN_EMAIL = 'admin001@mbcpeermade.com'
ADMIN_PASSWORD = 'mbcpeermade'  # Plaintext password to be hashed
ADMIN_ROLE = 'admin'
ADMIN_DEPARTMENT_CODE = 'CS'
ADMIN_DEPARTMENT_NAME = 'Computer Science'

def bootstrap_admin():
    app = create_app()

    with app.app_context():
        try:
            # Ensure the department exists
            department = Department.query.filter_by(departmentcode=ADMIN_DEPARTMENT_CODE).first()
            if not department:
                department = Department(
                    departmentcode=ADMIN_DEPARTMENT_CODE,
                    departmentname=ADMIN_DEPARTMENT_NAME
                )
                db.session.add(department)
                db.session.commit()
                logger.info(f"Department '{ADMIN_DEPARTMENT_CODE}' created successfully.")
            else:
                logger.info(f"Department '{ADMIN_DEPARTMENT_CODE}' already exists.")

            # Check if admin user already exists
            admin_user = User.query.filter_by(admission_number=ADMIN_ADMISSION_NUMBER).first()
            if not admin_user:
                # Hash the password using bcrypt
                hashed_password = bcrypt.hashpw(
                    ADMIN_PASSWORD.encode('utf-8'),
                    bcrypt.gensalt()
                ).decode('utf-8')

                # Create the admin user with minimal required fields
                admin = User(
                    admission_number=ADMIN_ADMISSION_NUMBER,
                    username=ADMIN_USERNAME,
                    email=ADMIN_EMAIL,
                    password=hashed_password,
                    role=ADMIN_ROLE,
                    departmentcode=ADMIN_DEPARTMENT_CODE
                )
                db.session.add(admin)
                db.session.commit()
                logger.info(f"Admin user '{ADMIN_ADMISSION_NUMBER}' created successfully with password '{ADMIN_PASSWORD}'.")
            else:
                logger.info(f"Admin user '{ADMIN_ADMISSION_NUMBER}' already exists.")

        except Exception as e:
            db.session.rollback()
            logger.error(f"Error during bootstrap: {str(e)}", exc_info=True)
            raise

if __name__ == "__main__":
    bootstrap_admin()