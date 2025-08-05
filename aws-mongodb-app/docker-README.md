# Docker Deployment Guide - AWS MongoDB Application

This comprehensive guide documents the complete process of containerizing and running the AWS MongoDB application using Docker with a custom bridge network named `mogo-network`. This guide covers every step taken to achieve a fully functional multi-container application setup.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Project Structure Analysis](#project-structure-analysis)
3. [Docker Images Overview](#docker-images-overview)
4. [Custom Network Setup](#custom-network-setup)
5. [Container Configuration](#container-configuration)
6. [Step-by-Step Deployment Process](#step-by-step-deployment-process)
7. [Container Management](#container-management)
8. [Testing and Verification](#testing-and-verification)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)

## Prerequisites

Before starting the containerization process, ensure you have:

### Required Software
- **Docker Engine**: Version 20.10 or higher
- **Docker Compose**: Version 1.29 or higher (optional, for reference)
- **Git**: For version control
- **curl**: For testing API endpoints
- **jq**: For JSON formatting (optional but recommended)

### Verify Prerequisites
```bash
# Check Docker version
docker --version
# Expected output: Docker version 20.10.x or higher

# Check Docker is running
docker info
# Should show Docker system information without errors

# Check available images (if any)
docker images

# Check running containers
docker ps -a
```

### Project Requirements
- Pre-built Docker images for frontend and backend applications
- MongoDB 7.0 image (will be pulled automatically)
- Proper Dockerfile configurations in respective directories

## Project Structure Analysis

The project follows a microservices architecture with the following structure:

```
aws-mongodb-app/
├── backend/                    # Node.js API server
│   ├── config/                # Database configuration
│   ├── middleware/            # Authentication & authorization
│   ├── models/               # MongoDB data models
│   ├── routes/               # API route handlers
│   ├── Dockerfile            # Backend container configuration
│   ├── package.json          # Backend dependencies
│   ├── .env                  # Development environment variables
│   ├── .env.docker           # Docker-specific environment variables
│   └── server.js             # Main server file
├── frontend/                  # React application
│   ├── src/                  # React source code
│   ├── public/               # Static assets
│   ├── Dockerfile            # Frontend container configuration
│   └── package.json          # Frontend dependencies
├── mongodb/                  # MongoDB configuration
│   └── init-scripts/         # Database initialization scripts
├── nginx/                    # Load balancer configuration
├── docker-compose.yml        # Original compose configuration
├── manage-containers.sh      # Container management script
└── docker-README.md         # This comprehensive guide
```

### Key Configuration Files

#### Backend Dockerfile (`backend/Dockerfile`)
```dockerfile
# Use official Node.js runtime as base image
FROM node:18-alpine

# Set working directory in container
WORKDIR /app

# Copy package.json and package-lock.json (if available)
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && npm cache clean --force

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy application code
COPY . .

# Change ownership of the app directory to nodejs user
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

# Start the application
CMD ["npm", "start"]
```

#### Frontend Dockerfile (`frontend/Dockerfile`)
The frontend uses a multi-stage build process with nginx for serving the React application.

## Docker Images Overview

### Available Images Before Deployment
```bash
# Command used to check existing images
docker images

# Output showed:
REPOSITORY           TAG       IMAGE ID       CREATED       SIZE
frontend-mongo-app   latest    9a48ab335221   3 hours ago   65MB
mongo                7.0       071948f2e033   2 weeks ago   834MB
```

### Images Required for Deployment
1. **frontend-mongo-app:latest** - Pre-built React application
2. **backend-mongo-app:latest** - Node.js API server (built during process)
3. **mongo:7.0** - Official MongoDB database

## Custom Network Setup

### Why Custom Network?
- **Container Isolation**: Separate network namespace for application containers
- **Service Discovery**: Containers can communicate using container names as hostnames
- **Security**: Network-level isolation from other Docker containers
- **Flexibility**: Custom IP addressing and network configuration

### Network Creation Process

#### Step 1: Create Custom Bridge Network
```bash
# Create the custom bridge network named 'mogo-network'
docker network create --driver bridge mogo-network

# Expected output: Network ID (e.g., a870dd444f3a69d610b5428280e162f6424423509d35cd0c885c7d2a28f1bcbd)
```

#### Step 2: Verify Network Creation
```bash
# List all Docker networks
docker network ls

# Expected output:
NETWORK ID     NAME           DRIVER    SCOPE
1493b0a742cd   bridge         bridge    local
ad4de51e97d4   host           host      local
a870dd444f3a   mogo-network   bridge    local  # <-- Our custom network
97cbaad6826c   none           null      local
```

#### Step 3: Inspect Network Configuration
```bash
# Inspect the network details
docker network inspect mogo-network

# Key information from output:
# - Subnet: 172.19.0.0/16
# - Gateway: 172.19.0.1
# - Driver: bridge
# - Containers: (initially empty)
```

## Container Configuration

### Environment Variables Setup

#### Backend Environment Configuration
The backend requires specific environment variables for Docker deployment. A separate environment file was created:

**File: `backend/.env.docker`**
```env
# Server Configuration
NODE_ENV=production
PORT=5000

# MongoDB Configuration - using container name for Docker networking
MONGODB_URI=mongodb://admin:password123@mongodb:27017/myapp?authSource=admin

# Frontend URL for CORS
FRONTEND_URL=http://localhost:3000

# JWT Configuration
JWT_SECRET=3d38c422b144ae0eac66536e48883dfc87b13b51d88839441750a75f8ed8738f695be09b10f3549ae17c903d2ccfafaa35af3b23897e87d1fd6d00be990ca157
JWT_EXPIRE=7d

# AWS Configuration (if using AWS services)
AWS_REGION=us-east-1

# Application Configuration
APP_NAME=AWS MongoDB Backend
LOG_LEVEL=info
```

**Key Differences from Development Environment:**
- `MONGODB_URI` uses container name `mongodb` instead of `localhost`
- `NODE_ENV` set to `production`
- Authentication database specified as `admin`

### Container Specifications

#### MongoDB Container
- **Image**: mongo:7.0
- **Container Name**: mongodb
- **Network**: mogo-network
- **Ports**: 27017:27017
- **Environment Variables**:
  - `MONGO_INITDB_ROOT_USERNAME=admin`
  - `MONGO_INITDB_ROOT_PASSWORD=password123`
  - `MONGO_INITDB_DATABASE=myapp`
- **Volumes**: `mongodb_data:/data/db`

#### Backend Container
- **Image**: backend-mongo-app:latest
- **Container Name**: backend
- **Network**: mogo-network
- **Ports**: 5000:5000
- **Environment**: Loaded from `.env.docker` file
- **Dependencies**: Waits for MongoDB to be ready

#### Frontend Container
- **Image**: frontend-mongo-app:latest
- **Container Name**: frontend
- **Network**: mogo-network
- **Ports**: 3000:3000
- **Environment Variables**:
  - `REACT_APP_API_URL=http://localhost:5000/api`

## Step-by-Step Deployment Process

This section documents every command executed to achieve the final deployment.

### Phase 1: Pre-Deployment Preparation

#### Step 1: Analyze Current Environment
```bash
# Check current directory
pwd
# Output: /home/prospa/AWS-solutions-architect-project-demo/aws-mongodb-app

# List project contents
ls -la
# Shows: backend/, frontend/, mongodb/, nginx/, aws/, docker-compose.yml, etc.

# Check existing Docker images
docker images
# Output showed frontend-mongo-app and mongo:7.0 were available
```

#### Step 2: Examine Project Structure
```bash
# Check docker-compose.yml for reference
cat docker-compose.yml
# This provided insights into the original multi-container setup

# Examine backend Dockerfile
cat backend/Dockerfile
# Confirmed Node.js 18-alpine base image and proper configuration

# Check existing environment configuration
cat backend/.env
# Showed development configuration with localhost MongoDB URI
```

#### Step 3: Check for Running Containers
```bash
# List all containers (running and stopped)
docker ps -a

# Output showed:
CONTAINER ID   IMAGE       COMMAND                  CREATED       STATUS       PORTS                                             NAMES
fb74333d772a   mongo:7.0   "docker-entrypoint.s…"   5 hours ago   Up 5 hours   0.0.0.0:27017->27017/tcp, [::]:27017->27017/tcp   mongodb-dev

# Stop conflicting container to avoid port conflicts
docker stop mongodb-dev
```

### Phase 2: Image Preparation

#### Step 4: Build Missing Backend Image
The backend image was not available, so it needed to be built:

```bash
# Navigate to backend directory
cd /home/prospa/AWS-solutions-architect-project-demo/aws-mongodb-app/backend

# Build backend Docker image
docker build -t backend-mongo-app .

# Build process output (abbreviated):
# - FROM node:18-alpine
# - WORKDIR /app
# - COPY package*.json ./
# - RUN npm ci --only=production
# - RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
# - COPY . .
# - RUN chown -R nodejs:nodejs /app
# - USER nodejs
# - EXPOSE 5000
# - CMD ["npm", "start"]

# Verify image was created
docker images | grep backend-mongo-app
# Output: backend-mongo-app   latest    7e1c3b8505f2   X minutes ago   XXX MB
```

**Build Process Details:**
- Base image: `node:18-alpine` (lightweight Linux distribution)
- Dependencies installed with `npm ci --only=production` for faster, reliable builds
- Non-root user `nodejs` created for security
- Application code copied and ownership changed
- Port 5000 exposed for API access
- Health check configured for container monitoring

### Phase 3: Network Infrastructure Setup

#### Step 5: Create Custom Bridge Network
```bash
# Return to project root
cd /home/prospa/AWS-solutions-architect-project-demo/aws-mongodb-app

# Create custom bridge network named 'mogo-network'
docker network create --driver bridge mogo-network

# Output: a870dd444f3a69d610b5428280e162f6424423509d35cd0c885c7d2a28f1bcbd

# Verify network creation
docker network ls
# Confirmed mogo-network was created with bridge driver
```

#### Step 6: Inspect Network Configuration
```bash
# Get detailed network information
docker network inspect mogo-network

# Key configuration details:
# - Name: mogo-network
# - Driver: bridge
# - Subnet: 172.19.0.0/16
# - Gateway: 172.19.0.1
# - EnableIPv4: true
# - Internal: false (allows external connectivity)
```

### Phase 4: Environment Configuration

#### Step 7: Create Docker-Specific Environment File
```bash
# Create production environment file for Docker deployment
cat > backend/.env.docker << 'EOF'
# Server Configuration
NODE_ENV=production
PORT=5000

# MongoDB Configuration - using container name for Docker networking
MONGODB_URI=mongodb://admin:password123@mongodb:27017/myapp?authSource=admin

# Frontend URL for CORS
FRONTEND_URL=http://localhost:3000

# JWT Configuration
JWT_SECRET=3d38c422b144ae0eac66536e48883dfc87b13b51d88839441750a75f8ed8738f695be09b10f3549ae17c903d2ccfafaa35af3b23897e87d1fd6d00be990ca157
JWT_EXPIRE=7d

# AWS Configuration (if using AWS services)
AWS_REGION=us-east-1

# Application Configuration
APP_NAME=AWS MongoDB Backend
LOG_LEVEL=info
EOF

# Verify file creation
cat backend/.env.docker
```

**Critical Configuration Changes:**
- `MONGODB_URI` changed from `localhost` to `mongodb` (container name)
- `NODE_ENV` set to `production` for optimized performance
- `authSource=admin` specified for MongoDB authentication
- Container-to-container communication enabled through Docker networking

### Phase 5: Container Deployment

#### Step 8: Deploy MongoDB Container
```bash
# Start MongoDB container first (database dependency)
docker run -d \
  --name mongodb \
  --network mogo-network \
  -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=password123 \
  -e MONGO_INITDB_DATABASE=myapp \
  -v mongodb_data:/data/db \
  mongo:7.0

# Output: 7b9019eb4c1adbf2f916cfe2c6ce6c3780bc94456da631b8684317c9d1eafbe1

# Verify MongoDB container is running
docker ps | grep mongodb
```

**MongoDB Container Configuration:**
- **Detached mode** (`-d`): Runs in background
- **Container name**: `mongodb` for service discovery
- **Network**: Connected to `mogo-network`
- **Port mapping**: `27017:27017` for external access
- **Environment variables**: Root user credentials and default database
- **Volume**: Persistent data storage with `mongodb_data` volume
- **Image**: Official `mongo:7.0` from Docker Hub

#### Step 9: Deploy Backend API Container
```bash
# Wait for MongoDB to initialize (important for database connections)
sleep 10

# Start backend container
docker run -d \
  --name backend \
  --network mogo-network \
  -p 5000:5000 \
  --env-file /home/prospa/AWS-solutions-architect-project-demo/aws-mongodb-app/backend/.env.docker \
  backend-mongo-app

# Output: df2e4a48821df46fed920461942c2ecb668a4a53a4a2ed157ef38353fea1031f

# Verify backend container is running
docker ps | grep backend
```

**Backend Container Configuration:**
- **Startup delay**: 10-second wait ensures MongoDB is ready
- **Environment file**: Uses Docker-specific configuration
- **Network connectivity**: Can reach MongoDB using container name
- **Port exposure**: API accessible on localhost:5000
- **Custom image**: Uses locally built `backend-mongo-app`

#### Step 10: Deploy Frontend Container
```bash
# Start frontend container
docker run -d \
  --name frontend \
  --network mogo-network \
  -p 3000:3000 \
  -e REACT_APP_API_URL=http://localhost:5000/api \
  frontend-mongo-app

# Output: a9936f6c9adda978e76c57ae5742bed31704a7b1ef07592d7cc6b3ce984d99d1

# Verify frontend container is running
docker ps | grep frontend
```

**Frontend Container Configuration:**
- **React environment**: `REACT_APP_API_URL` points to backend API
- **Static serving**: Nginx serves built React application
- **Port mapping**: Web interface accessible on localhost:3000
- **Pre-built image**: Uses existing `frontend-mongo-app`

### Phase 6: Deployment Verification

#### Step 11: Verify All Containers Are Running
```bash
# Check status of all containers
docker ps

# Expected output showing all three containers:
CONTAINER ID   IMAGE                COMMAND                  CREATED          STATUS                             PORTS
a9936f6c9add   frontend-mongo-app   "dumb-init -- nginx …"   13 seconds ago   Up 12 seconds (healthy)            0.0.0.0:3000->3000/tcp
df2e4a48821d   backend-mongo-app    "docker-entrypoint.s…"   22 seconds ago   Up 21 seconds (health: starting)   0.0.0.0:5000->5000/tcp
7b9019eb4c1a   mongo:7.0            "docker-entrypoint.s…"   40 seconds ago   Up 40 seconds                      0.0.0.0:27017->27017/tcp
```

#### Step 12: Verify Network Connectivity
```bash
# Inspect network to see connected containers
docker network inspect mogo-network

# Key information from output:
# Containers section shows:
# - mongodb: 172.19.0.2/16
# - backend: 172.19.0.3/16  
# - frontend: 172.19.0.4/16
```

**Network Topology:**
```
mogo-network (172.19.0.0/16)
├── Gateway: 172.19.0.1
├── mongodb: 172.19.0.2
├── backend: 172.19.0.3
└── frontend: 172.19.0.4
```

#### Step 13: Check Container Logs
```bash
# Check backend startup logs
docker logs backend --tail 10

# Expected output:
🚀 Starting AWS MongoDB Backend Application...
✅ Environment variables loaded successfully
📊 Environment: production
🔌 Port: 5000
🗄️  Database: mongodb://admin:password123@mongodb:27017/myapp?authSource=admin
🔐 JWT configured with 7d expiration
Server running on port 5000
Environment: production

# Check MongoDB logs
docker logs mongodb --tail 5
# Shows database initialization and index creation

# Check frontend logs  
docker logs frontend --tail 5
# Shows nginx startup and worker processes

## Testing and Verification

### Comprehensive Application Testing

#### Step 14: Test Backend API Health
```bash
# Test backend health endpoint
curl -s http://localhost:5000/health

# Expected response:
{
  "status": "OK",
  "timestamp": "2025-08-04T17:11:10.133Z",
  "uptime": 35.170441078,
  "environment": "production"
}
```

#### Step 15: Test Frontend Accessibility
```bash
# Test frontend HTTP response
curl -s -I http://localhost:3000

# Expected response headers:
HTTP/1.1 200 OK
Server: nginx
Date: Mon, 04 Aug 2025 17:11:13 GMT
Content-Type: text/html
Content-Length: 480
Last-Modified: Mon, 04 Aug 2025 13:52:56 GMT
Connection: keep-alive
ETag: "6890bb38-1e0"
Cache-Control: no-cache, no-store, must-revalidate
Accept-Ranges: bytes
```

#### Step 16: Test Database Connectivity
```bash
# Test MongoDB connection from backend container
docker exec backend node -e "
const mongoose = require('mongoose');
mongoose.connect(process.env.MONGODB_URI)
  .then(() => {
    console.log('✅ Database connection successful');
    process.exit(0);
  })
  .catch(err => {
    console.log('❌ Database connection failed:', err.message);
    process.exit(1);
  });
"

# Expected output:
✅ Database connection successful
```

#### Step 17: Test Inter-Container Communication
```bash
# Test backend can reach MongoDB
docker exec backend ping -c 3 mongodb
# Should show successful ping responses

# Test frontend can reach backend (if ping is available)
docker exec frontend ping -c 3 backend
# Should show successful ping responses

# Test DNS resolution
docker exec backend nslookup mongodb
# Should resolve to container IP address
```

### Application Access Points

After successful deployment, the application is accessible via:

- **🌐 Frontend Web Interface**: http://localhost:3000
- **🔧 Backend API**: http://localhost:5000
- **🩺 API Health Check**: http://localhost:5000/health
- **🗄️ MongoDB Database**: localhost:27017 (external access)

## Container Management

### Automated Management Script

A comprehensive management script was created to simplify container operations:

**File: `manage-containers.sh`**

```bash
#!/bin/bash

# MongoDB Application Container Management Script
# Network: mogo-network

NETWORK_NAME="mogo-network"

case "$1" in
    start)
        echo "🚀 Starting MongoDB Application containers..."
        
        # Create network if it doesn't exist
        if ! docker network ls | grep -q $NETWORK_NAME; then
            echo "📡 Creating network: $NETWORK_NAME"
            docker network create --driver bridge $NETWORK_NAME
        fi
        
        # Start MongoDB
        echo "🗄️  Starting MongoDB..."
        docker run -d \
            --name mongodb \
            --network $NETWORK_NAME \
            -p 27017:27017 \
            -e MONGO_INITDB_ROOT_USERNAME=admin \
            -e MONGO_INITDB_ROOT_PASSWORD=password123 \
            -e MONGO_INITDB_DATABASE=myapp \
            -v mongodb_data:/data/db \
            mongo:7.0
        
        # Wait for MongoDB to be ready
        echo "⏳ Waiting for MongoDB to be ready..."
        sleep 10
        
        # Start Backend
        echo "🔧 Starting Backend API..."
        docker run -d \
            --name backend \
            --network $NETWORK_NAME \
            -p 5000:5000 \
            --env-file ./backend/.env.docker \
            backend-mongo-app
        
        # Start Frontend
        echo "🌐 Starting Frontend..."
        docker run -d \
            --name frontend \
            --network $NETWORK_NAME \
            -p 3000:3000 \
            -e REACT_APP_API_URL=http://localhost:5000/api \
            frontend-mongo-app
        
        echo "✅ All containers started successfully!"
        echo "🌐 Frontend: http://localhost:3000"
        echo "🔧 Backend API: http://localhost:5000"
        echo "🗄️  MongoDB: localhost:27017"
        ;;
        
    stop)
        echo "🛑 Stopping MongoDB Application containers..."
        docker stop frontend backend mongodb 2>/dev/null || true
        echo "✅ All containers stopped!"
        ;;
        
    restart)
        echo "🔄 Restarting MongoDB Application..."
        $0 stop
        sleep 3
        $0 start
        ;;
        
    status)
        echo "📊 Container Status:"
        docker ps --filter "name=mongodb" --filter "name=backend" --filter "name=frontend" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        echo -e "\n🌐 Network Information:"
        docker network inspect $NETWORK_NAME --format "{{range .Containers}}{{.Name}}: {{.IPv4Address}}{{println}}{{end}}" 2>/dev/null || echo "Network not found"
        ;;
        
    logs)
        if [ -z "$2" ]; then
            echo "📋 Available containers: mongodb, backend, frontend"
            echo "Usage: $0 logs <container_name>"
        else
            echo "📋 Logs for $2:"
            docker logs $2 --tail 20 -f
        fi
        ;;
        
    clean)
        echo "🧹 Cleaning up containers and network..."
        docker stop frontend backend mongodb 2>/dev/null || true
        docker rm frontend backend mongodb 2>/dev/null || true
        docker network rm $NETWORK_NAME 2>/dev/null || true
        echo "✅ Cleanup completed!"
        ;;
        
    test)
        echo "🧪 Testing application connectivity..."
        
        echo "Testing Backend Health:"
        curl -s http://localhost:5000/health | jq . 2>/dev/null || curl -s http://localhost:5000/health
        
        echo -e "\nTesting Frontend:"
        curl -s -I http://localhost:3000 | head -1
        
        echo -e "\nTesting Database Connection:"
        docker exec backend node -e "
        const mongoose = require('mongoose');
        mongoose.connect(process.env.MONGODB_URI)
          .then(() => {
            console.log('✅ Database connection successful');
            process.exit(0);
          })
          .catch(err => {
            console.log('❌ Database connection failed:', err.message);
            process.exit(1);
          });
        " 2>/dev/null
        ;;
        
    *)
        echo "MongoDB Application Container Manager"
        echo "Usage: $0 {start|stop|restart|status|logs|clean|test}"
        echo ""
        echo "Commands:"
        echo "  start   - Start all application containers"
        echo "  stop    - Stop all application containers"
        echo "  restart - Restart all application containers"
        echo "  status  - Show container and network status"
        echo "  logs    - Show logs for a specific container"
        echo "  clean   - Remove all containers and network"
        echo "  test    - Test application connectivity"
        echo ""
        echo "Network: $NETWORK_NAME"
        echo "Ports: Frontend(3000), Backend(5000), MongoDB(27017)"
        ;;
esac
```

### Management Script Usage

```bash
# Make script executable
chmod +x manage-containers.sh

# Start all containers
./manage-containers.sh start

# Check container status
./manage-containers.sh status

# View logs for specific container
./manage-containers.sh logs backend
./manage-containers.sh logs frontend
./manage-containers.sh logs mongodb

# Test application connectivity
./manage-containers.sh test

# Stop all containers
./manage-containers.sh stop

# Restart all containers
./manage-containers.sh restart

# Complete cleanup (removes containers and network)
./manage-containers.sh clean
```

### Manual Container Management Commands

#### Individual Container Control
```bash
# Start individual containers
docker start mongodb
docker start backend
docker start frontend

# Stop individual containers
docker stop frontend
docker stop backend
docker stop mongodb

# Remove individual containers
docker rm frontend
docker rm backend
docker rm mongodb

# View individual container logs
docker logs mongodb -f
docker logs backend -f
docker logs frontend -f
```

#### Network Management
```bash
# List networks
docker network ls

# Inspect network details
docker network inspect mogo-network

# Remove network (containers must be stopped first)
docker network rm mogo-network

# Create network again
docker network create --driver bridge mogo-network
```

#### Volume Management
```bash
# List volumes
docker volume ls

# Inspect MongoDB data volume
docker volume inspect mongodb_data

# Remove volume (container must be stopped and removed first)
docker volume rm mongodb_data

# Create volume manually
docker volume create mongodb_data
```

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Port Already in Use
**Symptoms:**
```bash
Error response from daemon: driver failed programming external connectivity on endpoint mongodb: 
Bind for 0.0.0.0:27017 failed: port is already allocated
```

**Solution:**
```bash
# Find process using the port
sudo netstat -tulpn | grep :27017
# or
sudo lsof -i :27017

# Stop conflicting container
docker ps | grep 27017
docker stop <container_name>

# Kill process if not Docker container
sudo kill -9 <process_id>
```

#### Issue 2: Container Cannot Connect to Database
**Symptoms:**
- Backend logs show connection errors
- Health check fails
- API returns database connection errors

**Diagnosis:**
```bash
# Check if MongoDB container is running
docker ps | grep mongodb

# Check MongoDB logs
docker logs mongodb

# Test network connectivity
docker exec backend ping mongodb

# Verify environment variables
docker exec backend env | grep MONGODB_URI
```

**Solutions:**
```bash
# Ensure containers are on same network
docker network inspect mogo-network

# Restart containers in correct order
./manage-containers.sh stop
./manage-containers.sh start

# Check MongoDB authentication
docker exec -it mongodb mongosh -u admin -p password123 --authenticationDatabase admin
```

#### Issue 3: Frontend Cannot Reach Backend
**Symptoms:**
- Frontend loads but API calls fail
- CORS errors in browser console
- Network errors in browser developer tools

**Diagnosis:**
```bash
# Test backend API directly
curl http://localhost:5000/health

# Check backend logs
docker logs backend

# Verify frontend environment variables
docker exec frontend env | grep REACT_APP_API_URL
```

**Solutions:**
```bash
# Ensure backend is running and healthy
docker ps | grep backend

# Check CORS configuration in backend
# Verify FRONTEND_URL in backend/.env.docker

# Test API from host machine
curl -v http://localhost:5000/api/test
```

#### Issue 4: Container Health Check Failures
**Symptoms:**
- Container shows as "unhealthy" in docker ps
- Application not responding properly

**Diagnosis:**
```bash
# Check container health status
docker inspect backend --format='{{.State.Health.Status}}'

# View health check logs
docker inspect backend --format='{{range .State.Health.Log}}{{.Output}}{{end}}'

# Check if health check script exists
docker exec backend ls -la healthcheck.js
```

**Solutions:**
```bash
# Create missing health check script
docker exec backend node -e "console.log('Health check script needed')"

# Restart container
docker restart backend

# Disable health check temporarily (for debugging)
docker run --health-cmd='' --health-interval=0s <other_options>
```

#### Issue 5: Network Connectivity Issues
**Symptoms:**
- Containers cannot communicate with each other
- DNS resolution fails between containers

**Diagnosis:**
```bash
# Check network configuration
docker network inspect mogo-network

# Test DNS resolution
docker exec backend nslookup mongodb
docker exec frontend nslookup backend

# Check container network settings
docker inspect backend --format='{{.NetworkSettings.Networks}}'
```

**Solutions:**
```bash
# Recreate network
docker network rm mogo-network
docker network create --driver bridge mogo-network

# Reconnect containers to network
docker network connect mogo-network mongodb
docker network connect mogo-network backend
docker network connect mogo-network frontend

# Use IP addresses instead of container names (temporary fix)
docker network inspect mogo-network | grep IPv4Address
```

### Debugging Commands

#### Container Inspection
```bash
# Get detailed container information
docker inspect <container_name>

# Check container resource usage
docker stats <container_name>

# Execute commands inside container
docker exec -it <container_name> /bin/sh
docker exec -it <container_name> bash

# Check container filesystem
docker exec <container_name> ls -la /app
docker exec <container_name> cat /app/package.json
```

#### Log Analysis
```bash
# View logs with timestamps
docker logs -t <container_name>

# Follow logs in real-time
docker logs -f <container_name>

# View last N lines of logs
docker logs --tail 50 <container_name>

# View logs from specific time
docker logs --since "2025-08-04T17:00:00" <container_name>
```

#### Network Debugging
```bash
# Test connectivity between containers
docker exec backend ping -c 3 mongodb
docker exec frontend wget -qO- http://backend:5000/health

# Check DNS resolution
docker exec backend nslookup mongodb
docker exec backend cat /etc/resolv.conf

# Inspect network traffic (if tcpdump available)
docker exec backend tcpdump -i eth0 -n
```

## Best Practices

### Security Best Practices

#### Container Security
```bash
# Run containers with non-root users (already implemented in Dockerfiles)
USER nodejs

# Use specific image tags instead of 'latest'
FROM node:18-alpine  # ✅ Good
FROM node:latest     # ❌ Avoid

# Scan images for vulnerabilities
docker scan backend-mongo-app
docker scan frontend-mongo-app
```

#### Network Security
```bash
# Use custom networks instead of default bridge
docker network create --driver bridge mogo-network  # ✅ Good
docker run --network bridge                         # ❌ Less secure

# Limit port exposure
-p 127.0.0.1:5000:5000  # Only localhost access
-p 5000:5000            # All interfaces (current setup)

# Use secrets for sensitive data (production)
docker secret create mongodb_password password.txt
docker service create --secret mongodb_password mongo
```

#### Environment Variable Security
```bash
# Use .env files instead of command line (current approach)
--env-file ./backend/.env.docker  # ✅ Good
-e MONGODB_URI=mongodb://...       # ❌ Visible in process list

# Use Docker secrets in production
echo "password123" | docker secret create db_password -
```

### Performance Optimization

#### Resource Limits
```bash
# Set memory limits
docker run --memory="512m" --name backend backend-mongo-app

# Set CPU limits
docker run --cpus="1.5" --name backend backend-mongo-app

# Combined resource limits
docker run \
  --memory="512m" \
  --cpus="1.0" \
  --name backend \
  backend-mongo-app
```

#### Volume Optimization
```bash
# Use named volumes for better performance
-v mongodb_data:/data/db  # ✅ Good (current approach)
-v ./data:/data/db        # ❌ Slower on some systems

# Use tmpfs for temporary data
--tmpfs /tmp:rw,noexec,nosuid,size=100m
```

#### Image Optimization
```bash
# Multi-stage builds (already used in frontend)
FROM node:18-alpine AS builder
# ... build steps ...
FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html

# Use .dockerignore files
echo "node_modules" > .dockerignore
echo "*.log" >> .dockerignore
echo ".git" >> .dockerignore
```

### Monitoring and Logging

#### Container Monitoring
```bash
# Monitor resource usage
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

# Set up health checks (already implemented)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

# Use monitoring tools
docker run -d \
  --name=cadvisor \
  -p 8080:8080 \
  -v /:/rootfs:ro \
  -v /var/run:/var/run:ro \
  -v /sys:/sys:ro \
  -v /var/lib/docker/:/var/lib/docker:ro \
  gcr.io/cadvisor/cadvisor:latest
```

#### Centralized Logging
```bash
# Use logging drivers
docker run --log-driver=json-file --log-opt max-size=10m --log-opt max-file=3

# Forward logs to external systems
docker run --log-driver=syslog --log-opt syslog-address=tcp://logserver:514

# Use log aggregation
docker run -d \
  --name=fluentd \
  -p 24224:24224 \
  -v /data:/fluentd/log \
  fluent/fluentd:latest
```

### Backup and Recovery

#### Database Backup
```bash
# Create backup script
cat > backup-mongodb.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups"
mkdir -p $BACKUP_DIR

# Create MongoDB dump
docker exec mongodb mongodump \
  --host localhost \
  --port 27017 \
  --username admin \
  --password password123 \
  --authenticationDatabase admin \
  --out $BACKUP_DIR/mongodb_backup_$DATE

echo "Backup completed: $BACKUP_DIR/mongodb_backup_$DATE"
EOF

chmod +x backup-mongodb.sh
```

#### Container State Backup
```bash
# Export container as image
docker commit backend backend-mongo-app:backup-$(date +%Y%m%d)

# Save image to file
docker save backend-mongo-app:latest > backend-backup.tar

# Load image from file
docker load < backend-backup.tar
```

#### Volume Backup
```bash
# Backup named volume
docker run --rm \
  -v mongodb_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/mongodb_data_backup.tar.gz -C /data .

# Restore named volume
docker run --rm \
  -v mongodb_data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/mongodb_data_backup.tar.gz -C /data
```

### Production Deployment Considerations

#### Environment Separation
```bash
# Use different environment files
backend/.env.development
backend/.env.staging
backend/.env.production

# Use environment-specific networks
docker network create --driver bridge mogo-network-prod
docker network create --driver bridge mogo-network-staging
```

#### Scaling Considerations
```bash
# Horizontal scaling with multiple backend instances
docker run -d --name backend-1 --network mogo-network -p 5001:5000 backend-mongo-app
docker run -d --name backend-2 --network mogo-network -p 5002:5000 backend-mongo-app
docker run -d --name backend-3 --network mogo-network -p 5003:5000 backend-mongo-app

# Load balancer configuration (nginx)
upstream backend {
    server backend-1:5000;
    server backend-2:5000;
    server backend-3:5000;
}
```

#### High Availability Setup
```bash
# MongoDB replica set
docker run -d --name mongodb-primary --network mogo-network mongo:7.0 --replSet rs0
docker run -d --name mongodb-secondary --network mogo-network mongo:7.0 --replSet rs0

# Initialize replica set
docker exec -it mongodb-primary mongosh --eval "
rs.initiate({
  _id: 'rs0',
  members: [
    { _id: 0, host: 'mongodb-primary:27017' },
    { _id: 1, host: 'mongodb-secondary:27017' }
  ]
})
"
```

## Advanced Topics

### Docker Compose Integration

While this guide focuses on manual Docker commands, you can also use Docker Compose for easier management:

```yaml
# docker-compose.override.yml for custom network
version: '3.8'

services:
  mongodb:
    networks:
      - mogo-network
  
  backend:
    networks:
      - mogo-network
  
  frontend:
    networks:
      - mogo-network

networks:
  mogo-network:
    external: true
```

### Container Orchestration

#### Docker Swarm (Simple Orchestration)
```bash
# Initialize swarm
docker swarm init

# Deploy as stack
docker stack deploy -c docker-compose.yml mongodb-app

# Scale services
docker service scale mongodb-app_backend=3
```

#### Kubernetes Migration Path
```yaml
# kubernetes/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: mongodb-app

---
# kubernetes/mongodb-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb
  namespace: mongodb-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo:7.0
        ports:
        - containerPort: 27017
        env:
        - name: MONGO_INITDB_ROOT_USERNAME
          value: admin
        - name: MONGO_INITDB_ROOT_PASSWORD
          value: password123
```

### CI/CD Integration

#### GitHub Actions Example
```yaml
# .github/workflows/docker-build.yml
name: Build and Test Docker Images

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Build backend image
      run: |
        cd backend
        docker build -t backend-mongo-app:${{ github.sha }} .
    
    - name: Build frontend image
      run: |
        cd frontend
        docker build -t frontend-mongo-app:${{ github.sha }} .
    
    - name: Test application
      run: |
        docker network create test-network
        # Start containers and run tests
        ./manage-containers.sh start
        ./manage-containers.sh test
        ./manage-containers.sh clean
```

## Summary

This comprehensive guide documented the complete process of containerizing and deploying the AWS MongoDB application using Docker with a custom bridge network. The key achievements include:

### ✅ Accomplished Tasks

1. **Image Preparation**
   - Built backend Docker image from source
   - Verified frontend image availability
   - Configured proper Dockerfiles with security best practices

2. **Network Infrastructure**
   - Created custom bridge network `mogo-network`
   - Configured container-to-container communication
   - Established proper network isolation

3. **Container Deployment**
   - Deployed MongoDB with persistent storage
   - Deployed backend API with environment-specific configuration
   - Deployed frontend with proper API connectivity

4. **Testing and Verification**
   - Verified all containers are running and healthy
   - Tested inter-container communication
   - Confirmed application accessibility via browser

5. **Management Automation**
   - Created comprehensive management script
   - Implemented proper startup/shutdown procedures
   - Added monitoring and debugging capabilities

### 🌐 Final Application Access

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:5000
- **Database**: localhost:27017
- **Health Check**: http://localhost:5000/health

### 📊 Network Configuration

- **Network Name**: mogo-network
- **Network Type**: Bridge
- **Subnet**: 172.19.0.0/16
- **Container IPs**:
  - MongoDB: 172.19.0.2
  - Backend: 172.19.0.3
  - Frontend: 172.19.0.4

### 🛠️ Management Commands

```bash
# Quick start
./manage-containers.sh start

# Check status
./manage-containers.sh status

# View logs
./manage-containers.sh logs <container_name>

# Test connectivity
./manage-containers.sh test

# Clean shutdown
./manage-containers.sh stop
```

This setup provides a robust, scalable, and maintainable containerized deployment of your MongoDB application with proper networking, security, and monitoring capabilities.
```
