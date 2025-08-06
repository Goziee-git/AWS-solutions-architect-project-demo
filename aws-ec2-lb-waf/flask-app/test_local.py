#!/usr/bin/env python3
"""
Simple test script to verify the Flask application works locally
"""

import requests
import time
import sys
import subprocess
import threading
from app import app

def test_endpoints():
    """Test various endpoints"""
    base_url = "http://localhost:8080"
    
    endpoints_to_test = [
        "/health",
        "/api/status",
        "/api/instance-info",
        "/search?q=test",
        "/api/data",
        "/api/metrics"
    ]
    
    print("Testing endpoints...")
    
    for endpoint in endpoints_to_test:
        try:
            response = requests.get(f"{base_url}{endpoint}", timeout=5)
            status = "✅ PASS" if response.status_code == 200 else f"❌ FAIL ({response.status_code})"
            print(f"{endpoint}: {status}")
        except requests.exceptions.RequestException as e:
            print(f"{endpoint}: ❌ ERROR - {e}")
    
    # Test POST endpoint
    try:
        response = requests.post(
            f"{base_url}/comment",
            json={"comment": "Test comment"},
            timeout=5
        )
        status = "✅ PASS" if response.status_code == 200 else f"❌ FAIL ({response.status_code})"
        print(f"/comment (POST): {status}")
    except requests.exceptions.RequestException as e:
        print(f"/comment (POST): ❌ ERROR - {e}")

def run_server():
    """Run the Flask server in a separate thread"""
    app.run(host='0.0.0.0', port=8080, debug=False, use_reloader=False)

if __name__ == "__main__":
    print("Starting Flask application test...")
    
    # Start server in background thread
    server_thread = threading.Thread(target=run_server, daemon=True)
    server_thread.start()
    
    # Wait for server to start
    print("Waiting for server to start...")
    time.sleep(3)
    
    # Test endpoints
    test_endpoints()
    
    print("\nTest completed. Server is still running on http://localhost:8080")
    print("Press Ctrl+C to stop the server.")
    
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nShutting down...")
        sys.exit(0)
