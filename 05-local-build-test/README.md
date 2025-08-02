# Local Build and Test Guide

Complete guide for building, testing, and running the Task Management API locally for development and validation.

## Development Environment Setup

### **Prerequisites**
```bash
# Required software versions
Java 17 (Amazon Corretto recommended)
Maven 3.9+
Docker 24.0+
Docker Compose 2.0+
Git 2.30+
curl (for API testing)
```

### **Environment Verification**
```bash
# Verify Java installation
java -version
# Expected: openjdk version "17.0.x" 2023-xx-xx

# Verify Maven installation
mvn -version
# Expected: Apache Maven 3.9.x

# Verify Docker installation
docker --version
docker-compose --version

# Verify Git installation
git --version
```

## Local Build Scripts

### **build.sh - Application Build Script**
```bash
#!/bin/bash
# scripts/build.sh
# Build script for Task Management API

set -e

echo "🚀 Starting Task Management API Build Process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v java &> /dev/null; then
        print_error "Java is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v mvn &> /dev/null; then
        print_error "Maven is not installed or not in PATH"
        exit 1
    fi
    
    # Check Java version
    JAVA_VERSION=$(java -version 2>&1 | grep -oP 'version "([0-9]+)' | grep -oP '[0-9]+' | head -1)
    if [ "$JAVA_VERSION" -lt 17 ]; then
        print_error "Java 17 or higher is required. Current version: $JAVA_VERSION"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Clean previous builds
clean_build() {
    print_status "Cleaning previous builds..."
    mvn clean -q
    
    # Remove logs directory
    if [ -d "logs" ]; then
        rm -rf logs
        print_status "Removed logs directory"
    fi
    
    print_success "Clean completed"
}

# Compile source code
compile_code() {
    print_status "Compiling source code..."
    mvn compile -q
    
    if [ $? -eq 0 ]; then
        print_success "Compilation successful"
    else
        print_error "Compilation failed"
        exit 1
    fi
}

# Run unit tests
run_tests() {
    print_status "Running unit tests..."
    mvn test -q
    
    if [ $? -eq 0 ]; then
        print_success "All tests passed"
    else
        print_error "Some tests failed"
        exit 1
    fi
}

# Generate test coverage report
generate_coverage() {
    print_status "Generating test coverage report..."
    mvn jacoco:report -q
    
    if [ -f "target/site/jacoco/index.html" ]; then
        print_success "Coverage report generated: target/site/jacoco/index.html"
    else
        print_warning "Coverage report not generated"
    fi
}

# Package application
package_app() {
    print_status "Packaging application..."
    mvn package -DskipTests -q
    
    if [ -f "target/task-management-api-1.0.0.jar" ]; then
        print_success "Application packaged successfully"
        
        # Show JAR file info
        JAR_SIZE=$(du -h target/task-management-api-1.0.0.jar | cut -f1)
        print_status "JAR file size: $JAR_SIZE"
    else
        print_error "Packaging failed"
        exit 1
    fi
}

# Security scan
security_scan() {
    print_status "Running security scan..."
    mvn org.owasp:dependency-check-maven:check -q || true
    
    if [ -f "target/dependency-check-report.html" ]; then
        print_success "Security scan completed: target/dependency-check-report.html"
    else
        print_warning "Security scan report not generated"
    fi
}

# Main execution
main() {
    echo "=================================================="
    echo "    Task Management API - Build Script"
    echo "=================================================="
    
    check_prerequisites
    clean_build
    compile_code
    run_tests
    generate_coverage
    package_app
    security_scan
    
    echo "=================================================="
    print_success "Build process completed successfully! 🎉"
    echo "=================================================="
    
    echo ""
    echo "📦 Artifacts generated:"
    echo "   - JAR file: target/task-management-api-1.0.0.jar"
    echo "   - Test coverage: target/site/jacoco/index.html"
    echo "   - Security report: target/dependency-check-report.html"
    echo ""
    echo "🚀 Next steps:"
    echo "   - Run locally: ./scripts/run-local.sh"
    echo "   - Run tests: ./scripts/test.sh"
    echo "   - Build Docker: docker build -t task-api ."
}

# Execute main function
main "$@"
```

### **test.sh - Comprehensive Testing Script**
```bash
#!/bin/bash
# scripts/test.sh
# Comprehensive testing script for Task Management API

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Unit tests
run_unit_tests() {
    print_status "Running unit tests..."
    mvn test -Dtest="*Test" -q
    
    if [ $? -eq 0 ]; then
        print_success "Unit tests passed"
    else
        print_error "Unit tests failed"
        return 1
    fi
}

# Integration tests
run_integration_tests() {
    print_status "Running integration tests..."
    mvn test -Dtest="*IT" -q
    
    if [ $? -eq 0 ]; then
        print_success "Integration tests passed"
    else
        print_error "Integration tests failed"
        return 1
    fi
}

# API contract tests
run_contract_tests() {
    print_status "Running API contract tests..."
    
    # Start application in background for testing
    java -jar target/task-management-api-1.0.0.jar \
        --spring.profiles.active=test \
        --server.port=8081 &
    
    APP_PID=$!
    
    # Wait for application to start
    sleep 30
    
    # Test API endpoints
    test_health_endpoint
    test_task_crud_operations
    
    # Stop application
    kill $APP_PID
    wait $APP_PID 2>/dev/null || true
}

# Test health endpoint
test_health_endpoint() {
    print_status "Testing health endpoint..."
    
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/actuator/health)
    
    if [ "$RESPONSE" = "200" ]; then
        print_success "Health endpoint test passed"
    else
        print_error "Health endpoint test failed (HTTP $RESPONSE)"
        return 1
    fi
}

# Test CRUD operations
test_task_crud_operations() {
    print_status "Testing task CRUD operations..."
    
    # Create task
    CREATE_RESPONSE=$(curl -s -X POST http://localhost:8081/api/v1/tasks \
        -H "Content-Type: application/json" \
        -d '{
            "title": "Test Task",
            "description": "This is a test task",
            "status": "TODO",
            "priority": "HIGH"
        }')
    
    TASK_ID=$(echo $CREATE_RESPONSE | grep -o '"id":[0-9]*' | grep -o '[0-9]*')
    
    if [ -n "$TASK_ID" ]; then
        print_success "Task creation test passed (ID: $TASK_ID)"
    else
        print_error "Task creation test failed"
        return 1
    fi
    
    # Get task
    GET_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/api/v1/tasks/$TASK_ID)
    
    if [ "$GET_RESPONSE" = "200" ]; then
        print_success "Task retrieval test passed"
    else
        print_error "Task retrieval test failed (HTTP $GET_RESPONSE)"
        return 1
    fi
    
    # Update task
    UPDATE_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT http://localhost:8081/api/v1/tasks/$TASK_ID \
        -H "Content-Type: application/json" \
        -d '{"status": "IN_PROGRESS"}')
    
    if [ "$UPDATE_RESPONSE" = "200" ]; then
        print_success "Task update test passed"
    else
        print_error "Task update test failed (HTTP $UPDATE_RESPONSE)"
        return 1
    fi
    
    # Delete task
    DELETE_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE http://localhost:8081/api/v1/tasks/$TASK_ID)
    
    if [ "$DELETE_RESPONSE" = "204" ]; then
        print_success "Task deletion test passed"
    else
        print_error "Task deletion test failed (HTTP $DELETE_RESPONSE)"
        return 1
    fi
}

# Performance tests
run_performance_tests() {
    print_status "Running performance tests..."
    
    # Simple load test with curl
    print_status "Running basic load test (100 requests)..."
    
    for i in {1..100}; do
        curl -s -o /dev/null http://localhost:8081/actuator/health &
    done
    
    wait
    print_success "Basic load test completed"
}

# Security tests
run_security_tests() {
    print_status "Running security tests..."
    
    # Test for common vulnerabilities
    print_status "Testing for SQL injection..."
    
    INJECTION_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
        "http://localhost:8081/api/v1/tasks?id=1'; DROP TABLE tasks; --")
    
    if [ "$INJECTION_RESPONSE" = "400" ] || [ "$INJECTION_RESPONSE" = "404" ]; then
        print_success "SQL injection protection test passed"
    else
        print_error "SQL injection protection test failed"
        return 1
    fi
}

# Generate test reports
generate_test_reports() {
    print_status "Generating test reports..."
    
    # Surefire reports
    mvn surefire-report:report -q
    
    # JaCoCo coverage report
    mvn jacoco:report -q
    
    print_success "Test reports generated"
    echo "   - Test results: target/site/surefire-report.html"
    echo "   - Coverage report: target/site/jacoco/index.html"
}

# Main execution
main() {
    echo "=================================================="
    echo "    Task Management API - Test Suite"
    echo "=================================================="
    
    # Build application first
    if [ ! -f "target/task-management-api-1.0.0.jar" ]; then
        print_status "Building application first..."
        ./scripts/build.sh
    fi
    
    # Run all test suites
    run_unit_tests
    run_integration_tests
    generate_test_reports
    
    echo "=================================================="
    print_success "All tests completed successfully! ✅"
    echo "=================================================="
}

# Execute main function
main "$@"
```

### **run-local.sh - Local Execution Script**
```bash
#!/bin/bash
# scripts/run-local.sh
# Script to run Task Management API locally

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
APP_PORT=8080
PROFILE=${1:-dev}
JAR_FILE="target/task-management-api-1.0.0.jar"

# Check if JAR file exists
check_jar_file() {
    if [ ! -f "$JAR_FILE" ]; then
        print_error "JAR file not found: $JAR_FILE"
        print_status "Building application..."
        ./scripts/build.sh
    fi
}

# Start database services
start_dependencies() {
    print_status "Starting database services..."
    
    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    
    # Start MySQL and Redis using Docker Compose
    docker-compose up -d mysql redis
    
    # Wait for services to be ready
    print_status "Waiting for database services to be ready..."
    
    # Wait for MySQL
    for i in {1..30}; do
        if docker-compose exec mysql mysqladmin ping -h localhost -u root -prootpass > /dev/null 2>&1; then
            print_success "MySQL is ready"
            break
        fi
        sleep 2
    done
    
    # Wait for Redis
    for i in {1..30}; do
        if docker-compose exec redis redis-cli ping > /dev/null 2>&1; then
            print_success "Redis is ready"
            break
        fi
        sleep 2
    done
}

# Run application
run_application() {
    print_status "Starting Task Management API..."
    print_status "Profile: $PROFILE"
    print_status "Port: $APP_PORT"
    
    # Set JVM options
    JAVA_OPTS="-Xmx512m -Xms256m -XX:+UseG1GC"
    
    # Run application
    java $JAVA_OPTS -jar $JAR_FILE \
        --spring.profiles.active=$PROFILE \
        --server.port=$APP_PORT \
        --spring.datasource.url=jdbc:mysql://localhost:3306/taskdb \
        --spring.datasource.username=taskuser \
        --spring.datasource.password=taskpass \
        --spring.redis.host=localhost \
        --spring.redis.port=6379 &
    
    APP_PID=$!
    
    # Wait for application to start
    print_status "Waiting for application to start..."
    
    for i in {1..60}; do
        if curl -s http://localhost:$APP_PORT/actuator/health > /dev/null 2>&1; then
            print_success "Application started successfully!"
            break
        fi
        sleep 2
    done
    
    # Display application info
    echo ""
    echo "=================================================="
    echo "🚀 Task Management API is running!"
    echo "=================================================="
    echo "📍 Application URL: http://localhost:$APP_PORT"
    echo "📊 Health Check: http://localhost:$APP_PORT/actuator/health"
    echo "📚 API Documentation: http://localhost:$APP_PORT/swagger-ui.html"
    echo "📈 Metrics: http://localhost:$APP_PORT/actuator/prometheus"
    echo ""
    echo "🔧 Database Services:"
    echo "   MySQL: localhost:3306 (taskuser/taskpass)"
    echo "   Redis: localhost:6379"
    echo ""
    echo "📝 Logs: tail -f logs/task-api.log"
    echo "🛑 Stop: Ctrl+C or kill $APP_PID"
    echo "=================================================="
    
    # Wait for user to stop
    wait $APP_PID
}

# Cleanup function
cleanup() {
    print_status "Shutting down services..."
    
    # Stop application if running
    if [ ! -z "$APP_PID" ]; then
        kill $APP_PID 2>/dev/null || true
    fi
    
    # Stop Docker services
    docker-compose down
    
    print_success "Cleanup completed"
}

# Trap cleanup on exit
trap cleanup EXIT

# Main execution
main() {
    echo "=================================================="
    echo "    Task Management API - Local Runner"
    echo "=================================================="
    
    check_jar_file
    start_dependencies
    run_application
}

# Execute main function
main "$@"
```

## Testing Strategies

### **Unit Testing with JUnit 5**
```java
// src/test/java/com/taskapi/service/TaskServiceTest.java
@ExtendWith(MockitoExtension.class)
class TaskServiceTest {
    
    @Mock
    private TaskRepository taskRepository;
    
    @InjectMocks
    private TaskServiceImpl taskService;
    
    @Test
    @DisplayName("Should create task successfully")
    void shouldCreateTaskSuccessfully() {
        // Given
        TaskCreateRequest request = new TaskCreateRequest();
        request.setTitle("Test Task");
        request.setDescription("Test Description");
        request.setStatus(TaskStatus.TODO);
        request.setPriority(Priority.HIGH);
        
        Task savedTask = new Task();
        savedTask.setId(1L);
        savedTask.setTitle("Test Task");
        savedTask.setStatus(TaskStatus.TODO);
        
        when(taskRepository.save(any(Task.class))).thenReturn(savedTask);
        
        // When
        TaskResponse response = taskService.createTask(request);
        
        // Then
        assertThat(response).isNotNull();
        assertThat(response.getId()).isEqualTo(1L);
        assertThat(response.getTitle()).isEqualTo("Test Task");
        assertThat(response.getStatus()).isEqualTo(TaskStatus.TODO);
        
        verify(taskRepository).save(any(Task.class));
    }
    
    @Test
    @DisplayName("Should throw exception when task not found")
    void shouldThrowExceptionWhenTaskNotFound() {
        // Given
        Long taskId = 999L;
        when(taskRepository.findById(taskId)).thenReturn(Optional.empty());
        
        // When & Then
        assertThatThrownBy(() -> taskService.getTaskById(taskId))
            .isInstanceOf(TaskNotFoundException.class)
            .hasMessage("Task not found with id: " + taskId);
    }
}
```

### **Integration Testing with TestContainers**
```java
// src/test/java/com/taskapi/integration/TaskControllerIT.java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
class TaskControllerIT {
    
    @Container
    static MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0")
            .withDatabaseName("testdb")
            .withUsername("test")
            .withPassword("test");
    
    @Autowired
    private TestRestTemplate restTemplate;
    
    @Autowired
    private TaskRepository taskRepository;
    
    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", mysql::getJdbcUrl);
        registry.add("spring.datasource.username", mysql::getUsername);
        registry.add("spring.datasource.password", mysql::getPassword);
    }
    
    @Test
    void shouldCreateAndRetrieveTask() {
        // Given
        TaskCreateRequest request = new TaskCreateRequest();
        request.setTitle("Integration Test Task");
        request.setDescription("Test Description");
        request.setStatus(TaskStatus.TODO);
        request.setPriority(Priority.MEDIUM);
        
        // When - Create task
        ResponseEntity<TaskResponse> createResponse = restTemplate.postForEntity(
            "/api/v1/tasks", request, TaskResponse.class);
        
        // Then - Verify creation
        assertThat(createResponse.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(createResponse.getBody()).isNotNull();
        
        Long taskId = createResponse.getBody().getId();
        
        // When - Retrieve task
        ResponseEntity<TaskResponse> getResponse = restTemplate.getForEntity(
            "/api/v1/tasks/" + taskId, TaskResponse.class);
        
        // Then - Verify retrieval
        assertThat(getResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(getResponse.getBody().getTitle()).isEqualTo("Integration Test Task");
    }
}
```

## API Testing Scripts

### **api-test.sh - API Endpoint Testing**
```bash
#!/bin/bash
# scripts/api-test.sh
# API endpoint testing script

BASE_URL="http://localhost:8080"
API_URL="$BASE_URL/api/v1"

# Test health endpoint
test_health() {
    echo "Testing health endpoint..."
    curl -s "$BASE_URL/actuator/health" | jq '.'
}

# Test task creation
test_create_task() {
    echo "Testing task creation..."
    curl -s -X POST "$API_URL/tasks" \
        -H "Content-Type: application/json" \
        -d '{
            "title": "API Test Task",
            "description": "Created via API test",
            "status": "TODO",
            "priority": "HIGH",
            "assigneeEmail": "test@example.com"
        }' | jq '.'
}

# Test task listing
test_list_tasks() {
    echo "Testing task listing..."
    curl -s "$API_URL/tasks" | jq '.'
}

# Run all tests
echo "Starting API tests..."
test_health
test_create_task
test_list_tasks
echo "API tests completed!"
```

## Performance Testing

### **load-test.sh - Simple Load Testing**
```bash
#!/bin/bash
# scripts/load-test.sh
# Simple load testing script

BASE_URL="http://localhost:8080"
CONCURRENT_USERS=10
REQUESTS_PER_USER=100

echo "Starting load test..."
echo "Concurrent users: $CONCURRENT_USERS"
echo "Requests per user: $REQUESTS_PER_USER"

# Function to make requests
make_requests() {
    for i in $(seq 1 $REQUESTS_PER_USER); do
        curl -s -o /dev/null "$BASE_URL/actuator/health"
    done
}

# Start concurrent users
for i in $(seq 1 $CONCURRENT_USERS); do
    make_requests &
done

# Wait for all requests to complete
wait

echo "Load test completed!"
```

## Development Workflow

### **Daily Development Cycle**
```bash
# 1. Pull latest changes
git pull origin main

# 2. Build and test
./scripts/build.sh
./scripts/test.sh

# 3. Run locally for development
./scripts/run-local.sh dev

# 4. Make changes and test
# ... code changes ...

# 5. Quick test cycle
mvn test -Dtest=TaskServiceTest
./scripts/api-test.sh

# 6. Commit changes
git add .
git commit -m "feat: add new task filtering feature"
git push origin feature/task-filtering
```

### **Pre-commit Validation**
```bash
#!/bin/bash
# scripts/pre-commit.sh
# Pre-commit validation script

echo "Running pre-commit validation..."

# Format code
mvn spotless:apply -q

# Run tests
./scripts/test.sh

# Security scan
mvn org.owasp:dependency-check-maven:check -q

# Build application
./scripts/build.sh

echo "Pre-commit validation completed!"
```

This comprehensive local development setup provides all the tools and scripts needed for efficient development, testing, and validation of the Task Management API.
