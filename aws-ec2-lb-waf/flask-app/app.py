#!/usr/bin/env python3
"""
Flask Web Application for AWS EC2 + ALB + WAF Demo
This application runs on EC2 instances behind an Application Load Balancer
and includes endpoints for testing WAF rules and load balancing functionality.

=== AWS DEPLOYMENT REQUIREMENTS ===

REQUIRED ENVIRONMENT VARIABLES:
1. PORT (optional) - Default: 8080
   - The port the Flask application will listen on
   - Set via environment variable: export PORT=8080
   - Used by ALB health checks and target group configuration

2. SECRET_KEY (CRITICAL for production)
   - Currently hardcoded as 'demo-secret-key-change-in-production'
   - MUST be changed for production deployment
   - Set via environment variable: export SECRET_KEY='your-secure-random-key'
   - Used for session management and CSRF protection

3. DEBUG (optional) - Default: False
   - Controls Flask debug mode
   - Set via environment variable: export DEBUG=False
   - Should ALWAYS be False in production

REQUIRED AWS INFRASTRUCTURE:
1. EC2 Instance Requirements:
   - Amazon Linux 2 or Ubuntu 18.04+ recommended
   - Python 3.7+ installed
   - pip3 for package management
   - Internet access for package installation
   - Security group allowing inbound traffic on port 8080 from ALB
   - IAM role with EC2 metadata access (automatically available)

2. Application Load Balancer (ALB) Configuration:
   - Target group pointing to EC2 instances on port 8080
   - Health check path: /health
   - Health check protocol: HTTP
   - Health check port: 8080
   - Healthy threshold: 2
   - Unhealthy threshold: 2
   - Timeout: 5 seconds
   - Interval: 30 seconds

3. AWS WAF Configuration:
   - Web ACL associated with the ALB
   - Rules to test: SQL injection, XSS, path traversal, admin access
   - Rate limiting rules for /api/data endpoint

4. EC2 Instance Metadata Service (IMDS):
   - Application automatically fetches instance metadata
   - No additional configuration needed
   - Provides: instance-id, AZ, private IP, public IP, instance type

REQUIRED SYSTEM PACKAGES:
- python3 (3.7+)
- python3-pip
- systemd (for service management)

REQUIRED PYTHON PACKAGES (see requirements.txt):
- Flask==2.3.3
- requests==2.31.0
- Additional dependencies listed in requirements.txt

DEPLOYMENT DIRECTORIES:
- Application files: /opt/flask-app/
- Service file: /etc/systemd/system/webapp.service
- Logs: journalctl -u webapp

NETWORK REQUIREMENTS:
- Outbound HTTPS (443) for package installation
- Outbound HTTP (80) for metadata service (169.254.169.254)
- Inbound HTTP (8080) from ALB security group
- DNS resolution for package repositories

SECURITY CONSIDERATIONS:
- Application runs as 'ec2-user' (non-root)
- Security headers automatically added to all responses
- Intentionally vulnerable endpoints for WAF testing (/search, /comment, /api/file, /admin)
- These vulnerable endpoints should be protected by WAF rules in production
"""

from flask import Flask, jsonify, request, render_template
import requests
import json
import time
import os
import logging
from datetime import datetime

# =============================================================================
# ENVIRONMENT VARIABLES SETUP
# =============================================================================

# Optional: Load environment variables from .env file for development
# Uncomment the following lines if you want to use python-dotenv:
# try:
#     from dotenv import load_dotenv
#     load_dotenv()  # This loads variables from .env file
# except ImportError:
#     pass  # python-dotenv not installed, use system environment variables

# =============================================================================
# LOGGING CONFIGURATION
# =============================================================================

# Configure logging level from environment variable
log_level = os.environ.get('LOG_LEVEL', 'INFO').upper()
logging.basicConfig(
    level=getattr(logging, log_level, logging.INFO),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# =============================================================================
# FLASK APPLICATION SETUP
# =============================================================================

app = Flask(__name__, static_folder='static', static_url_path='/static')

# =============================================================================
# ENVIRONMENT VARIABLES CONFIGURATION
# =============================================================================

# SECRET_KEY - CRITICAL for production security
# How to set: export SECRET_KEY='your-super-secure-random-key'
# Generate secure key: python3 -c "import secrets; print(secrets.token_hex(32))"
# Used for: Session management, CSRF protection, secure cookies
# Default: Insecure demo key (MUST change for production)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'demo-secret-key-change-in-production')

# DEBUG - Flask debug mode
# How to set: export DEBUG=False
# Values: True/False (case insensitive)
# Production: MUST be False for security
# Development: Can be True for debugging
app.config['DEBUG'] = os.environ.get('DEBUG', 'False').lower() == 'true'

# MAX_CONTENT_LENGTH - Maximum request size
# How to set: export MAX_CONTENT_LENGTH=16777216
# Value: Size in bytes (default: 16MB)
# Purpose: Prevent large request attacks
app.config['MAX_CONTENT_LENGTH'] = int(os.environ.get('MAX_CONTENT_LENGTH', 16 * 1024 * 1024))

# ENVIRONMENT - Deployment environment identifier
# How to set: export ENVIRONMENT=production
# Values: development, staging, production
# Purpose: Environment-specific behavior and logging
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'production')

# AWS_REGION - AWS region for deployment
# How to set: export AWS_REGION=us-east-1
# Purpose: CloudWatch logging, AWS service calls
AWS_REGION = os.environ.get('AWS_REGION', 'us-east-1')

# RATE_LIMIT_ENABLED - Application-level rate limiting
# How to set: export RATE_LIMIT_ENABLED=False
# Values: True/False
# Purpose: Additional rate limiting beyond WAF
RATE_LIMIT_ENABLED = os.environ.get('RATE_LIMIT_ENABLED', 'False').lower() == 'true'

# =============================================================================
# SECURITY CONFIGURATIONS
# =============================================================================

# Static file caching (1 year for performance)
app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 31536000

# Log configuration summary
logger.info(f"  Application starting with configuration:")
logger.info(f"  Environment: {ENVIRONMENT}")
logger.info(f"  Debug Mode: {app.config['DEBUG']}")
logger.info(f"  AWS Region: {AWS_REGION}")
logger.info(f"  Rate Limiting: {RATE_LIMIT_ENABLED}")
logger.info(f"  Max Content Length: {app.config['MAX_CONTENT_LENGTH']} bytes")

# Warn about insecure configuration
if app.config['SECRET_KEY'] == 'demo-secret-key-change-in-production':
    logger.warning("WARNING: Using default SECRET_KEY! Change this for production!")
    logger.warning("Generate secure key: python3 -c \"import secrets; print(secrets.token_hex(32))\"")

if app.config['DEBUG'] and ENVIRONMENT == 'production':
    logger.error("ERROR: Debug mode is enabled in production environment!")
    logger.error("Set DEBUG=False for production deployment")

def get_instance_metadata():
    """
    Get EC2 instance metadata from AWS Instance Metadata Service (IMDS)
    
    AWS REQUIREMENTS:
    - EC2 instance must have access to IMDS (enabled by default)
    - No additional IAM permissions required for basic metadata
    - Network access to 169.254.169.254 (link-local address)
    - IMDS version 1 or 2 supported
    
    METADATA ENDPOINTS USED:
    - http://169.254.169.254/latest/meta-data/instance-id
    - http://169.254.169.254/latest/meta-data/placement/availability-zone
    - http://169.254.169.254/latest/meta-data/local-ipv4
    - http://169.254.169.254/latest/meta-data/public-ipv4 (if instance has public IP)
    - http://169.254.169.254/latest/meta-data/instance-type
    
    FALLBACK BEHAVIOR:
    - If metadata service is unavailable (local development), returns 'unknown' values
    - Application continues to function without metadata
    """
    try:
        # Instance ID - Unique identifier for the EC2 instance
        instance_id = requests.get(
            'http://169.254.169.254/latest/meta-data/instance-id', 
            timeout=2
        ).text
        
        # Availability Zone - AWS AZ where instance is running
        az = requests.get(
            'http://169.254.169.254/latest/meta-data/placement/availability-zone', 
            timeout=2
        ).text
        
        # Private IP - VPC private IP address assigned to instance
        private_ip = requests.get(
            'http://169.254.169.254/latest/meta-data/local-ipv4', 
            timeout=2
        ).text
        
        # Public IP - Elastic IP or auto-assigned public IP (if available)
        try:
            public_ip = requests.get(
                'http://169.254.169.254/latest/meta-data/public-ipv4', 
                timeout=2
            ).text
        except:
            public_ip = 'N/A'  # Instance may not have public IP
        
        # Instance type - EC2 instance size (t3.micro, m5.large, etc.)
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
            'region': az[:-1] if az != 'unknown' else 'unknown'  # Extract region from AZ
        }
    except Exception as e:
        logger.error(f"Error getting instance metadata: {e}")
        # Return fallback values for local development or metadata service issues
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

@app.before_request
def add_security_headers():
    """Add security headers to all responses"""
    pass

@app.after_request
def after_request(response):
    """Add security headers after each request"""
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    return response

@app.route('/')
def index():
    """Main page with testing interface"""
    return render_template('index.html', metadata=INSTANCE_METADATA)

@app.route('/health')
def health():
    """
    Health check endpoint for ALB Target Group
    
    ALB CONFIGURATION REQUIREMENTS:
    - Target Group Health Check Path: /health
    - Health Check Protocol: HTTP
    - Health Check Port: 8080 (or whatever PORT env var is set to)
    - Success Codes: 200
    - Healthy Threshold: 2 consecutive successful checks
    - Unhealthy Threshold: 2 consecutive failed checks
    - Timeout: 5 seconds
    - Interval: 30 seconds
    - Grace Period: 300 seconds (for initial instance startup)
    
    RESPONSE FORMAT:
    - Always returns HTTP 200 status
    - JSON response with instance metadata
    - Used by ALB to determine instance health
    """
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
    """
    Search endpoint - intentionally vulnerable for WAF testing
    
    WAF RULE TESTING:
    - Tests SQL injection protection
    - Example malicious queries: ' OR 1=1--, UNION SELECT * FROM users
    - WAF should block requests containing SQL injection patterns
    - AWS Managed Rule Group: AWSManagedRulesCommonRuleSet
    - Specific rules: SQLiQueryArguments, SQLiBody
    
    SECURITY NOTE:
    - This endpoint is intentionally vulnerable for demonstration
    - In production, input validation and parameterized queries should be used
    - WAF provides the first line of defense against SQL injection
    """
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
    """
    Comment endpoint - intentionally vulnerable for WAF XSS testing
    
    WAF RULE TESTING:
    - Tests Cross-Site Scripting (XSS) protection
    - Example malicious payloads: <script>alert('XSS')</script>, javascript:alert(1)
    - WAF should block requests containing XSS patterns
    - AWS Managed Rule Group: AWSManagedRulesCommonRuleSet
    - Specific rules: XSSQueryArguments, XSSBody
    
    SECURITY NOTE:
    - This endpoint is intentionally vulnerable for demonstration
    - In production, input sanitization and output encoding should be used
    - WAF provides protection against common XSS attack vectors
    """
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
    """
    Data endpoint for rate limiting tests
    
    WAF RATE LIMITING CONFIGURATION:
    - Should be configured with rate-based rule
    - Example: Block IP addresses making more than 100 requests per 5 minutes
    - Rule type: Rate-based rule
    - Rate limit: 100 requests per 5-minute window
    - Action: Block or Count (for testing)
    - Scope: IP address
    
    CLOUDWATCH METRICS:
    - Monitor AllowedRequests and BlockedRequests metrics
    - Set up alarms for unusual traffic patterns
    - Use AWS WAF logs for detailed analysis
    """
    return jsonify({
        'data': 'sample data payload',
        'timestamp': datetime.utcnow().isoformat(),
        'request_count': 1,
        **INSTANCE_METADATA
    })

@app.route('/api/file')
def api_file():
    """
    File endpoint for path traversal testing
    
    WAF RULE TESTING:
    - Tests path traversal attack protection
    - Example malicious paths: ../../../etc/passwd, ..\\..\\windows\\system32
    - WAF should block requests containing directory traversal patterns
    - AWS Managed Rule Group: AWSManagedRulesUnixRuleSet or AWSManagedRulesWindowsRuleSet
    - Specific rules: UNIXShellCommandsVariables, WindowsShellCommandsVariables
    
    SECURITY NOTE:
    - This endpoint is intentionally vulnerable for demonstration
    - In production, validate and sanitize file paths
    - Use allowlists for permitted file access patterns
    """
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
    """
    Admin area - should be blocked by WAF
    
    WAF RULE CONFIGURATION:
    - Create custom rule to block access to /admin paths
    - Rule type: String match condition
    - Match type: Starts with
    - Value to match: /admin
    - Action: Block
    - Priority: High (lower number = higher priority)
    
    ALTERNATIVE APPROACHES:
    - Use AWS Managed Rule Group: AWSManagedRulesAdminProtectionRuleSet
    - Implement IP allowlist for admin access
    - Use AWS Cognito for authentication before reaching this endpoint
    
    MONITORING:
    - Set up CloudWatch alarms for blocked admin access attempts
    - Log all admin access attempts for security analysis
    """
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
    """
    Application startup configuration
    
    ENVIRONMENT VARIABLES USED:
    
    1. PORT - Port number for the application
       How to set: export PORT=8080
       Default: 8080
       Requirements:
       * Must match ALB target group port configuration
       * Must match EC2 security group inbound rules
       * Must be available and not in use by other services
    
    2. HOST - Interface to bind to
       How to set: export HOST=0.0.0.0
       Default: 0.0.0.0 (all interfaces)
       Options:
       * 0.0.0.0 - Accept connections from anywhere (production)
       * 127.0.0.1 - Local connections only (development)
    
    3. All other environment variables are loaded at application startup
       See the configuration section above for complete list
    
    PRODUCTION DEPLOYMENT METHODS:
    
    Method 1: Direct environment variables
    $ export SECRET_KEY='your-secure-key'
    $ export DEBUG=False
    $ export PORT=8080
    $ python3 run.py
    
    Method 2: Using .env file
    $ cp .env.example .env
    $ nano .env  # Edit values
    $ source .env
    $ python3 run.py
    
    Method 3: Systemd service with environment file
    $ sudo cp webapp.service /etc/systemd/system/
    $ sudo systemctl daemon-reload
    $ sudo systemctl enable webapp
    $ sudo systemctl start webapp
    
    SYSTEMD SERVICE CONFIGURATION:
    - Service file: /etc/systemd/system/webapp.service
    - Environment file: /opt/flask-app/.env
    - Runs as ec2-user (non-root)
    - Automatic restart on failure
    - Logs to systemd journal: journalctl -u webapp -f
    
    ALB HEALTH CHECK REQUIREMENTS:
    - Endpoint: /health
    - Protocol: HTTP
    - Port: Same as PORT environment variable
    - Expected response: HTTP 200 with JSON payload
    - Timeout: 5 seconds
    - Healthy threshold: 2 consecutive successes
    - Unhealthy threshold: 2 consecutive failures
    - Grace period: 300 seconds for initial startup
    """
    
    # =============================================================================
    # STARTUP ENVIRONMENT VARIABLES
    # =============================================================================
    
    # PORT - Application port
    # How to set: export PORT=8080
    port = int(os.environ.get('PORT', 8080))
    
    # HOST - Bind interface
    # How to set: export HOST=0.0.0.0
    host = os.environ.get('HOST', '0.0.0.0')
    
    # REQUEST_TIMEOUT - Request timeout in seconds
    # How to set: export REQUEST_TIMEOUT=30
    request_timeout = int(os.environ.get('REQUEST_TIMEOUT', 30))
    
    # =============================================================================
    # STARTUP VALIDATION
    # =============================================================================
    
    # Validate port range
    if not (1 <= port <= 65535):
        logger.error(f"Invalid port number: {port}. Must be between 1 and 65535.")
        exit(1)
    
    # Validate host format
    if host not in ['0.0.0.0', '127.0.0.1', 'localhost'] and not host.replace('.', '').isdigit():
        logger.warning(f"Unusual host configuration: {host}")
    
    # =============================================================================
    # STARTUP LOGGING
    # =============================================================================
    
    logger.info("=" * 60)
    logger.info("Flask Application Starting")
    logger.info("=" * 60)
    logger.info(f"Environment: {ENVIRONMENT}")
    logger.info(f"Host: {host}")
    logger.info(f"Port: {port}")
    logger.info(f"Debug Mode: {app.config['DEBUG']}")
    logger.info(f"AWS Region: {AWS_REGION}")
    logger.info(f"Request Timeout: {request_timeout}s")
    logger.info(f"Instance Metadata: {INSTANCE_METADATA}")
    logger.info("=" * 60)
    
    # =============================================================================
    # SECURITY WARNINGS
    # =============================================================================
    
    if app.config['DEBUG']:
        logger.warning("⚠️  DEBUG MODE IS ENABLED - Not suitable for production!")
    
    if app.config['SECRET_KEY'] == 'demo-secret-key-change-in-production':
        logger.warning("⚠️  USING DEFAULT SECRET_KEY - Change for production!")
    
    if host == '0.0.0.0':
        logger.info("✅ Application will accept connections from all interfaces (production mode)")
    else:
        logger.info(f"🔒 Application will only accept connections from {host}")
    
    # =============================================================================
    # START APPLICATION
    # =============================================================================
    
    try:
        # Run the Flask application
        app.run(
            host=host,           # Interface from environment variable
            port=port,           # Port from environment variable
            debug=False,         # Always False for security (use DEBUG env var for app logic)
            threaded=True,       # Enable threading for concurrent requests
            use_reloader=False   # Disable reloader in production
        )
    except KeyboardInterrupt:
        logger.info("Application stopped by user")
    except Exception as e:
        logger.error(f"Failed to start application: {e}")
        exit(1)
