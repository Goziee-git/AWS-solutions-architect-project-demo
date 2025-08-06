# Local Development Guide - AWS EC2 + ALB + WAF Demo

This guide provides detailed steps to run the Flask web application locally for development and testing purposes.

## 📋 Prerequisites

Before running the application locally, ensure you have the following installed:

- **Python 3.8+** (Check with `python3 --version`)
- **pip** (Python package installer)
- **Git** (for version control)
- **curl** or **wget** (for testing endpoints)

## 🚀 Quick Start

### Option 1: Using the Startup Script (Recommended)

```bash
# Navigate to project directory
cd aws-ec2-lb-waf

# Run the startup script
./start-local.sh
```

This script will automatically:
- Check prerequisites
- Create and activate virtual environment
- Install dependencies
- Start the Flask application
- Display helpful information

### Option 2: Manual Setup

#### 1. Clone and Navigate to Project

```bash
# If not already in the project directory
cd /path/to/AWS-solutions-architect-project-demo/aws-ec2-lb-waf
```

#### 2. Create Virtual Environment

```bash
# Create virtual environment
python3 -m venv aws-ec2-venv

# Activate virtual environment
source aws-ec2-venv/bin/activate

# Verify activation (should show virtual environment path)
which python
```

#### 3. Install Dependencies

```bash
# Navigate to flask-app directory
cd flask-app

# Install required packages
pip install -r requirements.txt

# Verify installation
pip list
```

#### 4. Run the Application

```bash
# Method 1: Using Python directly
python app.py

# Method 2: Using the run script
python run.py

# Method 3: Using Flask command
export FLASK_APP=app.py
flask run --host=0.0.0.0 --port=8080
```

### 5. Access the Application

Open your web browser and navigate to:
- **Local Access**: http://localhost:8080
- **Network Access**: http://YOUR_IP:8080

## 📁 Project Structure

```
aws-ec2-lb-waf/
├── flask-app/                 # Main application directory
│   ├── app.py                # Flask application
│   ├── run.py                # Application runner script
│   ├── requirements.txt      # Python dependencies
│   ├── templates/            # HTML templates
│   │   └── index.html       # Main web interface
│   └── README.md            # Flask app documentation
├── aws-ec2-venv/             # Virtual environment (auto-created)
├── infrastructure/           # Terraform files for AWS deployment
├── scripts/                  # Utility scripts
├── tests/                    # Test files
└── local-run-README.md      # This file
```

## 🔧 Configuration Options

### Environment Variables

You can customize the application behavior using environment variables:

```bash
# Set custom port (default: 8080)
export PORT=5000

# Enable debug mode (not recommended for production)
export FLASK_DEBUG=1

# Set Flask environment
export FLASK_ENV=development
```

### Running with Custom Configuration

```bash
# Run on custom port
PORT=5000 python app.py

# Run with debug enabled
FLASK_DEBUG=1 python app.py

# Run with both custom port and debug
PORT=5000 FLASK_DEBUG=1 python app.py
```

## 🧪 Testing the Application

### 1. Automated Testing

```bash
# Run the built-in test script
cd flask-app
python test_local.py
```

This will automatically:
- Start the Flask application
- Test all endpoints
- Display results
- Keep the server running for manual testing

### 2. Basic Functionality Test

```bash
# Test health endpoint
curl http://localhost:8080/health

# Test API status
curl http://localhost:8080/api/status

# Test instance info
curl http://localhost:8080/api/instance-info
```

### 2. WAF Testing Endpoints

```bash
# Test search endpoint (SQL injection simulation)
curl "http://localhost:8080/search?q=test"

# Test comment endpoint (XSS simulation)
curl -X POST http://localhost:8080/comment \
  -H "Content-Type: application/json" \
  -d '{"comment": "This is a test comment"}'

# Test file endpoint (path traversal simulation)
curl "http://localhost:8080/api/file?path=test.txt"

# Test admin area (should be accessible locally)
curl http://localhost:8080/admin
```

### 3. Load Testing Endpoints

```bash
# Test load endpoint
curl http://localhost:8080/api/load-test

# Test with delay
curl "http://localhost:8080/api/load-test?delay=2"

# Test metrics endpoint
curl http://localhost:8080/api/metrics
```

### 4. Web Interface Testing

1. Open http://localhost:8080 in your browser
2. Use the web interface to test various endpoints
3. Check the "Instance Information" section
4. Test WAF simulation buttons
5. Test load balancer simulation buttons
6. Test performance testing buttons

## 🐛 Troubleshooting

### Common Issues and Solutions

#### 1. Port Already in Use

```bash
# Error: Address already in use
# Solution: Use a different port
PORT=8081 python app.py

# Or kill the process using the port
sudo lsof -ti:8080 | xargs kill -9
```

#### 2. Module Not Found Error

```bash
# Error: ModuleNotFoundError: No module named 'flask'
# Solution: Ensure virtual environment is activated and dependencies installed
source aws-ec2-venv/bin/activate
pip install -r requirements.txt
```

#### 3. Permission Denied

```bash
# Error: Permission denied on port 80 or 443
# Solution: Use port > 1024 or run with sudo (not recommended)
PORT=8080 python app.py
```

#### 4. Virtual Environment Issues

```bash
# Deactivate current environment
deactivate

# Remove and recreate virtual environment
rm -rf aws-ec2-venv
python3 -m venv aws-ec2-venv
source aws-ec2-venv/bin/activate
pip install -r flask-app/requirements.txt
```

### 5. Instance Metadata Not Available

When running locally, AWS EC2 instance metadata is not available. The application handles this gracefully by showing:
- Instance ID: "unknown"
- Availability Zone: "unknown"
- Private IP: "unknown"
- Public IP: "unknown"

This is expected behavior for local development.

## 🔍 Development Tips

### 1. Code Changes and Hot Reload

For development with automatic reloading:

```bash
# Enable debug mode for hot reload
export FLASK_DEBUG=1
python app.py
```

### 2. Logging

View application logs in the terminal where you started the app. Logs include:
- Request information
- Search queries
- Comments received
- File requests
- Admin area access attempts

### 3. Testing Different Scenarios

```bash
# Test malicious payloads (safe in local environment)
curl "http://localhost:8080/search?q='; DROP TABLE users; --"
curl -X POST http://localhost:8080/comment \
  -H "Content-Type: application/json" \
  -d '{"comment": "<script>alert(\"XSS\")</script>"}'
curl "http://localhost:8080/api/file?path=../../../etc/passwd"
```

## 📊 Performance Testing

### Using curl for Load Testing

```bash
# Simple load test
for i in {1..10}; do
  curl -s http://localhost:8080/api/load-test &
done
wait

# Timed requests
time curl http://localhost:8080/api/load-test
```

### Using Apache Bench (if installed)

```bash
# Install Apache Bench
sudo apt-get install apache2-utils  # Ubuntu/Debian
brew install httpie                  # macOS

# Run load test
ab -n 100 -c 10 http://localhost:8080/api/load-test
```

## 🔒 Security Notes

### Local Development Security

- The application runs in development mode with debug disabled by default
- Static file serving is disabled to prevent accidental file exposure
- All "vulnerable" endpoints are intentionally designed for WAF testing
- Never run this application in production without proper security measures

### Production Considerations

When deploying to production:
1. Use proper WSGI server (Gunicorn, uWSGI)
2. Enable HTTPS/TLS
3. Configure proper firewall rules
4. Use environment variables for sensitive configuration
5. Enable proper logging and monitoring
6. Apply AWS WAF rules to protect against attacks

## 🛑 Stopping the Application

### Stop the Flask Application

```bash
# In the terminal where the app is running
Ctrl + C

# Or if running in background
pkill -f "python app.py"
```

### Deactivate Virtual Environment

```bash
deactivate
```

## 📚 Additional Resources

- [Flask Documentation](https://flask.palletsprojects.com/)
- [AWS WAF Documentation](https://docs.aws.amazon.com/waf/)
- [AWS Application Load Balancer Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [Python Virtual Environments Guide](https://docs.python.org/3/tutorial/venv.html)

## 🆘 Getting Help

If you encounter issues:

1. Check the troubleshooting section above
2. Verify all prerequisites are installed
3. Ensure virtual environment is properly activated
4. Check application logs for error messages
5. Verify port availability and permissions

For AWS-specific issues when deploying to production, refer to the main README.md and deployment documentation.
