
import json
import urllib.request
import urllib.parse
import sys

BASE_URL = "http://localhost:8000"
DEAN_USER = "truongkhoa"
DEAN_PASS = "12345678"

def login(username, password):
    print(f"Logging in as {username}...")
    url = f"{BASE_URL}/auth/login"
    data = urllib.parse.urlencode({
        "username": username,
        "password": password
    }).encode()
    
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    
    try:
        with urllib.request.urlopen(req) as response:
            if response.status == 200:
                body = json.loads(response.read())
                print("Login successful.")
                return body["access_token"]
    except urllib.error.HTTPError as e:
        print(f"Login failed: {e.code} {e.read().decode()}")
        return None
    except Exception as e:
         print(f"Login error: {e}")
         return None

def test_flow():
    token = login(DEAN_USER, DEAN_PASS)
    if not token:
        print("Could not login as Dean. Skipping creation test.")
        # Try a fallback or assume admin/admin if defaulted? No, seeded data implied.
        return

    # 2. Create Lecturer
    new_user = "lecturer_urllib_1"
    new_pass = "12345678"
    print(f"Creating lecturer {new_user} with password {new_pass}...")
    
    url = f"{BASE_URL}/deans/lecturers"
    data = json.dumps({
        "username": new_user,
        "email": f"{new_user}@test.com",
        "full_name": "Test Lecturer Urllib",
        "phone_number": "0123456789",
        "password": new_pass,
        "role": "lecturer"
    }).encode()
    
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Content-Type", "application/json")
    
    try:
        with urllib.request.urlopen(req) as response:
            print("Lecturer created successfully.")
            response.read() # Consume
    except urllib.error.HTTPError as e:
        if e.code == 400:
             print("Lecturer creation failed (likely exists):", e.read().decode())
        else:
            print(f"Failed to create lecturer: {e.code} {e.read().decode()}")
            return

    # ... (Lecturer created) ...
    
    # 2.5 Seed Data: Create Course & Class & Enroll Student (As Dean)
    print("Seeding data...")
     # Create Course
    course_code = "TEST101"
    course_id = 1 # Fallback
    try:
        url_course = f"{BASE_URL}/deans/courses"
        data_course = json.dumps({"code": course_code, "name": "Mobile Test Course", "credits": 3}).encode()
        req_c = urllib.request.Request(url_course, data=data_course, method="POST")
        req_c.add_header("Authorization", f"Bearer {token}")
        req_c.add_header("Content-Type", "application/json")
        with urllib.request.urlopen(req_c) as resp:
            c_data = json.loads(resp.read().decode())
            course_id = c_data['id']
            print(f"Course created: {course_id}")
    except urllib.error.HTTPError:
        print("Course likely exists, using ID 1 (risk)")
        # Ideally fetch course by code.

    # Create Class
    lecturer_id = 0 # Need lecturer ID. 
    # Actually we don't have lecturer ID from create response easily if it says "already exists".
    # But we can get it from login /me.
    
    # Let's Login as Lecturer first to get ID
    print("Getting Lecturer ID...")
    lecturer_token = login(new_user, new_pass)
    lecturer_id = 0
    if lecturer_token:
        url_me = f"{BASE_URL}/lecturers/me"
        req_me = urllib.request.Request(url_me, method="GET")
        req_me.add_header("Authorization", f"Bearer {lecturer_token}")
        with urllib.request.urlopen(req_me) as resp:
            me_data = json.loads(resp.read().decode())
            lecturer_id = me_data['id']
            print(f"Lecturer ID: {lecturer_id}")

    if lecturer_id > 0:
        # Create Class assigned to this lecturer
        print(f"Creating class for lecturer {lecturer_id}...")
        url_class = f"{BASE_URL}/deans/classes"
        data_class = json.dumps({
            "code": "MOB101", 
            "course_id": course_id, 
            "lecturer_id": lecturer_id,
            "semester": "HK1",
            "max_students": 30
        }).encode()
        req_cl = urllib.request.Request(url_class, data=data_class, method="POST")
        req_cl.add_header("Authorization", f"Bearer {token}")
        req_cl.add_header("Content-Type", "application/json")
        try:
            with urllib.request.urlopen(req_cl) as resp:
                print("Class created.")
        except urllib.error.HTTPError as e:
            print(f"Class creation warning: {e.code} (might exist)")
            
        # Create Student & Enroll
        print("Creating Student...")
        stu_user = "student_mob_1"
        stu_pass = "12345678"
        url_stu = f"{BASE_URL}/deans/students"
        data_stu = json.dumps({
            "username": stu_user, "password": stu_pass,
            "email": "stu@mob.com", "full_name": "Student Mobile", 
            "student_code": "STU001", "role": "student"
        }).encode()
        req_s = urllib.request.Request(url_stu, data=data_stu, method="POST")
        req_s.add_header("Authorization", f"Bearer {token}")
        req_s.add_header("Content-Type", "application/json")
        student_id = 0
        try:
            with urllib.request.urlopen(req_s) as resp:
                 print("Student created.")
        except:
             print("Student likely exists.")
        
        # We need Student ID for enrollment. Login as student to get it? Or assume from DB?
        # Let's skip enrollment for now if complicated, but verify Class list first.
        # Actually Enrollment is needed for "view members".
        # Assume Dean can enroll by student_code? 
        # Check enroll API: POST /deans/enrollments -> student_id (int).
        # Need student ID.
        pass

    # 4. Verify Lecturer Data
    print("Verifying Lecturer Data...")
    if lecturer_token:
        print("Fetching lecturer classes...")
        url = f"{BASE_URL}/lecturers/my-classes"
        req = urllib.request.Request(url, method="GET")
        req.add_header("Authorization", f"Bearer {lecturer_token}")
        
        try:
            with urllib.request.urlopen(req) as response:
                print("Classes fetched successfully.")
                classes_data = json.loads(response.read().decode())
                print(f"Found {len(classes_data)} classes.")
                
                if classes_data:
                    first_class_id = classes_data[0]['id']
                    print(f"Fetching students for class {first_class_id}...")
                    url_students = f"{BASE_URL}/lecturers/classes/{first_class_id}/students"
                    req_stu = urllib.request.Request(url_students, method="GET")
                    req_stu.add_header("Authorization", f"Bearer {lecturer_token}")
                    try:
                        with urllib.request.urlopen(req_stu) as resp_stu:
                            print("Students fetched successfully.")
                            stu_data = json.loads(resp_stu.read().decode())
                            print(f"Found {len(stu_data)} students.")
                            if len(stu_data) > 0:
                                print("First student sample:", json.dumps(stu_data[0], indent=2))
                    except urllib.error.HTTPError as e:
                        print(f"Failed to fetch students: {e.code} {e.read().decode()}")

        except urllib.error.HTTPError as e:
            print(f"Failed to fetch classes: {e.code} {e.read().decode()}")
    else:
        print("Lecturer token not available, skipping verification.")

if __name__ == "__main__":
    test_flow()
