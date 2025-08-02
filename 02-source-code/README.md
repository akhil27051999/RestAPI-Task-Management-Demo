# Task Management API - Source Code

## Overview
A Spring Boot REST API for task management with CRUD operations, built with Java 17 and MySQL.

## Features
- Create, read, update, delete tasks
- Task status management (PENDING, IN_PROGRESS, COMPLETED, CANCELLED)
- Search tasks by title
- Filter tasks by status
- Health checks and metrics endpoints
- Comprehensive test coverage

## Technology Stack
- **Java 17**
- **Spring Boot 2.7.14**
- **Spring Data JPA**
- **MySQL 8.0**
- **Maven**
- **JUnit 5**
- **Mockito**

## API Endpoints

### Tasks
- `GET /api/tasks` - Get all tasks
- `GET /api/tasks/{id}` - Get task by ID
- `POST /api/tasks` - Create new task
- `PUT /api/tasks/{id}` - Update task
- `DELETE /api/tasks/{id}` - Delete task

### Health & Monitoring
- `GET /actuator/health` - Health check
- `GET /actuator/metrics` - Application metrics
- `GET /actuator/prometheus` - Prometheus metrics

## Quick Start

### Prerequisites
- Java 17+
- Maven 3.6+
- MySQL 8.0+

### Database Setup
```sql
CREATE DATABASE taskdb;
CREATE USER 'taskuser'@'localhost' IDENTIFIED BY 'taskpass';
GRANT ALL PRIVILEGES ON taskdb.* TO 'taskuser'@'localhost';
FLUSH PRIVILEGES;
```

### Environment Variables
```bash
export DB_USERNAME=taskuser
export DB_PASSWORD=taskpass
```

### Run Application
```bash
# Build
mvn clean package

# Run
mvn spring-boot:run

# Or run JAR
java -jar target/task-management-api-1.0.0.jar
```

### Test Application
```bash
# Run tests
mvn test

# Run with coverage
mvn test jacoco:report

# View coverage report
open target/site/jacoco/index.html
```

## Usage Examples

### Create Task
```bash
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Complete project",
    "description": "Finish the task management API",
    "status": "PENDING"
  }'
```

### Get All Tasks
```bash
curl http://localhost:8080/api/tasks
```

### Update Task
```bash
curl -X PUT http://localhost:8080/api/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Complete project",
    "description": "Finish the task management API",
    "status": "COMPLETED"
  }'
```

### Delete Task
```bash
curl -X DELETE http://localhost:8080/api/tasks/1
```

## Configuration

### Development (application.yml)
- Database: localhost:3306/taskdb
- Logging: DEBUG level
- JPA: show-sql enabled

### Production (application-prod.yml)
- Database: Environment variables
- Logging: INFO level
- JPA: show-sql disabled

## Testing
- Unit tests for service layer
- Integration tests for controller layer
- Test coverage with JaCoCo
- H2 in-memory database for tests

## Build & Deployment
```bash
# Build JAR
mvn clean package

# Build Docker image
docker build -t task-management-api .

# Run with Docker Compose
docker-compose up -d
```

This source code provides a complete, production-ready REST API with proper layered architecture and comprehensive testing.

## Project Structure Summary

This source code provides:

✅ **Complete REST API** - Full CRUD operations for task management
✅ **Layered Architecture** - Controller, Service, Repository, Model layers
✅ **Database Integration** - MySQL with JPA/Hibernate
✅ **Configuration Management** - Environment-specific configurations
✅ **Comprehensive Testing** - Unit and integration tests
✅ **Production Ready** - Health checks, metrics, and monitoring
✅ **Documentation** - Complete README with usage examples

The code follows Spring Boot best practices with proper separation of concerns and is ready for containerization and deployment.
