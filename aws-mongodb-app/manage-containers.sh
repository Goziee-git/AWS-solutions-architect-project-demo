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
