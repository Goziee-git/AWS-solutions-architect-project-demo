#!/bin/bash

# Deployment script for Flask application on EC2
# This script should be run as root or with sudo

set -e

echo "Starting Flask application deployment..."

# Variables
APP_DIR="/opt/flask-app"
SERVICE_NAME="webapp"
USER="ec2-user"

# Create application directory
echo "Creating application directory..."
mkdir -p $APP_DIR
chown $USER:$USER $APP_DIR

# Copy application files
echo "Copying application files..."
cp -r . $APP_DIR/
chown -R $USER:$USER $APP_DIR

# Install Python dependencies
echo "Installing Python dependencies..."
cd $APP_DIR
pip3 install -r requirements.txt

# Install and configure systemd service
echo "Setting up systemd service..."
cp webapp.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

# Check service status
echo "Checking service status..."
systemctl status $SERVICE_NAME --no-pager

echo "Flask application deployment completed!"
echo "Application is running on port 8080"
echo "Health check: curl http://localhost:8080/health"
