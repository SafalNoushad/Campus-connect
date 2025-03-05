import mysql.connector
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def get_db_connection():
    """Establish and return a database connection."""
    try:
        db = mysql.connector.connect(
            host=os.getenv("MYSQL_HOST"),
            user=os.getenv("MYSQL_USER"),
            password=os.getenv("MYSQL_PASSWORD"),
            database=os.getenv("MYSQL_DB"),
            autocommit=True  # ✅ Improves performance by auto-committing transactions
        )
        return db
    except mysql.connector.Error as err:
        print(f"❌ Database Connection Error: {err}")
        raise
