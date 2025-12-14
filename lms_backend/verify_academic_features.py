import json
import urllib.request
import urllib.parse
from datetime import date
import sys

BASE_URL = "http://localhost:8000"
DEAN_USER = "truongkhoa"
DEAN_PASS = "12345678"

def make_request(url, method="GET", data=None, token=None):
    req_url = f"{BASE_URL}{url}"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    
    encoded_data = None
    if data:
        encoded_data = json.dumps(data).encode()
        
    req = urllib.request.Request(req_url, data=encoded_data, method=method, headers=headers)
    
    try:
        with urllib.request.urlopen(req) as response:
            if response.status in [200, 201]:
                resp_data = response.read()
                if resp_data:
                    return json.loads(resp_data)
                return {}
    except urllib.error.HTTPError as e:
        print(f"Request failed: {method} {url} -> {e.code} {e.read().decode()}")
        return None
    except Exception as e:
        print(f"Error: {e}")
        return None

def login(username, password):
    print(f"Logging in as {username}...")
    data = urllib.parse.urlencode({"username": username, "password": password}).encode()
    req = urllib.request.Request(f"{BASE_URL}/auth/login", data=data, method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    
    try:
        with urllib.request.urlopen(req) as response:
            body = json.loads(response.read())
            print("Login successful.")
            return body["access_token"]
    except Exception as e:
        print(f"Login failed: {e}")
        return None

def run_verification():
    # 1. Login as Dean
    token = login(DEAN_USER, DEAN_PASS)
    if not token:
        print("FATAL: Cannot login as Dean")
        return

    # 2. Create Academic Year
    print("\n--- Creating Academic Year ---")
    academic_year = {
        "year": "2023-2024",
        "start_date": "2023-08-01",
        "end_date": "2024-06-30",
        "is_active": True
    }
    ay_resp = make_request("/deans/academic-years", "POST", academic_year, token)
    if not ay_resp:
        print("Maybe already exists, fetching list...")
        ay_list = make_request("/deans/academic-years", "GET", None, token)
        if ay_list:
            for ay in ay_list:
                if ay["year"] == "2023-2024":
                    ay_resp = ay
                    break
    
    if not ay_resp:
        print("Failed to get Academic Year")
        return
        
    ay_id = ay_resp["id"]
    print(f"Academic Year ID: {ay_id}")

    # 3. Create Semester
    print("\n--- Creating Semester ---")
    semester = {
        "code": "20231",
        "name": "Học kỳ 1 năm 2023-2024",
        "academic_year_id": ay_id,
        "semester_number": 1,
        "start_date": "2023-08-15",
        "end_date": "2024-01-15",
        "is_active": True
    }
    sem_resp = make_request("/deans/semesters", "POST", semester, token)
    if not sem_resp:
        print("Maybe already exists, fetching list...")
        sem_list = make_request("/deans/semesters", "GET", None, token)
        if sem_list:
            for sem in sem_list:
                if sem["code"] == "20231":
                    sem_resp = sem
                    break
    
    if not sem_resp:
        print("Failed to get Semester")
        return
        
    sem_id = sem_resp["id"]
    sem_code = sem_resp["code"]
    print(f"Semester ID: {sem_id}, Code: {sem_code}")

    # 4. Create Course & Class
    print("\n--- Creating Course & Class ---")
    course_code = "MATH101"
    course = {"code": course_code, "name": "Giải tích 1", "credits": 3}
    course_resp = make_request("/deans/courses", "POST", course, token)
    if not course_resp:
        courses = make_request("/deans/courses", "GET", None, token)
        if courses:
            for c in courses:
                if c["code"] == course_code:
                    course_resp = c
                    break
    
    course_id = course_resp["id"]
    print(f"Course ID: {course_id}")
    
    lecturers = make_request("/deans/lecturers", "GET", None, token)
    lecturer_id = lecturers[0]["id"] if lecturers else 1
    
    class_code = "MATH101.20231.01"
    cls = {
        "code": class_code,
        "course_id": course_id,
        "lecturer_id": lecturer_id,
        "semester": sem_code,
        "max_students": 100
    }
    class_resp = make_request("/deans/classes", "POST", cls, token)
    if not class_resp:
         classes = make_request("/deans/classes", "GET", None, token)
         if classes:
             for c in classes:
                 if c["code"] == class_code:
                     class_resp = c
                     break
    
    class_id = class_resp["id"]
    print(f"Class ID: {class_id}")

    # 5. Create Student & Enroll
    print("\n--- Creating Student & Enrolling ---")
    student_user = "student_verify"
    student_pass = "12345678"
    student_data = {
        "username": student_user,
        "password": student_pass,
        "email": "verify@stu.com",
        "full_name": "Student Verify",
        "role": "student",
        "student_code": "SV20230001"
    }
    make_request("/deans/students", "POST", student_data, token)
    
    # Login as student to get ID
    stu_token = login(student_user, student_pass)
    if not stu_token:
        print("Failed to login as student")
        return

    stu_me = make_request("/students/me", "GET", None, stu_token)
    student_id = stu_me["id"]
    print(f"Student ID: {student_id}")
    
    # Enroll student in class
    enroll_data = {"student_ids": [student_id]}
    print(f"Enrolling student {student_id} into class {class_id}...")
    make_request(f"/deans/classes/{class_id}/enrollments/bulk", "POST", enroll_data, token)
    
    # Get enrollment ID
    class_students = make_request(f"/deans/classes/{class_id}/grades", "GET", None, token)
    enrollment_id = None
    if class_students:
        for s in class_students:
            if s["student_id"] == student_id:
                enrollment_id = s["enrollment_id"]
                break
    print(f"Enrollment ID: {enrollment_id}")
    
    # 6. Setup Grades
    print("\n--- Entering Grades ---")
    if enrollment_id:
        grade_data = {
            "enrollment_id": enrollment_id,
            "grade_type": "final",
            "score": 8.5, # Should be A (4.0)
            "weight": 1.0
        }
        make_request("/deans/grades", "POST", grade_data, token)

    # 7. Calculate Results
    print("\n--- Calculating Academic Results ---")
    calc_resp = make_request(f"/deans/semesters/{sem_id}/calculate-results", "POST", None, token)
    print(f"Calculation response: {calc_resp}")
    
    # 8. Verify as Student
    print("\n--- Verifying as Student ---")
    my_results = make_request("/students/my-results", "GET", None, stu_token)
    print("My Results Summary:", json.dumps(my_results, indent=2))
    
    if my_results:
        print("\n--- Verifying Semester Detail ---")
        detail = make_request(f"/students/my-results/{sem_code}", "GET", None, stu_token)
        print("Semester Detail:", json.dumps(detail, indent=2))
        
        # Verify correctness
        if len(my_results) > 0:
            latest = my_results[0]
            if latest["gpa"] == 4.0:
                print("\n✅ SUCCESS: GPA calculated correctly as 4.0 (for score 8.5)")
            else:
                print(f"\n❌ FAILURE: Expected GPA 4.0, got {latest['gpa']}")
    else:
        print("\n❌ FAILURE: No results found for student")

if __name__ == "__main__":
    run_verification()
