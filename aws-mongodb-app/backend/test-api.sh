#!/bin/bash

echo "🧪 Testing JWT API Endpoints"
echo "=============================="

BASE_URL="http://localhost:5000"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "\n${YELLOW}1. Testing Health Check${NC}"
curl -s "$BASE_URL/health" | jq '.'

echo -e "\n${YELLOW}2. Testing User Registration${NC}"
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123",
    "firstName": "Test",
    "lastName": "User"
  }')

echo "$REGISTER_RESPONSE" | jq '.'

# Extract token from registration response
TOKEN=$(echo "$REGISTER_RESPONSE" | jq -r '.token // empty')
REFRESH_TOKEN=$(echo "$REGISTER_RESPONSE" | jq -r '.refreshToken // empty')

if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
  echo -e "\n${GREEN}✅ Registration successful! Token received.${NC}"
  
  echo -e "\n${YELLOW}3. Testing Protected Route (Get Current User)${NC}"
  curl -s -X GET "$BASE_URL/api/auth/me" \
    -H "Authorization: Bearer $TOKEN" | jq '.'
  
  if [ -n "$REFRESH_TOKEN" ] && [ "$REFRESH_TOKEN" != "null" ]; then
    echo -e "\n${YELLOW}4. Testing Token Refresh${NC}"
    curl -s -X POST "$BASE_URL/api/auth/refresh" \
      -H "Content-Type: application/json" \
      -d "{\"refreshToken\": \"$REFRESH_TOKEN\"}" | jq '.'
  fi
  
else
  echo -e "\n${RED}❌ Registration failed or user already exists${NC}"
  
  echo -e "\n${YELLOW}3. Testing Login with existing user${NC}"
  LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/login" \
    -H "Content-Type: application/json" \
    -d '{
      "email": "test@example.com",
      "password": "password123"
    }')
  
  echo "$LOGIN_RESPONSE" | jq '.'
  
  # Extract token from login response
  TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token // empty')
  
  if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
    echo -e "\n${GREEN}✅ Login successful! Token received.${NC}"
    
    echo -e "\n${YELLOW}4. Testing Protected Route (Get Current User)${NC}"
    curl -s -X GET "$BASE_URL/api/auth/me" \
      -H "Authorization: Bearer $TOKEN" | jq '.'
  else
    echo -e "\n${RED}❌ Login failed${NC}"
  fi
fi

echo -e "\n${YELLOW}5. Testing Invalid Token${NC}"
curl -s -X GET "$BASE_URL/api/auth/me" \
  -H "Authorization: Bearer invalid.token.here" | jq '.'

echo -e "\n${GREEN}🎉 API Testing Complete!${NC}"
