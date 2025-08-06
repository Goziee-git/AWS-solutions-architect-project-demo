#!/bin/bash

# Flask Application Environment Setup Script
# This script helps you set up environment variables for the Flask application

set -e  # Exit on any error

echo "=========================================="
echo "Flask Application Environment Setup"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to generate secure secret key
generate_secret_key() {
    python3 -c "import secrets; print(secrets.token_hex(32))"
}

# Function to prompt for input with default
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    
    echo -e "${BLUE}$prompt${NC}"
    if [ -n "$default" ]; then
        echo -e "Default: ${YELLOW}$default${NC}"
    fi
    read -r input
    
    if [ -z "$input" ] && [ -n "$default" ]; then
        input="$default"
    fi
    
    eval "$var_name='$input'"
}

echo "This script will help you create a .env file for your Flask application."
echo ""

# Check if .env already exists
if [ -f ".env" ]; then
    echo -e "${YELLOW}Warning: .env file already exists!${NC}"
    echo "Do you want to:"
    echo "1) Backup existing .env and create new one"
    echo "2) Exit and manually edit existing .env"
    read -p "Choose (1 or 2): " choice
    
    case $choice in
        1)
            cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
            echo -e "${GREEN}Existing .env backed up${NC}"
            ;;
        2)
            echo "Exiting. Edit your existing .env file manually."
            exit 0
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

echo ""
echo "=== CRITICAL SECURITY SETTINGS ==="

# SECRET_KEY
echo ""
echo -e "${RED}IMPORTANT: SECRET_KEY is critical for security!${NC}"
echo "Generate a new secure key? (recommended)"
read -p "Generate new SECRET_KEY? (y/n): " generate_key

if [[ $generate_key =~ ^[Yy]$ ]]; then
    SECRET_KEY=$(generate_secret_key)
    echo -e "${GREEN}Generated secure SECRET_KEY${NC}"
else
    prompt_with_default "Enter SECRET_KEY (leave empty to generate):" "" SECRET_KEY
    if [ -z "$SECRET_KEY" ]; then
        SECRET_KEY=$(generate_secret_key)
        echo -e "${GREEN}Generated secure SECRET_KEY${NC}"
    fi
fi

# DEBUG
echo ""
prompt_with_default "Enable DEBUG mode? (True/False):" "False" DEBUG

echo ""
echo "=== APPLICATION CONFIGURATION ==="

# PORT
prompt_with_default "Application port:" "8080" PORT

# HOST
prompt_with_default "Host interface (0.0.0.0 for production, 127.0.0.1 for local):" "0.0.0.0" HOST

# ENVIRONMENT
prompt_with_default "Environment (development/staging/production):" "production" ENVIRONMENT

# AWS_REGION
prompt_with_default "AWS Region:" "us-east-1" AWS_REGION

echo ""
echo "=== LOGGING CONFIGURATION ==="

# LOG_LEVEL
prompt_with_default "Log level (DEBUG/INFO/WARNING/ERROR):" "INFO" LOG_LEVEL

echo ""
echo "=== OPTIONAL SETTINGS ==="

# RATE_LIMIT_ENABLED
prompt_with_default "Enable application-level rate limiting? (True/False):" "False" RATE_LIMIT_ENABLED

# MAX_CONTENT_LENGTH
prompt_with_default "Maximum request size in bytes:" "16777216" MAX_CONTENT_LENGTH

# REQUEST_TIMEOUT
prompt_with_default "Request timeout in seconds:" "30" REQUEST_TIMEOUT

echo ""
echo "=== CREATING .env FILE ==="

# Create .env file
cat > .env << EOF
# Flask Application Environment Variables
# Generated on $(date)

# =============================================================================
# CRITICAL PRODUCTION SETTINGS
# =============================================================================

SECRET_KEY=$SECRET_KEY
DEBUG=$DEBUG

# =============================================================================
# APPLICATION CONFIGURATION
# =============================================================================

PORT=$PORT
HOST=$HOST
ENVIRONMENT=$ENVIRONMENT
AWS_REGION=$AWS_REGION

# =============================================================================
# LOGGING CONFIGURATION
# =============================================================================

LOG_LEVEL=$LOG_LEVEL

# =============================================================================
# PERFORMANCE SETTINGS
# =============================================================================

MAX_CONTENT_LENGTH=$MAX_CONTENT_LENGTH
REQUEST_TIMEOUT=$REQUEST_TIMEOUT

# =============================================================================
# SECURITY SETTINGS
# =============================================================================

RATE_LIMIT_ENABLED=$RATE_LIMIT_ENABLED

# =============================================================================
# FLASK ENVIRONMENT
# =============================================================================

FLASK_ENV=$ENVIRONMENT
TESTING=False
EOF

# Set secure permissions
chmod 600 .env

echo -e "${GREEN}✅ .env file created successfully!${NC}"
echo ""
echo "=== NEXT STEPS ==="
echo ""
echo "1. Review the .env file:"
echo "   cat .env"
echo ""
echo "2. Test the configuration:"
echo "   source .env && python3 run.py"
echo ""
echo "3. For systemd service deployment:"
echo "   sudo cp webapp.service /etc/systemd/system/"
echo "   sudo systemctl daemon-reload"
echo "   sudo systemctl enable webapp"
echo "   sudo systemctl start webapp"
echo ""
echo "4. Monitor the service:"
echo "   sudo systemctl status webapp"
echo "   sudo journalctl -u webapp -f"
echo ""

# Security warnings
echo "=== SECURITY REMINDERS ==="
echo ""
if [ "$DEBUG" = "True" ] && [ "$ENVIRONMENT" = "production" ]; then
    echo -e "${RED}⚠️  WARNING: Debug mode is enabled in production environment!${NC}"
fi

if [ "$HOST" = "0.0.0.0" ]; then
    echo -e "${YELLOW}ℹ️  Application will accept connections from all interfaces${NC}"
else
    echo -e "${GREEN}🔒 Application will only accept local connections${NC}"
fi

echo ""
echo -e "${YELLOW}🔐 IMPORTANT SECURITY NOTES:${NC}"
echo "• Never commit .env files to version control"
echo "• .env file permissions set to 600 (owner read/write only)"
echo "• Rotate SECRET_KEY regularly in production"
echo "• Consider using AWS Systems Manager Parameter Store for production secrets"
echo ""
echo -e "${GREEN}Setup complete!${NC}"
