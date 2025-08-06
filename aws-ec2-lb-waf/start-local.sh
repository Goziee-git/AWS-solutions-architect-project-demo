#!/bin/bash

# AWS EC2 + ALB + WAF Demo - Local Startup Script
# This script sets up and runs the Flask application locally

set -e

echo "🚀 AWS EC2 + ALB + WAF Demo - Local Startup"
echo "=========================================="

# Check if we're in the right directory
if [ ! -f "flask-app/app.py" ]; then
    echo "❌ Error: Please run this script from the aws-ec2-lb-waf directory"
    echo "Current directory: $(pwd)"
    exit 1
fi

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is not installed or not in PATH"
    exit 1
fi

echo "✅ Python 3 found: $(python3 --version)"

# Create virtual environment if it doesn't exist
if [ ! -d "aws-ec2-venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv aws-ec2-venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source aws-ec2-venv/bin/activate

# Install dependencies
echo "📥 Installing dependencies..."
cd flask-app
pip install -q -r requirements.txt

# Check if port 8080 is available
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  Warning: Port 8080 is already in use"
    echo "   You can access the existing application at http://localhost:8080"
    echo "   Or kill the existing process and run this script again"
    exit 1
fi

echo "🌐 Starting Flask application..."
echo "   Local URL: http://localhost:8080"
echo "   Network URL: http://$(hostname -I | awk '{print $1}'):8080"
echo ""
echo "📝 Application Features:"
echo "   • Instance information display"
echo "   • WAF rule testing endpoints"
echo "   • Load balancer simulation"
echo "   • Performance testing tools"
echo ""
echo "Press Ctrl+C to stop the application"
echo "=========================================="

# Start the application
python app.py
