#!/bin/bash

# Update system
yum update -y

# Install required packages
yum install -y httpd python3 python3-pip

# Install Python packages for web server
pip3 install flask requests

# Get instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

# Create a simple web application
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>EC2 + ALB + WAF Demo</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f0f0; }
        .container { background-color: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { color: #232f3e; border-bottom: 2px solid #ff9900; padding-bottom: 10px; }
        .info { margin: 20px 0; }
        .info-item { margin: 10px 0; padding: 10px; background-color: #f8f9fa; border-left: 4px solid #ff9900; }
        .test-section { margin-top: 30px; padding: 20px; background-color: #e8f4fd; border-radius: 5px; }
        button { background-color: #ff9900; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; margin: 5px; }
        button:hover { background-color: #e88b00; }
        #results { margin-top: 20px; padding: 10px; background-color: #f8f9fa; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="header">🚀 AWS EC2 + ALB + WAF Demo</h1>
        
        <div class="info">
            <div class="info-item"><strong>Instance ID:</strong> $INSTANCE_ID</div>
            <div class="info-item"><strong>Availability Zone:</strong> $AZ</div>
            <div class="info-item"><strong>Private IP:</strong> $PRIVATE_IP</div>
            <div class="info-item"><strong>Timestamp:</strong> <span id="timestamp"></span></div>
        </div>

        <div class="test-section">
            <h3>🔒 WAF Testing</h3>
            <p>Test the WAF protection by trying these potentially malicious requests:</p>
            <button onclick="testSQLInjection()">Test SQL Injection</button>
            <button onclick="testXSS()">Test XSS</button>
            <button onclick="testRateLimiting()">Test Rate Limiting</button>
            <button onclick="testNormalRequest()">Normal Request</button>
            <div id="results"></div>
        </div>

        <div class="test-section">
            <h3>⚖️ Load Balancer Testing</h3>
            <p>Refresh this page multiple times to see different instances serving requests.</p>
            <button onclick="location.reload()">Refresh Page</button>
            <button onclick="makeMultipleRequests()">Make 10 Requests</button>
        </div>
    </div>

    <script>
        // Update timestamp
        document.getElementById('timestamp').textContent = new Date().toLocaleString();

        function testSQLInjection() {
            fetch('/search?q=\' OR 1=1 --')
                .then(response => response.text())
                .then(data => updateResults('SQL Injection Test', data))
                .catch(error => updateResults('SQL Injection Test', 'Error: ' + error));
        }

        function testXSS() {
            fetch('/comment', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({comment: '<script>alert("XSS")</script>'})
            })
                .then(response => response.text())
                .then(data => updateResults('XSS Test', data))
                .catch(error => updateResults('XSS Test', 'Error: ' + error));
        }

        function testRateLimiting() {
            const promises = [];
            for (let i = 0; i < 100; i++) {
                promises.push(fetch('/api/data'));
            }
            Promise.allSettled(promises)
                .then(results => {
                    const blocked = results.filter(r => r.value && r.value.status === 403).length;
                    updateResults('Rate Limiting Test', \`Made 100 requests, \${blocked} were blocked\`);
                });
        }

        function testNormalRequest() {
            fetch('/api/status')
                .then(response => response.json())
                .then(data => updateResults('Normal Request', JSON.stringify(data, null, 2)))
                .catch(error => updateResults('Normal Request', 'Error: ' + error));
        }

        function makeMultipleRequests() {
            const results = [];
            const promises = [];
            
            for (let i = 0; i < 10; i++) {
                promises.push(
                    fetch('/api/instance-info')
                        .then(response => response.json())
                        .then(data => data.instance_id)
                );
            }
            
            Promise.all(promises)
                .then(instanceIds => {
                    const counts = {};
                    instanceIds.forEach(id => counts[id] = (counts[id] || 0) + 1);
                    updateResults('Load Balancer Test', 'Instance distribution: ' + JSON.stringify(counts, null, 2));
                });
        }

        function updateResults(testName, result) {
            const resultsDiv = document.getElementById('results');
            resultsDiv.innerHTML = \`<strong>\${testName}:</strong><br><pre>\${result}</pre>\`;
        }
    </script>
</body>
</html>
EOF

# Create Flask application for API endpoints
cat > /opt/webapp.py << 'EOF'
from flask import Flask, jsonify, request
import json
import requests
import os

app = Flask(__name__)

# Get instance metadata
def get_instance_metadata():
    try:
        instance_id = requests.get('http://169.254.169.254/latest/meta-data/instance-id', timeout=2).text
        az = requests.get('http://169.254.169.254/latest/meta-data/placement/availability-zone', timeout=2).text
        private_ip = requests.get('http://169.254.169.254/latest/meta-data/local-ipv4', timeout=2).text
        return {
            'instance_id': instance_id,
            'availability_zone': az,
            'private_ip': private_ip
        }
    except:
        return {
            'instance_id': 'unknown',
            'availability_zone': 'unknown',
            'private_ip': 'unknown'
        }

@app.route('/api/status')
def status():
    return jsonify({
        'status': 'healthy',
        'service': 'ec2-alb-waf-demo',
        **get_instance_metadata()
    })

@app.route('/api/instance-info')
def instance_info():
    return jsonify(get_instance_metadata())

@app.route('/search')
def search():
    query = request.args.get('q', '')
    # This endpoint is intentionally vulnerable for WAF testing
    return jsonify({
        'query': query,
        'results': ['result1', 'result2', 'result3'],
        **get_instance_metadata()
    })

@app.route('/comment', methods=['POST'])
def comment():
    data = request.get_json()
    comment = data.get('comment', '') if data else ''
    # This endpoint is intentionally vulnerable for WAF testing
    return jsonify({
        'comment': comment,
        'status': 'received',
        **get_instance_metadata()
    })

@app.route('/api/data')
def api_data():
    return jsonify({
        'data': 'sample data',
        'timestamp': str(requests.get('http://worldtimeapi.org/api/timezone/UTC').json().get('datetime', 'unknown')),
        **get_instance_metadata()
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Start Flask application
nohup python3 /opt/webapp.py > /var/log/webapp.log 2>&1 &

# Create a systemd service for the Flask app
cat > /etc/systemd/system/webapp.service << EOF
[Unit]
Description=Demo Web Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt
ExecStart=/usr/bin/python3 /opt/webapp.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable webapp
systemctl start webapp

# Configure log rotation
cat > /etc/logrotate.d/webapp << EOF
/var/log/webapp.log {
    daily
    missingok
    rotate 7
    compress
    notifempty
    create 644 ec2-user ec2-user
}
EOF

echo "User data script completed successfully" >> /var/log/user-data.log
