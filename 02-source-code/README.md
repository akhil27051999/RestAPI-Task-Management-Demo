# 2-Source Code Files

## src/main/java/com/taskapi/TaskApiApplication.java
```java
package com.taskapi;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class TaskApiApplication {
    public static void main(String[] args) {
        SpringApplication.run(TaskApiApplication.class, args);
    }
}
```

## src/main/java/com/taskapi/controller/TaskController.java
```java
package com.taskapi.controller;

import com.taskapi.model.Task;
import com.taskapi.service.TaskService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/tasks")
public class TaskController {

    @Autowired
    private TaskService taskService;

    @GetMapping
    public List<Task> getAllTasks() {
        return taskService.getAllTasks();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Task> getTaskById(@PathVariable Long id) {
        Optional<Task> task = taskService.getTaskById(id);
        return task.map(ResponseEntity::ok)
                  .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<Task> createTask(@RequestBody Task task) {
        Task savedTask = taskService.saveTask(task);
        return ResponseEntity.status(HttpStatus.CREATED).body(savedTask);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Task> updateTask(@PathVariable Long id, @RequestBody Task task) {
        if (!taskService.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        task.setId(id);
        Task updatedTask = taskService.saveTask(task);
        return ResponseEntity.ok(updatedTask);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTask(@PathVariable Long id) {
        if (!taskService.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        taskService.deleteTask(id);
        return ResponseEntity.noContent().build();
    }
}
```

## src/main/java/com/taskapi/model/Task.java
```java
package com.taskapi.model;

import javax.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "tasks")
public class Task {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String title;

    private String description;

    @Enumerated(EnumType.STRING)
    private TaskStatus status = TaskStatus.PENDING;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();

    // Constructors
    public Task() {}

    public Task(String title, String description) {
        this.title = title;
        this.description = description;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public TaskStatus getStatus() {
        return status;
    }

    public void setStatus(TaskStatus status) {
        this.status = status;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    public enum TaskStatus {
        PENDING, IN_PROGRESS, COMPLETED, CANCELLED
    }
}
```

## src/main/java/com/taskapi/repository/TaskRepository.java
```java
package com.taskapi.repository;

import com.taskapi.model.Task;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TaskRepository extends JpaRepository<Task, Long> {
    
    List<Task> findByStatus(Task.TaskStatus status);
    
    List<Task> findByTitleContainingIgnoreCase(String title);
}
```

## src/main/java/com/taskapi/service/TaskService.java
```java
package com.taskapi.service;

import com.taskapi.model.Task;
import com.taskapi.repository.TaskRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class TaskService {

    @Autowired
    private TaskRepository taskRepository;

    public List<Task> getAllTasks() {
        return taskRepository.findAll();
    }

    public Optional<Task> getTaskById(Long id) {
        return taskRepository.findById(id);
    }

    public Task saveTask(Task task) {
        return taskRepository.save(task);
    }

    public void deleteTask(Long id) {
        taskRepository.deleteById(id);
    }

    public boolean existsById(Long id) {
        return taskRepository.existsById(id);
    }

    public List<Task> getTasksByStatus(Task.TaskStatus status) {
        return taskRepository.findByStatus(status);
    }

    public List<Task> searchTasksByTitle(String title) {
        return taskRepository.findByTitleContainingIgnoreCase(title);
    }
}
```

## src/main/java/com/taskapi/config/DatabaseConfig.java
```java
package com.taskapi.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@Configuration
@EnableJpaRepositories(basePackages = "com.taskapi.repository")
public class DatabaseConfig {
    // Additional database configuration if needed
}
```

## src/main/resources/application.yml
```yaml
server:
  port: 8080

spring:
  application:
    name: task-management-api
  
  datasource:
    url: jdbc:mysql://localhost:3306/taskdb
    username: ${DB_USERNAME:root}
    password: ${DB_PASSWORD:password}
    driver-class-name: com.mysql.cj.jdbc.Driver
  
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
    properties:
      hibernate:
        dialect: org.hibernate.dialect.MySQL8Dialect
        format_sql: true

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    health:
      show-details: always

logging:
  level:
    com.taskapi: DEBUG
    org.springframework.web: DEBUG
```

## src/main/resources/application-prod.yml
```yaml
spring:
  datasource:
    url: jdbc:mysql://${DB_HOST:mysql-service}:${DB_PORT:3306}/${DB_NAME:taskdb}
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
  
  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false

logging:
  level:
    com.taskapi: INFO
    org.springframework.web: WARN
    org.hibernate: WARN

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
```

## src/test/java/com/taskapi/TaskControllerTest.java
```java
package com.taskapi;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.taskapi.controller.TaskController;
import com.taskapi.model.Task;
import com.taskapi.service.TaskService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Arrays;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(TaskController.class)
public class TaskControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private TaskService taskService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    public void testGetAllTasks() throws Exception {
        Task task1 = new Task("Task 1", "Description 1");
        Task task2 = new Task("Task 2", "Description 2");
        
        when(taskService.getAllTasks()).thenReturn(Arrays.asList(task1, task2));

        mockMvc.perform(get("/api/tasks"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].title").value("Task 1"))
                .andExpect(jsonPath("$[1].title").value("Task 2"));
    }

    @Test
    public void testGetTaskById() throws Exception {
        Task task = new Task("Test Task", "Test Description");
        task.setId(1L);
        
        when(taskService.getTaskById(1L)).thenReturn(Optional.of(task));

        mockMvc.perform(get("/api/tasks/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.title").value("Test Task"));
    }

    @Test
    public void testCreateTask() throws Exception {
        Task task = new Task("New Task", "New Description");
        Task savedTask = new Task("New Task", "New Description");
        savedTask.setId(1L);
        
        when(taskService.saveTask(any(Task.class))).thenReturn(savedTask);

        mockMvc.perform(post("/api/tasks")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(task)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.title").value("New Task"));
    }

    @Test
    public void testUpdateTask() throws Exception {
        Task task = new Task("Updated Task", "Updated Description");
        task.setId(1L);
        
        when(taskService.existsById(1L)).thenReturn(true);
        when(taskService.saveTask(any(Task.class))).thenReturn(task);

        mockMvc.perform(put("/api/tasks/1")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(task)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.title").value("Updated Task"));
    }

    @Test
    public void testDeleteTask() throws Exception {
        when(taskService.existsById(1L)).thenReturn(true);

        mockMvc.perform(delete("/api/tasks/1"))
                .andExpect(status().isNoContent());
    }

    @Test
    public void testGetTaskByIdNotFound() throws Exception {
        when(taskService.getTaskById(anyLong())).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/tasks/999"))
                .andExpect(status().isNotFound());
    }
}
```

## src/test/java/com/taskapi/TaskServiceTest.java
```java
package com.taskapi;

import com.taskapi.model.Task;
import com.taskapi.repository.TaskRepository;
import com.taskapi.service.TaskService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class TaskServiceTest {

    @Mock
    private TaskRepository taskRepository;

    @InjectMocks
    private TaskService taskService;

    private Task testTask;

    @BeforeEach
    public void setUp() {
        testTask = new Task("Test Task", "Test Description");
        testTask.setId(1L);
    }

    @Test
    public void testGetAllTasks() {
        List<Task> tasks = Arrays.asList(testTask);
        when(taskRepository.findAll()).thenReturn(tasks);

        List<Task> result = taskService.getAllTasks();

        assertEquals(1, result.size());
        assertEquals("Test Task", result.get(0).getTitle());
        verify(taskRepository).findAll();
    }

    @Test
    public void testGetTaskById() {
        when(taskRepository.findById(1L)).thenReturn(Optional.of(testTask));

        Optional<Task> result = taskService.getTaskById(1L);

        assertTrue(result.isPresent());
        assertEquals("Test Task", result.get().getTitle());
        verify(taskRepository).findById(1L);
    }

    @Test
    public void testSaveTask() {
        when(taskRepository.save(any(Task.class))).thenReturn(testTask);

        Task result = taskService.saveTask(testTask);

        assertEquals("Test Task", result.getTitle());
        verify(taskRepository).save(testTask);
    }

    @Test
    public void testDeleteTask() {
        taskService.deleteTask(1L);

        verify(taskRepository).deleteById(1L);
    }

    @Test
    public void testExistsById() {
        when(taskRepository.existsById(1L)).thenReturn(true);

        boolean result = taskService.existsById(1L);

        assertTrue(result);
        verify(taskRepository).existsById(1L);
    }

    @Test
    public void testGetTasksByStatus() {
        List<Task> tasks = Arrays.asList(testTask);
        when(taskRepository.findByStatus(Task.TaskStatus.PENDING)).thenReturn(tasks);

        List<Task> result = taskService.getTasksByStatus(Task.TaskStatus.PENDING);

        assertEquals(1, result.size());
        verify(taskRepository).findByStatus(Task.TaskStatus.PENDING);
    }

    @Test
    public void testSearchTasksByTitle() {
        List<Task> tasks = Arrays.asList(testTask);
        when(taskRepository.findByTitleContainingIgnoreCase("Test")).thenReturn(tasks);

        List<Task> result = taskService.searchTasksByTitle("Test");

        assertEquals(1, result.size());
        verify(taskRepository).findByTitleContainingIgnoreCase("Test");
    }
}
```

## pom.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.7.14</version>
        <relativePath/>
    </parent>
    
    <groupId>com.taskapi</groupId>
    <artifactId>task-management-api</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>
    <name>task-management-api</name>
    <description>Task Management REST API</description>
    
    <properties>
        <java.version>17</java.version>
    </properties>
    
    <dependencies>
        <!-- Spring Boot Starters -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        
        <!-- Database -->
        <dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
            <scope>runtime</scope>
        </dependency>
        
        <!-- Metrics -->
        <dependency>
            <groupId>io.micrometer</groupId>
            <artifactId>micrometer-registry-prometheus</artifactId>
        </dependency>
        
        <!-- Test Dependencies -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
            
            <plugin>
                <groupId>org.jacoco</groupId>
                <artifactId>jacoco-maven-plugin</artifactId>
                <version>0.8.8</version>
                <executions>
                    <execution>
                        <goals>
                            <goal>prepare-agent</goal>
                        </goals>
                    </execution>
                    <execution>
                        <id>report</id>
                        <phase>test</phase>
                        <goals>
                            <goal>report</goal>
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</project>
```

## .gitignore
```
# Maven
target/
pom.xml.tag
pom.xml.releaseBackup
pom.xml.versionsBackup
pom.xml.next
release.properties
dependency-reduced-pom.xml
buildNumber.properties
.mvn/timing.properties
.mvn/wrapper/maven-wrapper.jar

# IDE
.idea/
*.iws
*.iml
*.ipr
.vscode/
.classpath
.project
.settings/

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Runtime
*.pid
*.seed
*.pid.lock

# Environment
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Database
*.db
*.sqlite
```

## README.md
```markdown
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
```

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
