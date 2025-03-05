import mysql.connector
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Connect to MySQL
try:
    db = mysql.connector.connect(
        host=os.getenv("MYSQL_HOST"),
        user=os.getenv("MYSQL_USER"),
        password=os.getenv("MYSQL_PASSWORD"),
        database=os.getenv("MYSQL_DB")
    )

    cursor = db.cursor()
    cursor.execute("SHOW TABLES;")
    print("✅ Connected to MySQL! Tables:", cursor.fetchall())

except mysql.connector.Error as err:
    print(f"❌ Error: {err}")
