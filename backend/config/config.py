import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    SQLALCHEMY_DATABASE_URI = f"mysql+pymysql://{os.getenv('MYSQL_USER')}:{os.getenv('MYSQL_PASSWORD')}@{os.getenv('MYSQL_HOST')}/{os.getenv('MYSQL_DB')}"
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SECRET_KEY = os.getenv("SECRET_KEY")  # Ensure SECRET_KEY is loaded
    print("MYSQL_USER:", os.getenv("MYSQL_USER"))
    print("MYSQL_PASSWORD:", os.getenv("MYSQL_PASSWORD"))
    print("MYSQL_HOST:", os.getenv("MYSQL_HOST"))
    print("MYSQL_DB:", os.getenv("MYSQL_DB"))
    print("SECRET_KEY:", os.getenv("SECRET_KEY"))
