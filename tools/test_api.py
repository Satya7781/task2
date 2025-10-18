#!/usr/bin/env python3
"""
Test script to verify the Flask API is working correctly
"""

import requests
import json

API_BASE = 'http://localhost:5000/api'

def test_health():
    """Test the health endpoint"""
    try:
        response = requests.get(f'{API_BASE}/health')
        if response.status_code == 200:
            data = response.json()
            print("✅ Health check passed")
            print(f"   Status: {data['status']}")
            print(f"   Device: {data['device']}")
            print(f"   Model loaded: {data['model_loaded']}")
            return True
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Health check error: {e}")
        return False

def test_jobs():
    """Test the jobs endpoint"""
    try:
        response = requests.get(f'{API_BASE}/jobs')
        if response.status_code == 200:
            data = response.json()
            print("✅ Jobs endpoint working")
            print(f"   Current jobs: {len(data['jobs'])}")
            return True
        else:
            print(f"❌ Jobs endpoint failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Jobs endpoint error: {e}")
        return False

def main():
    print("🧪 Testing Flask API...")
    print("=" * 40)
    
    health_ok = test_health()
    jobs_ok = test_jobs()
    
    print("=" * 40)
    if health_ok and jobs_ok:
        print("🎉 All API tests passed!")
        print("📱 Web demo should work at: http://localhost:8080")
        print("📱 Mobile app should connect successfully")
    else:
        print("❌ Some tests failed. Check the Flask API server.")

if __name__ == "__main__":
    main()
