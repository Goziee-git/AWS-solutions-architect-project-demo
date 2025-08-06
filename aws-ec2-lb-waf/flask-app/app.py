#!/usr/bin/env python3
"""
Flask Web Application for AWS EC2 + ALB + WAF Demo
This application runs on EC2 instances behind an Application Load Balancer
and includes endpoints for testing WAF rules and load balancing functionality.
"""

from flask import Flask, jsonify, request, render_template, send_from_directory
import requests
import json
import time
import os
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configuration
app.config['SECRET_KEY'] = 'demo-secret-key-change-in-production'
app.config['DEBUG'] = False

def get_instance_metadata():
    """Get EC2 instance metadata"""
    try:
        # Instance ID
        instance_id = requests.get(
            'http://169.254.169.254/latest/meta-data/instance-id', 
            timeout=2
        ).text
        
        # Availability Zone
        az = requests.get(
            'http://169.254.169.254/latest/meta-data/placement/availability-zone', 
            timeout=2
        ).text
        
        # Private IP
        private_ip = requests.get(
            'http://169.254.169.254/latest/meta-data/local-ipv4', 
            timeout=2
        ).text
        
        # Public IP (if available)
        try:
            public_ip = requests.get(
                'http://169.254.169.254/latest/meta-data/public-ipv4', 
                timeout=2
            ).text
        except:
            public_ip = 'N/A'
        
        # Instance type
        try:
            instance_type = requests.get(
                'http://169.254.169.254/latest/meta-data/instance-type', 
                timeout=2
            ).text
        except:
            instance_type = 'unknown'
        
        return {
            'instance_id': instance_id,
            'availability_zone': az,
            'private_ip': private_ip,
            'public_ip': public_ip,
            'instance_type': instance_type,
            'region': az[:-1] if az != 'unknown' else 'unknown'
        }
    except Exception as e:
        logger.error(f"Error getting instance metadata: {e}")
        return {
            'instance_id': 'unknown',
            'availability_zone': 'unknown',
            'private_ip': 'unknown',
            'public_ip': 'unknown',
            'instance_type': 'unknown',
            'region': 'unknown'
        }

# Global variable to cache metadata
INSTANCE_METADATA = get_instance_metadata()

@app.route('/')
def index():
    """Main page with testing interface"""
    return render_template('index.html', metadata=INSTANCE_METADATA)

@app.route('/health')
def health():
    """Health check endpoint for ALB"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'service': 'ec2-alb-waf-demo',
        **INSTANCE_METADATA
    }), 200

@app.route('/api/status')
def api_status():
    """API status endpoint"""
    return jsonify({
        'status': 'operational',
        'service': 'ec2-alb-waf-demo',
        'version': '1.0.0',
        'timestamp': datetime.utcnow().isoformat(),
        'uptime': time.time(),
        **INSTANCE_METADATA
    })

@app.route('/api/instance-info')
def instance_info():
    """Get detailed instance information"""
    return jsonify({
        'timestamp': datetime.utcnow().isoformat(),
        **INSTANCE_METADATA
    })

@app.route('/search')
def search():
    """Search endpoint - intentionally vulnerable for WAF testing"""
    query = request.args.get('q', '')
    
    # Log the search query for monitoring
    logger.info(f"Search query received: {query}")
    
    # This endpoint is intentionally vulnerable to test WAF SQL injection rules
    return jsonify({
        'query': query,
        'results': [
            {'id': 1, 'title': 'Sample Result 1', 'description': 'This is a sample search result'},
            {'id': 2, 'title': 'Sample Result 2', 'description': 'Another sample result'},
            {'id': 3, 'title': 'Sample Result 3', 'description': 'Yet another result'}
        ],
        'total_results': 3,
        'timestamp': datetime.utcnow().isoformat(),
        **INSTANCE_METADATA
    })

@app.route('/comment', methods=['POST'])
def comment():
    """Comment endpoint - intentionally vulnerable for WAF XSS testing"""
    try:
        data = request.get_json()
        comment_text = data.get('comment', '') if data else ''
        
        # Log the comment for monitoring
        logger.info(f"Comment received: {comment_text}")
        
        # This endpoint is intentionally vulnerable to test WAF XSS rules
        return jsonify({
            'comment': comment_text,
            'status': 'received',
            'comment_id': int(time.time()),
            'timestamp': datetime.utcnow().isoformat(),
            **INSTANCE_METADATA
        })
    except Exception as e:
        logger.error(f"Error processing comment: {e}")
        return jsonify({
            'error': 'Invalid request format',
            'timestamp': datetime.utcnow().isoformat(),
            **INSTANCE_METADATA
        }), 400

@app.route('/api/data')
def api_data():
    """Data endpoint for rate limiting tests"""
    return jsonify({
        'data': 'sample data payload',
        'timestamp': datetime.utcnow().isoformat(),
        'request_count': 1,
        **INSTANCE_METADATA
    })

@app.route('/api/file')
def api_file():
    """File endpoint for path traversal testing"""
    file_path = request.args.get('path', '')
    
    # Log the file request for monitoring
    logger.info(f"File request: {file_path}")
    
    # This endpoint is intentionally vulnerable to test WAF path traversal rules
    return jsonify({
        'requested_path': file_path,
        'status': 'file_not_found',
        'message': 'This is a demo endpoint for testing path traversal protection',
        'timestamp': datetime.utcnow().isoformat(),
        **INSTANCE_METADATA
    })

@app.route('/admin')
@app.route('/admin/')
@app.route('/admin/<path:subpath>')
def admin_area(subpath=''):
    """Admin area - should be blocked by WAF"""
    logger.warning(f"Admin area access attempt: {subpath}")
    
    return jsonify({
        'message': 'Admin area access',
        'path': f'/admin/{subpath}' if subpath else '/admin',
        'note': 'This should be blocked by WAF rules',
        'timestamp': datetime.utcnow().isoformat(),
        **INSTANCE_METADATA
    })

@app.route('/api/load-test')
def load_test():
    """Endpoint for load testing"""
    # Simulate some processing time
    processing_time = request.args.get('delay', 0)
    try:
        delay = float(processing_time)
        if delay > 0 and delay <= 5:  # Max 5 seconds delay
            time.sleep(delay)
    except:
        pass
    
    return jsonify({
        'message': 'Load test endpoint',
        'processing_delay': processing_time,
        'timestamp': datetime.utcnow().isoformat(),
        **INSTANCE_METADATA
    })

@app.route('/api/metrics')
def metrics():
    """Basic metrics endpoint"""
    return jsonify({
        'metrics': {
            'cpu_usage': 'N/A',  # Would need additional libraries for real metrics
            'memory_usage': 'N/A',
            'disk_usage': 'N/A',
            'network_io': 'N/A'
        },
        'timestamp': datetime.utcnow().isoformat(),
        **INSTANCE_METADATA
    })

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify({
        'error': 'Not Found',
        'message': 'The requested resource was not found',
        'timestamp': datetime.utcnow().isoformat(),
        **INSTANCE_METADATA
    }), 404

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    return jsonify({
        'error': 'Internal Server Error',
        'message': 'An internal server error occurred',
        'timestamp': datetime.utcnow().isoformat(),
        **INSTANCE_METADATA
    }), 500

if __name__ == '__main__':
    # Get port from environment variable or default to 8080
    port = int(os.environ.get('PORT', 8080))
    
    # Run the application
    app.run(
        host='0.0.0.0',
        port=port,
        debug=False,
        threaded=True
    )
