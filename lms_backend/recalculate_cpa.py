"""
Script: Login as dean and recalculate all CPA
"""
import requests

# Login
login_response = requests.post(
    "http://localhost:8000/api/auth/login",
    data={"username": "dean", "password": "dean123"}
)

if login_response.status_code == 200:
    token = login_response.json()["access_token"]
    print(f"✓ Login successful! Token: {token[:50]}...")
    
    # Recalculate CPA
    print("\nRecalculating CPA for all students...")
    recalc_response = requests.post(
        "http://localhost:8000/api/deans/recalculate-all-cpa",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    if recalc_response.status_code == 200:
        result = recalc_response.json()
        print(f"\n✓ Recalculation completed!")
        print(f"  Total students: {result['total_students']}")
        print(f"  Success: {result['success']}")
        print(f"  Errors: {result['errors']}")
        if result.get('error_details'):
            print(f"\n  Error details:")
            for error in result['error_details']:
                print(f"    - {error}")
    else:
        print(f"✗ Recalculation failed: {recalc_response.status_code}")
        print(recalc_response.text)
else:
    print(f"✗ Login failed: {login_response.status_code}")
    print(login_response.text)
