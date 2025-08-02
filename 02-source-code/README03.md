# Task Management API - Source Code Documentation

## Project Overview

This is a comprehensive Spring Boot REST API for task management with complete DevOps implementation. The project demonstrates enterprise-level development practices with proper layered architecture, comprehensive testing, and production-ready configurations.

## Technology Stack

- **Java 17** - Latest LTS version with modern language features
- **Spring Boot 3.2** - Latest Spring Boot with enhanced performance
- **Spring Data JPA** - Data persistence and repository abstraction
- **MySQL 8.0** - Relational database with JSON support
- **Maven** - Dependency management and build automation
- **Docker** - Containerization for consistent deployments
- **JUnit 5** - Modern testing framework
- **Swagger/OpenAPI 3** - API documentation and testing

## Project Structure

```
src/
├── main/
│   ├── java/com/taskapi/
│   │   ├── TaskApiApplication.java          # Main application class
│   │   ├── controller/                      # REST API endpoints
│   │   ├── model/                          # JPA entities and enums
│   │   ├── repository/                     # Data access layer
│   │   ├── service/                        # Business logic layer
│   │   ├── dto/                           # Data transfer objects
│   │   ├── exception/                     # Error handling
│   │   └── config/                        # Configuration classes
│   └── resources/
│       ├── application.yml                 # Main configuration
│       ├── application-dev.yml            # Development config
│       ├── application-prod.yml           # Production config
│       └── db/migration/                  # Database schema
└── test/
    └── java/com/taskapi/                  # Test classes
```

---

## Source Code Files Explanation

### 1. Main Application Class

#### `TaskApiApplication.java`
```java
@SpringBootApplication
@EnableJpaRepositories
@EnableScheduling
public class TaskApiApplication {
    public static void main(String[] args) {
        SpringApplication.run(TaskApiApplication.class, args);
    }
}
```

**Purpose**: Entry point of the Spring Boot application
- `@SpringBootApplication`: Combines `@Configuration`, `@EnableAutoConfiguration`, and `@ComponentScan`
- `@EnableJpaRepositories`: Enables JPA repository scanning and configuration
- `@EnableScheduling`: Enables Spring's scheduled task execution capability

---

### 2. Controller Layer (REST API Endpoints)

#### `TaskController.java`
**Purpose**: Handles HTTP requests and responses for task operations

**Key Features**:
- RESTful endpoints for CRUD operations
- Request validation using `@Valid`
- Pagination support with `Pageable`
- Swagger documentation with `@Operation`
- Comprehensive logging

**Endpoints**:
- `GET /api/tasks` - Retrieve all tasks with pagination
- `GET /api/tasks/{id}` - Get specific task by ID
- `POST /api/tasks` - Create new task
- `PUT /api/tasks/{id}` - Update existing task
- `DELETE /api/tasks/{id}` - Delete task
- `GET /api/tasks/status/{status}` - Filter tasks by status

**Example Method**:
```java
@PostMapping
@Operation(summary = "Create new task")
public ResponseEntity<TaskResponse> createTask(@Valid @RequestBody TaskCreateRequest request) {
    TaskResponse created = taskService.createTask(request);
    return ResponseEntity.status(HttpStatus.CREATED).body(created);
}
```

#### `HealthController.java`
**Purpose**: Custom health check endpoint beyond Spring Actuator

**Features**:
- Database connectivity verification
- Custom health status reporting
- Integration with Spring Boot Actuator
- Connection pool monitoring

---

### 3. Model Layer (Data Entities)

#### `Task.java`
**Purpose**: JPA entity representing the task table

**Key Features**:
- JPA annotations for database mapping
- Lombok annotations for boilerplate code reduction
- Validation constraints
- Audit fields (created/updated timestamps)
- Builder pattern support

**Fields**:
- `id`: Primary key (auto-generated)
- `title`: Task title (required, max 255 chars)
- `description`: Detailed description (max 1000 chars)
- `status`: Current status (enum)
- `priority`: Task priority (enum)
- `createdAt/updatedAt`: Audit timestamps
- `dueDate`: Optional deadline
- `assignedTo`: User assignment
- `completedAt`: Completion timestamp

#### `TaskStatus.java`
**Purpose**: Enum defining possible task states

**Values**:
- `PENDING`: Initial state
- `IN_PROGRESS`: Work started
- `COMPLETED`: Task finished
- `CANCELLED`: Task cancelled

**Features**:
- Display name mapping
- String conversion methods
- Validation support

#### `Priority.java`
**Purpose**: Enum for task priority levels

**Values**:
- `LOW` (level 1): Non-urgent tasks
- `MEDIUM` (level 2): Standard priority
- `HIGH` (level 3): Important tasks
- `URGENT` (level 4): Critical tasks

**Features**:
- Numeric level for sorting
- Display name for UI
- Conversion utilities

---

### 4. Repository Layer (Data Access)

#### `TaskRepository.java`
**Purpose**: Data access interface extending JpaRepository

**Key Features**:
- Spring Data JPA repository
- Custom query methods
- JPQL queries for complex operations
- Method naming conventions for automatic query generation

**Custom Methods**:
```java
List<Task> findByStatus(TaskStatus status);
List<Task> findByPriority(Priority priority);
List<Task> findByAssignedTo(String assignedTo);

@Query("SELECT t FROM Task t WHERE t.dueDate BETWEEN :startDate AND :endDate")
List<Task> findTasksDueBetween(@Param("startDate") LocalDateTime startDate, 
                               @Param("endDate") LocalDateTime endDate);

@Query("SELECT t FROM Task t WHERE t.status = :status AND t.dueDate < :currentDate")
List<Task> findOverdueTasks(@Param("status") TaskStatus status, 
                           @Param("currentDate") LocalDateTime currentDate);
```

---

### 5. Service Layer (Business Logic)

#### `TaskService.java` (Interface)
**Purpose**: Service contract defining business operations

**Methods**:
- CRUD operations
- Search and filtering
- Business logic abstractions
- Return DTOs instead of entities

#### `TaskServiceImpl.java` (Implementation)
**Purpose**: Business logic implementation

**Key Features**:
- `@Transactional` for data consistency
- Entity to DTO mapping
- Custom metrics integration with Micrometer
- Comprehensive logging
- Error handling

**Example Method**:
```java
@Override
public TaskResponse createTask(TaskCreateRequest request) {
    Task task = Task.builder()
            .title(request.getTitle())
            .description(request.getDescription())
            .status(TaskStatus.valueOf(request.getStatus().toUpperCase()))
            .priority(Priority.valueOf(request.getPriority().toUpperCase()))
            .dueDate(request.getDueDate())
            .assignedTo(request.getAssignedTo())
            .build();

    Task savedTask = taskRepository.save(task);
    
    // Custom metrics
    Counter.builder("tasks.created")
            .tag("status", savedTask.getStatus().name())
            .register(meterRegistry)
            .increment();

    return mapToResponse(savedTask);
}
```

---

### 6. DTO Layer (Data Transfer Objects)

#### `TaskCreateRequest.java`
**Purpose**: Request DTO for creating new tasks

**Features**:
- Input validation annotations
- Required field constraints
- Size limitations
- Default values

#### `TaskUpdateRequest.java`
**Purpose**: Request DTO for updating existing tasks

**Features**:
- Optional fields (all nullable)
- Partial update support
- Validation constraints

#### `TaskResponse.java`
**Purpose**: Response DTO for API responses

**Features**:
- Complete task information
- Formatted for client consumption
- No sensitive internal data
- Consistent structure

---

### 7. Exception Handling

#### `TaskNotFoundException.java`
**Purpose**: Custom exception for missing tasks

**Usage**: Thrown when task ID doesn't exist in database

#### `GlobalExceptionHandler.java`
**Purpose**: Centralized exception handling

**Features**:
- `@RestControllerAdvice` for global handling
- Different exception types handling
- Consistent error response format
- Validation error mapping
- Logging integration

**Error Response Structure**:
```java
public static class ErrorResponse {
    private LocalDateTime timestamp;
    private int status;
    private String error;
    private String message;
    private String path;
    private Map<String, String> validationErrors;
}
```

---

### 8. Configuration Classes

#### `DatabaseConfig.java`
**Purpose**: Database connection and HikariCP configuration

**Features**:
- Connection pool optimization
- Performance tuning parameters
- Connection leak detection
- Prepared statement caching

#### `SecurityConfig.java`
**Purpose**: Spring Security configuration

**Features**:
- CORS configuration
- Endpoint security rules
- Session management (stateless)
- Public endpoint definitions

#### `SwaggerConfig.java`
**Purpose**: OpenAPI/Swagger documentation configuration

**Features**:
- API metadata definition
- Server configurations
- Contact information
- License details

---

### 9. Resource Files

#### `application.yml`
**Purpose**: Main application configuration

**Contains**:
- Server port configuration
- Database connection settings
- JPA/Hibernate properties
- Actuator endpoint configuration
- Logging configuration

#### `application-dev.yml`
**Purpose**: Development environment overrides

**Features**:
- Debug logging enabled
- SQL logging
- Development database settings
- All actuator endpoints exposed

#### `application-prod.yml`
**Purpose**: Production environment configuration

**Features**:
- Optimized logging levels
- Production database settings
- Limited actuator endpoints
- Performance optimizations

#### `V1__Create_tasks_table.sql`
**Purpose**: Database schema migration

**Features**:
- Table creation script
- Index definitions for performance
- Enum constraints
- Audit field setup

---

### 10. Test Files

#### `TaskControllerTest.java`
**Purpose**: Controller layer testing

**Features**:
- `@WebMvcTest` for web layer testing
- MockMvc for HTTP request simulation
- Service layer mocking
- JSON response validation

#### `TaskServiceTest.java`
**Purpose**: Service layer unit testing

**Features**:
- `@ExtendWith(MockitoExtension.class)` for mocking
- Business logic testing
- Exception scenario testing
- Mock verification

#### `TaskRepositoryTest.java`
**Purpose**: Repository layer testing

**Features**:
- `@DataJpaTest` for JPA testing
- In-memory database testing
- Custom query testing
- TestEntityManager usage

---

## Architecture Patterns

### 1. Layered Architecture
- **Controller Layer**: HTTP request handling
- **Service Layer**: Business logic
- **Repository Layer**: Data access
- **Model Layer**: Data entities

### 2. DTO Pattern
- Separation of internal entities from API contracts
- Input validation at DTO level
- Response formatting

### 3. Repository Pattern
- Data access abstraction
- Query method conventions
- Custom query support

### 4. Exception Handling Pattern
- Global exception handling
- Consistent error responses
- Proper HTTP status codes

---

## Key Features

### 1. Validation
- Bean Validation (JSR-303) annotations
- Custom validation messages
- Request-level validation

### 2. Logging
- SLF4J with Logback
- Structured logging
- Environment-specific log levels

### 3. Metrics
- Micrometer integration
- Custom business metrics
- Prometheus endpoint

### 4. Documentation
- OpenAPI 3.0 specification
- Swagger UI integration
- Comprehensive API docs

### 5. Testing
- Unit tests for all layers
- Integration tests
- Test data management

---

## Development Best Practices

### 1. Code Quality
- Lombok for boilerplate reduction
- Builder pattern usage
- Immutable DTOs where possible

### 2. Performance
- Connection pool optimization
- Query optimization with indexes
- Pagination for large datasets

### 3. Security
- Input validation
- SQL injection prevention
- CORS configuration

### 4. Maintainability
- Clear separation of concerns
- Comprehensive documentation
- Consistent naming conventions

---

## Getting Started

### Prerequisites
- Java 17+
- Maven 3.6+
- MySQL 8.0+
- Docker (optional)

### Running the Application

1. **Database Setup**:
   ```sql
   CREATE DATABASE taskdb;
   ```

2. **Environment Variables**:
   ```bash
   export DB_USERNAME=root
   export DB_PASSWORD=your_password
   ```

3. **Run Application**:
   ```bash
   mvn spring-boot:run
   ```

4. **Access API Documentation**:
   - Swagger UI: http://localhost:8080/swagger-ui.html
   - Health Check: http://localhost:8080/actuator/health
   - Metrics: http://localhost:8080/actuator/prometheus

### Testing

```bash
# Run all tests
mvn test

# Run with coverage
mvn test jacoco:report

# Integration tests only
mvn test -Dtest="*IT"
```

---

## API Usage Examples

### Create Task
```bash
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Complete project documentation",
    "description": "Write comprehensive README",
    "priority": "HIGH",
    "dueDate": "2024-12-31T23:59:59"
  }'
```

### Get All Tasks
```bash
curl http://localhost:8080/api/tasks?page=0&size=10
```

### Update Task
```bash
curl -X PUT http://localhost:8080/api/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{
    "status": "COMPLETED"
  }'
```

---

## Monitoring and Observability

### Health Checks
- Application health: `/actuator/health`
- Database connectivity verification
- Custom health indicators

### Metrics
- JVM metrics
- HTTP request metrics
- Custom business metrics
- Database connection pool metrics

### Logging
- Structured JSON logging in production
- Request/response logging
- Error tracking with stack traces

---

This comprehensive source code structure provides a solid foundation for a production-ready task management API with proper separation of concerns, comprehensive testing, and enterprise-level features.
