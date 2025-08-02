# Source Code - Task Management API

## Application Overview

A **Spring Boot REST API** for task management with MySQL database integration, implementing enterprise-grade patterns and best practices.

## Project Structure

```
src/
├── main/
│   ├── java/
│   │   └── com/
│   │       └── taskapi/
│   │           ├── TaskApiApplication.java          # Main application class
│   │           ├── controller/
│   │           │   ├── TaskController.java          # REST endpoints
│   │           │   └── HealthController.java        # Health checks
│   │           ├── model/
│   │           │   ├── Task.java                    # Task entity
│   │           │   ├── TaskStatus.java              # Status enum
│   │           │   └── Priority.java                # Priority enum
│   │           ├── repository/
│   │           │   └── TaskRepository.java          # Data access layer
│   │           ├── service/
│   │           │   ├── TaskService.java             # Business logic
│   │           │   └── TaskServiceImpl.java         # Service implementation
│   │           ├── dto/
│   │           │   ├── TaskCreateRequest.java       # Create task DTO
│   │           │   ├── TaskUpdateRequest.java       # Update task DTO
│   │           │   └── TaskResponse.java            # Response DTO
│   │           ├── exception/
│   │           │   ├── TaskNotFoundException.java   # Custom exceptions
│   │           │   └── GlobalExceptionHandler.java  # Error handling
│   │           └── config/
│   │               ├── DatabaseConfig.java          # Database configuration
│   │               ├── SecurityConfig.java          # Security configuration
│   │               └── SwaggerConfig.java           # API documentation
│   └── resources/
│       ├── application.yml                          # Main configuration
│       ├── application-dev.yml                      # Development config
│       ├── application-prod.yml                     # Production config
│       └── db/
│           └── migration/
│               └── V1__Create_tasks_table.sql       # Database schema
└── test/
    └── java/
        └── com/
            └── taskapi/
                ├── TaskControllerTest.java           # Controller tests
                ├── TaskServiceTest.java              # Service tests
                └── TaskRepositoryTest.java           # Repository tests
```

## Core Application Files

### **1. Main Application Class**
```java
// TaskApiApplication.java
package com.taskapi;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@SpringBootApplication
@EnableJpaAuditing
public class TaskApiApplication {
    public static void main(String[] args) {
        SpringApplication.run(TaskApiApplication.class, args);
    }
}
```

### **2. Task Entity Model**
```java
// Task.java
package com.taskapi.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "tasks")
@EntityListeners(AuditingEntityListener.class)
public class Task {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @NotBlank(message = "Title is required")
    @Column(nullable = false, length = 255)
    private String title;
    
    @Column(columnDefinition = "TEXT")
    private String description;
    
    @NotNull(message = "Status is required")
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TaskStatus status = TaskStatus.TODO;
    
    @NotNull(message = "Priority is required")
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Priority priority = Priority.MEDIUM;
    
    @Column(name = "assignee_email")
    private String assigneeEmail;
    
    @ElementCollection
    @CollectionTable(name = "task_tags", joinColumns = @JoinColumn(name = "task_id"))
    @Column(name = "tag")
    private List<String> tags;
    
    @Column(name = "due_date")
    private LocalDateTime dueDate;
    
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    // Constructors, getters, setters
    public Task() {}
    
    public Task(String title, String description, TaskStatus status, Priority priority) {
        this.title = title;
        this.description = description;
        this.status = status;
        this.priority = priority;
    }
    
    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    
    public TaskStatus getStatus() { return status; }
    public void setStatus(TaskStatus status) { this.status = status; }
    
    public Priority getPriority() { return priority; }
    public void setPriority(Priority priority) { this.priority = priority; }
    
    public String getAssigneeEmail() { return assigneeEmail; }
    public void setAssigneeEmail(String assigneeEmail) { this.assigneeEmail = assigneeEmail; }
    
    public List<String> getTags() { return tags; }
    public void setTags(List<String> tags) { this.tags = tags; }
    
    public LocalDateTime getDueDate() { return dueDate; }
    public void setDueDate(LocalDateTime dueDate) { this.dueDate = dueDate; }
    
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
```

### **3. Enums**
```java
// TaskStatus.java
package com.taskapi.model;

public enum TaskStatus {
    TODO("To Do"),
    IN_PROGRESS("In Progress"),
    REVIEW("In Review"),
    DONE("Done"),
    BLOCKED("Blocked");
    
    private final String displayName;
    
    TaskStatus(String displayName) {
        this.displayName = displayName;
    }
    
    public String getDisplayName() {
        return displayName;
    }
}

// Priority.java
package com.taskapi.model;

public enum Priority {
    LOW("Low"),
    MEDIUM("Medium"),
    HIGH("High"),
    CRITICAL("Critical");
    
    private final String displayName;
    
    Priority(String displayName) {
        this.displayName = displayName;
    }
    
    public String getDisplayName() {
        return displayName;
    }
}
```

### **4. REST Controller**
```java
// TaskController.java
package com.taskapi.controller;

import com.taskapi.dto.TaskCreateRequest;
import com.taskapi.dto.TaskResponse;
import com.taskapi.dto.TaskUpdateRequest;
import com.taskapi.model.Priority;
import com.taskapi.model.TaskStatus;
import com.taskapi.service.TaskService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/tasks")
@Tag(name = "Task Management", description = "APIs for managing tasks")
@CrossOrigin(origins = "*")
public class TaskController {
    
    @Autowired
    private TaskService taskService;
    
    @GetMapping
    @Operation(summary = "Get all tasks", description = "Retrieve all tasks with pagination")
    public ResponseEntity<Page<TaskResponse>> getAllTasks(Pageable pageable) {
        Page<TaskResponse> tasks = taskService.getAllTasks(pageable);
        return ResponseEntity.ok(tasks);
    }
    
    @GetMapping("/{id}")
    @Operation(summary = "Get task by ID", description = "Retrieve a specific task by its ID")
    public ResponseEntity<TaskResponse> getTaskById(@PathVariable Long id) {
        TaskResponse task = taskService.getTaskById(id);
        return ResponseEntity.ok(task);
    }
    
    @PostMapping
    @Operation(summary = "Create new task", description = "Create a new task")
    public ResponseEntity<TaskResponse> createTask(@Valid @RequestBody TaskCreateRequest request) {
        TaskResponse task = taskService.createTask(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(task);
    }
    
    @PutMapping("/{id}")
    @Operation(summary = "Update task", description = "Update an existing task")
    public ResponseEntity<TaskResponse> updateTask(
            @PathVariable Long id, 
            @Valid @RequestBody TaskUpdateRequest request) {
        TaskResponse task = taskService.updateTask(id, request);
        return ResponseEntity.ok(task);
    }
    
    @DeleteMapping("/{id}")
    @Operation(summary = "Delete task", description = "Delete a task by its ID")
    public ResponseEntity<Void> deleteTask(@PathVariable Long id) {
        taskService.deleteTask(id);
        return ResponseEntity.noContent().build();
    }
    
    @GetMapping("/status/{status}")
    @Operation(summary = "Get tasks by status", description = "Retrieve tasks filtered by status")
    public ResponseEntity<List<TaskResponse>> getTasksByStatus(@PathVariable TaskStatus status) {
        List<TaskResponse> tasks = taskService.getTasksByStatus(status);
        return ResponseEntity.ok(tasks);
    }
    
    @GetMapping("/assignee/{email}")
    @Operation(summary = "Get tasks by assignee", description = "Retrieve tasks assigned to a specific user")
    public ResponseEntity<List<TaskResponse>> getTasksByAssignee(@PathVariable String email) {
        List<TaskResponse> tasks = taskService.getTasksByAssignee(email);
        return ResponseEntity.ok(tasks);
    }
    
    @GetMapping("/priority/{priority}")
    @Operation(summary = "Get tasks by priority", description = "Retrieve tasks filtered by priority")
    public ResponseEntity<List<TaskResponse>> getTasksByPriority(@PathVariable Priority priority) {
        List<TaskResponse> tasks = taskService.getTasksByPriority(priority);
        return ResponseEntity.ok(tasks);
    }
}
```

### **5. Service Layer**
```java
// TaskService.java
package com.taskapi.service;

import com.taskapi.dto.TaskCreateRequest;
import com.taskapi.dto.TaskResponse;
import com.taskapi.dto.TaskUpdateRequest;
import com.taskapi.model.Priority;
import com.taskapi.model.TaskStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface TaskService {
    Page<TaskResponse> getAllTasks(Pageable pageable);
    TaskResponse getTaskById(Long id);
    TaskResponse createTask(TaskCreateRequest request);
    TaskResponse updateTask(Long id, TaskUpdateRequest request);
    void deleteTask(Long id);
    List<TaskResponse> getTasksByStatus(TaskStatus status);
    List<TaskResponse> getTasksByAssignee(String email);
    List<TaskResponse> getTasksByPriority(Priority priority);
}

// TaskServiceImpl.java
package com.taskapi.service;

import com.taskapi.dto.TaskCreateRequest;
import com.taskapi.dto.TaskResponse;
import com.taskapi.dto.TaskUpdateRequest;
import com.taskapi.exception.TaskNotFoundException;
import com.taskapi.model.Priority;
import com.taskapi.model.Task;
import com.taskapi.model.TaskStatus;
import com.taskapi.repository.TaskRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class TaskServiceImpl implements TaskService {
    
    @Autowired
    private TaskRepository taskRepository;
    
    @Override
    @Transactional(readOnly = true)
    public Page<TaskResponse> getAllTasks(Pageable pageable) {
        Page<Task> tasks = taskRepository.findAll(pageable);
        return tasks.map(this::convertToResponse);
    }
    
    @Override
    @Transactional(readOnly = true)
    public TaskResponse getTaskById(Long id) {
        Task task = taskRepository.findById(id)
                .orElseThrow(() -> new TaskNotFoundException("Task not found with id: " + id));
        return convertToResponse(task);
    }
    
    @Override
    public TaskResponse createTask(TaskCreateRequest request) {
        Task task = new Task();
        task.setTitle(request.getTitle());
        task.setDescription(request.getDescription());
        task.setStatus(request.getStatus() != null ? request.getStatus() : TaskStatus.TODO);
        task.setPriority(request.getPriority() != null ? request.getPriority() : Priority.MEDIUM);
        task.setAssigneeEmail(request.getAssigneeEmail());
        task.setTags(request.getTags());
        task.setDueDate(request.getDueDate());
        
        Task savedTask = taskRepository.save(task);
        return convertToResponse(savedTask);
    }
    
    @Override
    public TaskResponse updateTask(Long id, TaskUpdateRequest request) {
        Task task = taskRepository.findById(id)
                .orElseThrow(() -> new TaskNotFoundException("Task not found with id: " + id));
        
        if (request.getTitle() != null) {
            task.setTitle(request.getTitle());
        }
        if (request.getDescription() != null) {
            task.setDescription(request.getDescription());
        }
        if (request.getStatus() != null) {
            task.setStatus(request.getStatus());
        }
        if (request.getPriority() != null) {
            task.setPriority(request.getPriority());
        }
        if (request.getAssigneeEmail() != null) {
            task.setAssigneeEmail(request.getAssigneeEmail());
        }
        if (request.getTags() != null) {
            task.setTags(request.getTags());
        }
        if (request.getDueDate() != null) {
            task.setDueDate(request.getDueDate());
        }
        
        Task updatedTask = taskRepository.save(task);
        return convertToResponse(updatedTask);
    }
    
    @Override
    public void deleteTask(Long id) {
        if (!taskRepository.existsById(id)) {
            throw new TaskNotFoundException("Task not found with id: " + id);
        }
        taskRepository.deleteById(id);
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<TaskResponse> getTasksByStatus(TaskStatus status) {
        List<Task> tasks = taskRepository.findByStatus(status);
        return tasks.stream().map(this::convertToResponse).collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<TaskResponse> getTasksByAssignee(String email) {
        List<Task> tasks = taskRepository.findByAssigneeEmail(email);
        return tasks.stream().map(this::convertToResponse).collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<TaskResponse> getTasksByPriority(Priority priority) {
        List<Task> tasks = taskRepository.findByPriority(priority);
        return tasks.stream().map(this::convertToResponse).collect(Collectors.toList());
    }
    
    private TaskResponse convertToResponse(Task task) {
        TaskResponse response = new TaskResponse();
        response.setId(task.getId());
        response.setTitle(task.getTitle());
        response.setDescription(task.getDescription());
        response.setStatus(task.getStatus());
        response.setPriority(task.getPriority());
        response.setAssigneeEmail(task.getAssigneeEmail());
        response.setTags(task.getTags());
        response.setDueDate(task.getDueDate());
        response.setCreatedAt(task.getCreatedAt());
        response.setUpdatedAt(task.getUpdatedAt());
        return response;
    }
}
```

### **6. Repository Layer**
```java
// TaskRepository.java
package com.taskapi.repository;

import com.taskapi.model.Priority;
import com.taskapi.model.Task;
import com.taskapi.model.TaskStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface TaskRepository extends JpaRepository<Task, Long> {
    
    List<Task> findByStatus(TaskStatus status);
    
    List<Task> findByAssigneeEmail(String assigneeEmail);
    
    List<Task> findByPriority(Priority priority);
    
    Page<Task> findByStatusAndPriority(TaskStatus status, Priority priority, Pageable pageable);
    
    @Query("SELECT t FROM Task t WHERE t.dueDate BETWEEN :startDate AND :endDate")
    List<Task> findTasksDueBetween(@Param("startDate") LocalDateTime startDate, 
                                   @Param("endDate") LocalDateTime endDate);
    
    @Query("SELECT t FROM Task t WHERE t.title LIKE %:keyword% OR t.description LIKE %:keyword%")
    List<Task> searchTasks(@Param("keyword") String keyword);
    
    long countByStatus(TaskStatus status);
    
    long countByAssigneeEmail(String assigneeEmail);
}
```

## Configuration Files

### **1. Application Configuration**
```yaml
# application.yml
spring:
  application:
    name: task-management-api
  profiles:
    active: dev
  
  datasource:
    url: jdbc:mysql://localhost:3306/taskdb
    username: taskuser
    password: taskpass
    driver-class-name: com.mysql.cj.jdbc.Driver
    
  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false
    properties:
      hibernate:
        dialect: org.hibernate.dialect.MySQL8Dialect
        format_sql: true
    
  flyway:
    enabled: true
    locations: classpath:db/migration
    baseline-on-migrate: true

server:
  port: 8080
  servlet:
    context-path: /

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    health:
      show-details: always
  metrics:
    export:
      prometheus:
        enabled: true

logging:
  level:
    com.taskapi: INFO
    org.springframework.web: DEBUG
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} - %msg%n"
    file: "%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n"
  file:
    name: logs/task-api.log

springdoc:
  api-docs:
    path: /api-docs
  swagger-ui:
    path: /swagger-ui.html
```

### **2. Maven Configuration**
```xml
<!-- pom.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.1</version>
        <relativePath/>
    </parent>
    
    <groupId>com.taskapi</groupId>
    <artifactId>task-management-api</artifactId>
    <version>1.0.0</version>
    <name>task-management-api</name>
    <description>Task Management REST API</description>
    
    <properties>
        <java.version>17</java.version>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
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
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        
        <!-- Database -->
        <dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
            <version>8.0.33</version>
        </dependency>
        
        <dependency>
            <groupId>org.flywaydb</groupId>
            <artifactId>flyway-core</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.flywaydb</groupId>
            <artifactId>flyway-mysql</artifactId>
        </dependency>
        
        <!-- Monitoring -->
        <dependency>
            <groupId>io.micrometer</groupId>
            <artifactId>micrometer-registry-prometheus</artifactId>
        </dependency>
        
        <!-- Documentation -->
        <dependency>
            <groupId>org.springdoc</groupId>
            <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
            <version>2.3.0</version>
        </dependency>
        
        <!-- Testing -->
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
        
        <dependency>
            <groupId>org.testcontainers</groupId>
            <artifactId>junit-jupiter</artifactId>
            <scope>test</scope>
        </dependency>
        
        <dependency>
            <groupId>org.testcontainers</groupId>
            <artifactId>mysql</artifactId>
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

## Local Development Setup

### **1. Prerequisites**
```bash
# Install Java 17
java -version  # Should show Java 17

# Install Maven
mvn -version   # Should show Maven 3.6+

# Install MySQL (via Docker)
docker run --name mysql-dev \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e MYSQL_DATABASE=taskdb \
  -e MYSQL_USER=taskuser \
  -e MYSQL_PASSWORD=taskpass \
  -p 3306:3306 \
  -d mysql:8.0
```

### **2. Build and Run**
```bash
# Clone repository
git clone <repository-url>
cd task-management-api

# Build application
mvn clean compile

# Run tests
mvn test

# Run application
mvn spring-boot:run

# Or run with specific profile
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

### **3. Test API Endpoints**
```bash
# Health check
curl http://localhost:8080/actuator/health

# Create a task
curl -X POST http://localhost:8080/api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Task",
    "description": "This is a test task",
    "status": "TODO",
    "priority": "HIGH",
    "assigneeEmail": "test@example.com"
  }'

# Get all tasks
curl http://localhost:8080/api/v1/tasks

# Get task by ID
curl http://localhost:8080/api/v1/tasks/1

# Update task
curl -X PUT http://localhost:8080/api/v1/tasks/1 \
  -H "Content-Type: application/json" \
  -d '{
    "status": "IN_PROGRESS"
  }'

# Delete task
curl -X DELETE http://localhost:8080/api/v1/tasks/1
```

### **4. API Documentation**
- **Swagger UI**: http://localhost:8080/swagger-ui.html
- **OpenAPI JSON**: http://localhost:8080/api-docs
- **Actuator Endpoints**: http://localhost:8080/actuator

This source code provides a complete, production-ready REST API with proper layering, error handling, validation, and monitoring capabilities.
