#!/bin/bash

set -e

PROJECT_NAME="task-management-api"
DB_CONTAINER="local-mysql"
APP_CONTAINER="local-task-api"

echo "🚀 Starting Task Management API locally..."

# Function to cleanup on exit
cleanup() {
    echo "🧹 Cleaning up containers..."
    docker stop $APP_CONTAINER $DB_CONTAINER 2>/dev/null || true
    docker rm $APP_CONTAINER $DB_CONTAINER 2>/dev/null || true
}

# Set trap to cleanup on script exit
trap cleanup EXIT

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Start MySQL database
echo "🗄️ Starting MySQL database..."
docker run -d --name $DB_CONTAINER \
  -e MYSQL_ROOT_PASSWORD=password123 \
  -e MYSQL_DATABASE=taskdb \
  -e MYSQL_USER=taskuser \
  -e MYSQL_PASSWORD=taskpass \
  -p 3306:3306 \
  --health-cmd="mysqladmin ping -h localhost" \
  --health-interval=10s \
  --health-timeout=5s \
  --health-retries=5 \
  mysql:8.0

# Wait for database to be healthy
echo "⏳ Waiting for database to be ready..."
until [ "$(docker inspect --format='{{.State.Health.Status}}' $DB_CONTAINER)" = "healthy" ]; do
    echo "Waiting for MySQL to be healthy..."
    sleep 5
done

echo "✅ Database is ready!"

# Build application if JAR doesn't exist
if [ ! -f "target/$PROJECT_NAME-1.0.0.jar" ]; then
    echo "📦 Building application..."
    mvn clean package -DskipTests
fi

# Run application
echo "🚀 Starting application..."
docker run -d --name $APP_CONTAINER \
  --link $DB_CONTAINER:mysql \
  -e SPRING_PROFILES_ACTIVE=dev \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/taskdb \
  -e SPRING_DATASOURCE_USERNAME=taskuser \
  -e SPRING_DATASOURCE_PASSWORD=taskpass \
  -p 8080:8080 \
  $PROJECT_NAME:latest

# Wait for application to start
echo "⏳ Waiting for application to start..."
sleep 30

# Health check
echo "🏥 Performing health check..."
for i in {1..30}; do
    if curl -f -s http://localhost:8080/actuator/health > /dev/null; then
        echo "✅ Application is healthy!"
        break
    else
        echo "Waiting for application to be ready... ($i/30)"
        sleep 5
    fi
    
    if [ $i -eq 30 ]; then
        echo "❌ Application failed to start properly"
        echo "📋 Application logs:"
        docker logs $APP_CONTAINER
        exit 1
    fi
done

# Display application info
echo ""
echo "🎉 Task Management API is running locally!"
echo ""
echo "📋 Application Information:"
echo "  🌐 API Base URL: http://localhost:8080"
echo "  🏥 Health Check: http://localhost:8080/actuator/health"
echo "  📊 Metrics: http://localhost:8080/actuator/prometheus"
echo "  📖 API Endpoints:"
echo "    - GET    /api/tasks           - Get all tasks"
echo "    - POST   /api/tasks           - Create new task"
echo "    - GET    /api/tasks/{id}      - Get task by ID"
echo "    - PUT    /api/tasks/{id}      - Update task"
echo "    - DELETE /api/tasks/{id}      - Delete task"
echo ""
echo "🗄️ Database Information:"
echo "  📍 Host: localhost:3306"
echo "  🗃️ Database: taskdb"
echo "  👤 Username: taskuser"
echo "  🔑 Password: taskpass"
echo ""

# Test API endpoints
echo "🧪 Testing API endpoints..."

# Test health endpoint
echo "Testing health endpoint..."
curl -s http://localhost:8080/actuator/health | jq . || echo "Health check response received"

# Test create task
echo "Testing create task..."
TASK_ID=$(curl -s -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Task",
    "description": "This is a test task created by run-local script",
    "priority": "HIGH"
  }' | jq -r '.id' 2>/dev/null || echo "1")

echo "Created task with ID: $TASK_ID"

# Test get all tasks
echo "Testing get all tasks..."
curl -s http://localhost:8080/api/tasks | jq . || echo "Get all tasks response received"

echo ""
echo "✅ API testing completed!"
echo ""
echo "🔧 Useful commands:"
echo "  📋 View application logs: docker logs -f $APP_CONTAINER"
echo "  📋 View database logs: docker logs -f $DB_CONTAINER"
echo "  🗄️ Connect to database: docker exec -it $DB_CONTAINER mysql -u taskuser -p taskdb"
echo "  🛑 Stop application: docker stop $APP_CONTAINER $DB_CONTAINER"
echo ""
echo "Press Ctrl+C to stop the application and cleanup containers"

# Keep script running
while true; do
    sleep 10
    # Check if containers are still running
    if ! docker ps | grep -q $APP_CONTAINER; then
        echo "❌ Application container stopped unexpectedly"
        docker logs $APP_CONTAINER
        break
    fi
done
