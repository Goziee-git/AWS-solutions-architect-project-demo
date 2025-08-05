#!/bin/bash

# Production Docker Build Script for Frontend
# This script builds and tests the production Docker image

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="aws-mongodb-frontend"
TAG="latest"
CONTAINER_NAME="frontend-test"
PORT="3000"

echo -e "${BLUE}🚀 Starting production build for ${IMAGE_NAME}...${NC}"

# Clean up any existing containers
echo -e "${YELLOW}🧹 Cleaning up existing containers...${NC}"
docker stop ${CONTAINER_NAME} 2>/dev/null || true
docker rm ${CONTAINER_NAME} 2>/dev/null || true

# Build the Docker image
echo -e "${BLUE}🔨 Building Docker image...${NC}"
docker build \
  --no-cache \
  --tag ${IMAGE_NAME}:${TAG} \
  --target production \
  .

# Check image size
echo -e "${BLUE}📊 Image information:${NC}"
docker images ${IMAGE_NAME}:${TAG}

# Security scan (if available)
if command -v docker &> /dev/null && docker --help | grep -q "scout"; then
    echo -e "${BLUE}🔍 Running security scan...${NC}"
    docker scout cves ${IMAGE_NAME}:${TAG} || echo -e "${YELLOW}⚠️  Docker Scout not available or failed${NC}"
fi

# Test the container
echo -e "${BLUE}🧪 Testing the container...${NC}"
docker run -d \
  --name ${CONTAINER_NAME} \
  --port ${PORT}:${PORT} \
  ${IMAGE_NAME}:${TAG}

# Wait for container to start
echo -e "${YELLOW}⏳ Waiting for container to start...${NC}"
sleep 5

# Health check
echo -e "${BLUE}🏥 Running health checks...${NC}"
if curl -f http://localhost:${PORT}/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Health check passed!${NC}"
else
    echo -e "${RED}❌ Health check failed!${NC}"
    docker logs ${CONTAINER_NAME}
    exit 1
fi

# Test main page
if curl -f http://localhost:${PORT}/ > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Main page accessible!${NC}"
else
    echo -e "${RED}❌ Main page not accessible!${NC}"
    docker logs ${CONTAINER_NAME}
    exit 1
fi

# Show container stats
echo -e "${BLUE}📈 Container stats:${NC}"
docker stats ${CONTAINER_NAME} --no-stream

# Show logs
echo -e "${BLUE}📋 Container logs:${NC}"
docker logs ${CONTAINER_NAME} --tail 20

# Clean up test container
echo -e "${YELLOW}🧹 Cleaning up test container...${NC}"
docker stop ${CONTAINER_NAME}
docker rm ${CONTAINER_NAME}

echo -e "${GREEN}🎉 Production build completed successfully!${NC}"
echo -e "${GREEN}📦 Image: ${IMAGE_NAME}:${TAG}${NC}"
echo -e "${BLUE}💡 To run the container:${NC}"
echo -e "   docker run -d -p ${PORT}:${PORT} --name frontend ${IMAGE_NAME}:${TAG}"
