import mysql.connector
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def get_db_connection():
    """Establish MySQL database connection."""
    try:
        db = mysql.connector.connect(
            host=os.getenv("MYSQL_HOST"),
            user=os.getenv("MYSQL_USER"),
            password="Eva@0305",
            database=os.getenv("MYSQL_DB")
        )
        return db
    except mysql.connector.Error as err:
        print(f"❌ Database Connection Error: {err}")
        raise
