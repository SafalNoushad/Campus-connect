from flask_sqlalchemy import SQLAlchemy #type:ignore
from flask_migrate import Migrate   #type:ignore
from sqlalchemy import create_engine    #type:ignore

db = SQLAlchemy()
migrate = Migrate() 
try:
    engine = create_engine("mysql+pymysql://root:Eva%400305@localhost/campus_connect")
    conn = engine.connect()
    print("Database connection successful!")
    conn.close()
except Exception as e:
    print("Database Connection Error:", e)
