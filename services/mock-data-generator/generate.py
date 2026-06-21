"""
IOS+ Mock Data Generator
Populates PostgreSQL with synthetic students, courses, transcripts, and CLO data
for Wave 1 MVP simulation of UC-01 through UC-05.
"""

import os
import random
import datetime
from faker import Faker
import psycopg2
from psycopg2.extras import execute_values

fake = Faker()
Faker.seed(42)
random.seed(42)

DB_URL = os.getenv("DATABASE_URL", "postgresql://ios_admin:ios_local_dev@postgres:5432/ios_plus")
STUDENT_COUNT = int(os.getenv("SYNTHETIC_STUDENT_COUNT", "500"))
COURSE_COUNT = int(os.getenv("SYNTHETIC_COURSE_COUNT", "200"))
TRANSCRIPT_COUNT = int(os.getenv("SYNTHETIC_TRANSCRIPT_COUNT", "150"))

def get_conn():
    return psycopg2.connect(DB_URL)

def generate_students(conn, count):
    cur = conn.cursor()
    students = []
    for i in range(count):
        students.append((
            f"SYN-{i+1:05d}",
            f"LU-{random.randint(2022, 2026)}-{random.randint(10000, 99999)}",
            fake.first_name(),
            fake.last_name(),
            fake.email(),
            random.choice(["MIS", "Marketing", "Accounting", "Nursing", "Engineering", "Biology", "Psychology", "History"]),
            random.choice(["Freshman", "Sophomore", "Junior", "Senior", "Graduate"]),
            round(random.uniform(1.5, 4.0), 2),
            random.choice([True, False, False, False]),
            datetime.datetime.now()
        ))
    
    execute_values(cur, """
        INSERT INTO synthetic_students (syn_id, student_id, first_name, last_name, email, major, class_level, gpa, is_first_generation, created_at)
        VALUES %s
        ON CONFLICT (syn_id) DO NOTHING
    """, students)
    conn.commit()
    cur.close()
    print(f"Generated {count} synthetic students")

def generate_courses(conn, count):
    cur = conn.cursor()
    course_prefixes = ["ACCT", "ECON", "MIS", "MKTG", "FINA", "MGMT", "NURS", "ENGR", "BIOL", "HIST", "PSYC", "MATH"]
    courses = []
    for i in range(count):
        prefix = random.choice(course_prefixes)
        level = random.choice(["1300", "2300", "3300", "4300", "5300"])
        courses.append((
            f"{prefix} {level}",
            fake.catch_phrase(),
            random.randint(1, 4),
            random.choice(["Fall", "Spring", "Summer"]),
            random.randint(2024, 2026),
            random.randint(15, 120),
            datetime.datetime.now()
        ))
    
    execute_values(cur, """
        INSERT INTO synthetic_courses (course_id, course_name, credits, term, year, max_enrollment, created_at)
        VALUES %s
        ON CONFLICT (course_id) DO NOTHING
    """, courses)
    conn.commit()
    cur.close()
    print(f"Generated {count} synthetic courses")

def generate_transcripts(conn, count):
    cur = conn.cursor()
    cur.execute("SELECT syn_id FROM synthetic_students")
    student_ids = [r[0] for r in cur.fetchall()]
    cur.execute("SELECT course_id, credits FROM synthetic_courses")
    course_rows = cur.fetchall()
    
    transcripts = []
    for i in range(min(count, len(student_ids) * 3)):
        student = random.choice(student_ids)
        course, credits = random.choice(course_rows)
        grade = random.choice(["A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D", "F", "W"])
        grade_map = {"A": 4.0, "A-": 3.7, "B+": 3.3, "B": 3.0, "B-": 2.7, "C+": 2.3, "C": 2.0, "C-": 1.7, "D": 1.0, "F": 0.0, "W": 0.0}
        points = grade_map.get(grade, 0.0)
        
        transcripts.append((
            f"TRX-{i+1:05d}",
            student,
            course,
            random.choice(["Lone Star College", "San Jacinto College", "Austin Community College", "Houston Community College"]),
            grade,
            points,
            credits,
            random.choice(["Fall", "Spring", "Summer"]),
            random.randint(2020, 2024),
            datetime.datetime.now()
        ))
    
    execute_values(cur, """
        INSERT INTO synthetic_transcripts (transcript_id, syn_id, course_id, source_institution, grade, points, credits, term, year, created_at)
        VALUES %s
        ON CONFLICT (transcript_id) DO NOTHING
    """, transcripts)
    conn.commit()
    cur.close()
    print(f"Generated {len(transcripts)} synthetic transcripts")

def create_tables(conn):
    cur = conn.cursor()
    
    cur.execute("""
        CREATE TABLE IF NOT EXISTS synthetic_students (
            id SERIAL PRIMARY KEY,
            syn_id VARCHAR(20) UNIQUE NOT NULL,
            student_id VARCHAR(20) NOT NULL,
            first_name VARCHAR(100),
            last_name VARCHAR(100),
            email VARCHAR(255),
            major VARCHAR(100),
            class_level VARCHAR(50),
            gpa DECIMAL(3,2),
            is_first_generation BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    
    cur.execute("""
        CREATE TABLE IF NOT EXISTS synthetic_courses (
            id SERIAL PRIMARY KEY,
            course_id VARCHAR(20) UNIQUE NOT NULL,
            course_name VARCHAR(255),
            credits INTEGER,
            term VARCHAR(20),
            year INTEGER,
            max_enrollment INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    
    cur.execute("""
        CREATE TABLE IF NOT EXISTS synthetic_transcripts (
            id SERIAL PRIMARY KEY,
            transcript_id VARCHAR(20) UNIQUE NOT NULL,
            syn_id VARCHAR(20) REFERENCES synthetic_students(syn_id),
            course_id VARCHAR(20) REFERENCES synthetic_courses(course_id),
            source_institution VARCHAR(255),
            grade VARCHAR(5),
            points DECIMAL(3,2),
            credits DECIMAL(3,1),
            term VARCHAR(20),
            year INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    
    conn.commit()
    cur.close()
    print("Tables created/verified")

def main():
    print("=" * 50)
    print("IOS+ Mock Data Generator")
    print("=" * 50)
    print(f"Database: {DB_URL}")
    print(f"Students: {STUDENT_COUNT}")
    print(f"Courses: {COURSE_COUNT}")
    print(f"Transcripts: {TRANSCRIPT_COUNT}")
    print("-" * 50)
    
    conn = get_conn()
    try:
        create_tables(conn)
        generate_students(conn, STUDENT_COUNT)
        generate_courses(conn, COURSE_COUNT)
        generate_transcripts(conn, TRANSCRIPT_COUNT)
        print("-" * 50)
        print("Mock data generation complete!")
    except Exception as e:
        print(f"ERROR: {e}")
        conn.rollback()
        raise
    finally:
        conn.close()

if __name__ == "__main__":
    main()
