# Flask Web Application for AWS EC2 + ALB + WAF Demo

This Flask application runs on EC2 instances behind an Application Load Balancer and includes endpoints for testing WAF rules and load balancing functionality.

## Features

- **Interactive Web Interface**: HTML interface for testing WAF and load balancing
- **Instance Metadata**: Displays EC2 instance information
- **WAF Testing Endpoints**: Intentionally vulnerable endpoints for testing WAF rules
- **Load Balancer Testing**: Endpoints to verify load distribution
- **Health Checks**: ALB-compatible health check endpoint
- **Performance Testing**: Built-in performance testing tools

## File Structure

```
flask-app/
├── app.py              # Main Flask application
├── run.py              # Application startup script
├── requirements.txt    # Python dependencies
├── webapp.service      # Systemd service file
├── deploy.sh          # Deployment script
├── templates/
│   └── index.html     # Main web interface
└── README.md          # This file
```

## Installation

### Method 1: Manual Installation

1. **Install dependencies**:
   ```bash
   sudo yum update -y
   sudo yum install -y python3 python3-pip
   ```

2. **Install Python packages**:
   ```bash
   pip3 install -r requirements.txt
   ```

3. **Run the application**:
   ```bash
   python3 run.py
   ```

### Method 2: Using Deployment Script

1. **Make script executable**:
   ```bash
   chmod +x deploy.sh
   ```

2. **Run deployment script** (as root):
   ```bash
   sudo ./deploy.sh
   ```

### Method 3: Systemd Service

1. **Copy service file**:
   ```bash
   sudo cp webapp.service /etc/systemd/system/
   ```

2. **Enable and start service**:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable webapp
   sudo systemctl start webapp
   ```

3. **Check status**:
   ```bash
   sudo systemctl status webapp
   ```

## API Endpoints

### Health and Status
- `GET /health` - Health check endpoint (returns 200 OK)
- `GET /api/status` - Detailed status information
- `GET /api/instance-info` - EC2 instance metadata
- `GET /api/metrics` - Basic system metrics

### Testing Endpoints (Intentionally Vulnerable)
- `GET /search?q=<query>` - Search endpoint (vulnerable to SQL injection)
- `POST /comment` - Comment endpoint (vulnerable to XSS)
- `GET /api/file?path=<path>` - File endpoint (vulnerable to path traversal)
- `GET /admin` - Admin area (should be blocked by WAF)

### Load Testing
- `GET /api/data` - Data endpoint for rate limiting tests
- `GET /api/load-test?delay=<seconds>` - Load testing with optional delay

## Testing WAF Rules

The application includes several endpoints designed to test WAF protection:

### SQL Injection Testing
```bash
curl "http://your-alb-dns/search?q=' OR 1=1 --"
```

### XSS Testing
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"comment":"<script>alert(\"XSS\")</script>"}' \
  http://your-alb-dns/comment
```

### Path Traversal Testing
```bash
curl "http://your-alb-dns/api/file?path=../../../etc/passwd"
```

### Bad User Agent Testing
```bash
curl -H "User-Agent: badbot" http://your-alb-dns/api/status
```

### Admin Path Testing
```bash
curl http://your-alb-dns/admin
```

### Rate Limiting Testing
```bash
for i in {1..100}; do curl http://your-alb-dns/api/data & done
```

## Testing Load Balancing

### Multiple Requests to See Distribution
```bash
for i in {1..10}; do
  curl -s http://your-alb-dns/api/instance-info | jq .instance_id
done
```

### Health Check Testing
```bash
curl http://your-alb-dns/health
```

## Web Interface

Access the web interface at `http://your-alb-dns/` to use the interactive testing tools:

- **Instance Information**: View current EC2 instance details
- **WAF Testing**: Click buttons to test various attack patterns
- **Load Balancer Testing**: Test traffic distribution
- **Performance Testing**: Run performance and load tests

## Configuration

### Environment Variables
- `PORT`: Application port (default: 8080)
- `HOST`: Bind address (default: 0.0.0.0)
- `DEBUG`: Enable debug mode (default: False)

### Systemd Service Configuration
Edit `/etc/systemd/system/webapp.service` to modify:
- User/Group
- Working directory
- Environment variables
- Restart policies

## Monitoring

### Application Logs
```bash
# Systemd logs
sudo journalctl -u webapp -f

# Application logs (if using file logging)
tail -f /var/log/webapp.log
```

### Service Status
```bash
sudo systemctl status webapp
```

### Process Information
```bash
ps aux | grep python3
netstat -tlnp | grep :8080
```

## Troubleshooting

### Common Issues

1. **Port 8080 already in use**:
   ```bash
   sudo lsof -i :8080
   sudo kill -9 <PID>
   ```

2. **Permission denied**:
   ```bash
   sudo chown -R ec2-user:ec2-user /opt/flask-app
   ```

3. **Service won't start**:
   ```bash
   sudo journalctl -u webapp --no-pager
   ```

4. **Dependencies missing**:
   ```bash
   pip3 install -r requirements.txt --user
   ```

### Health Check Verification
```bash
# Local health check
curl http://localhost:8080/health

# External health check (from ALB)
curl http://your-alb-dns/health
```

## Security Notes

⚠️ **Important**: This application contains intentionally vulnerable endpoints for WAF testing purposes. Do not use in production without removing or securing these endpoints:

- `/search` - SQL injection vulnerable
- `/comment` - XSS vulnerable  
- `/api/file` - Path traversal vulnerable
- `/admin` - Should be blocked by WAF

## Integration with Infrastructure

This Flask application is designed to work with:
- **Application Load Balancer**: Health checks on `/health` endpoint
- **Auto Scaling Group**: Automatic instance management
- **WAF**: Protection against malicious requests
- **CloudWatch**: Logging and monitoring integration

The application automatically detects EC2 metadata and displays instance information to help verify load balancing functionality.
