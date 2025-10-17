#!/usr/bin/env python3
"""
Test script to verify audio file creation and playback
"""

import requests
import json
import time
import os

API_BASE = 'http://localhost:5000/api'

def test_audio_generation():
    """Test the complete audio generation workflow"""
    
    print("🧪 Testing Audio Generation Fix")
    print("=" * 40)
    
    # 1. Check API health
    try:
        response = requests.get(f'{API_BASE}/health')
        if response.status_code == 200:
            print("✅ API is healthy")
        else:
            print("❌ API health check failed")
            return False
    except Exception as e:
        print(f"❌ API connection failed: {e}")
        return False
    
    # 2. Create a dummy file for upload
    test_file_path = '/tmp/test_audio.mp3'
    with open(test_file_path, 'wb') as f:
        f.write(b'dummy audio content for testing')
    
    # 3. Upload file
    try:
        with open(test_file_path, 'rb') as f:
            files = {'file': ('test_audio.mp3', f, 'audio/mpeg')}
            response = requests.post(f'{API_BASE}/upload', files=files)
        
        if response.status_code == 200:
            job_data = response.json()
            job_id = job_data['job_id']
            print(f"✅ File uploaded, job ID: {job_id[:8]}...")
        else:
            print(f"❌ Upload failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Upload error: {e}")
        return False
    
    # 4. Start separation
    try:
        response = requests.post(f'{API_BASE}/separate/{job_id}')
        if response.status_code == 200:
            print("✅ Separation started")
        else:
            print(f"❌ Separation failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Separation error: {e}")
        return False
    
    # 5. Wait for completion
    print("⏳ Waiting for processing to complete...")
    for i in range(15):  # Wait up to 15 seconds
        try:
            response = requests.get(f'{API_BASE}/status/{job_id}')
            if response.status_code == 200:
                status_data = response.json()
                progress = int(status_data['progress'] * 100)
                print(f"   Progress: {progress}%")
                
                if status_data['status'] == 'completed':
                    print("✅ Processing completed")
                    stems = status_data['stems']
                    break
                elif status_data['status'] == 'failed':
                    print(f"❌ Processing failed: {status_data.get('error', 'Unknown error')}")
                    return False
            
            time.sleep(1)
        except Exception as e:
            print(f"❌ Status check error: {e}")
            return False
    else:
        print("❌ Processing timeout")
        return False
    
    # 6. Check generated audio files
    print("\n🎵 Checking generated audio files:")
    for stem_name, stem_path in stems.items():
        if os.path.exists(stem_path):
            file_size = os.path.getsize(stem_path)
            print(f"✅ {stem_name}: {file_size} bytes")
            
            # Test download endpoint
            try:
                response = requests.get(f'{API_BASE}/download/{job_id}/{stem_name}')
                if response.status_code == 200:
                    print(f"   ✅ Download endpoint works for {stem_name}")
                else:
                    print(f"   ❌ Download failed for {stem_name}: {response.status_code}")
            except Exception as e:
                print(f"   ❌ Download error for {stem_name}: {e}")
        else:
            print(f"❌ {stem_name}: File not found at {stem_path}")
    
    # Cleanup
    try:
        os.remove(test_file_path)
    except:
        pass
    
    print("\n🎉 Audio generation test completed!")
    return True

if __name__ == "__main__":
    success = test_audio_generation()
    if success:
        print("\n✅ All tests passed! Audio playback should now work in the web demo.")
    else:
        print("\n❌ Some tests failed. Check the Flask API logs.")
