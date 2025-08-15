#!/bin/bash

# Test script to verify key pair creation functionality
# Usage: ./test-keypair.sh

# Source variables
source "$(dirname "$0")/variables.sh"

echo "=== Key Pair Test Script ==="
echo "Testing key pair: $KEY_PAIR_NAME"
echo "Current directory: $(pwd)"
echo ""

# Check AWS CLI
check_aws_cli

# Check current key pair status
check_key_pair

# Show current configuration
show_config

echo "=== Test completed ==="
