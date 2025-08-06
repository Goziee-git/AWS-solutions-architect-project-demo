#!/usr/bin/env python3
"""
Startup script for the Flask application
"""

import os
import sys
from app import app

if __name__ == '__main__':
    # Get port from environment or default to 8080
    port = int(os.environ.get('PORT', 8080))
    host = os.environ.get('HOST', '0.0.0.0')
    debug = os.environ.get('DEBUG', 'False').lower() == 'true'
    
    print(f"Starting Flask app on {host}:{port}")
    print(f"Debug mode: {debug}")
    
    app.run(
        host=host,
        port=port,
        debug=debug,
        threaded=True
    )
