# Task Management API - Source Code Files

## Source Code Structure

```
src/
├── main/
│   ├── java/
│   │   └── com/
│   │       └── taskapi/
│   │           ├── TaskApiApplication.java
│   │           ├── controller/
│   │           │   └── TaskController.java
│   │           ├── model/
│   │           │   ├── Task.java
│   │           │   ├── TaskStatus.java
│   │           │   └── Priority.java
│   │           ├── repository/
│   │           │   └── TaskRepository.java
│   │           ├── service/
│   │           │   ├── TaskService.java
│   │           │   └── TaskServiceImpl.java
│   │           ├── dto/
│   │           │   ├── TaskCreateRequest.java
│   │           │   ├── TaskUpdateRequest.java
│   │           │   └── TaskResponse.java
│   │           └── exception/
│   │               ├── TaskNotFoundException.java
│   │               └── GlobalExceptionHandler.java
│   └── resources/
│       ├── application.yml
│       ├── application-dev.yml
│       └── application-prod.yml
└── test/
    └── java/
        └── com/
            └── taskapi/
                ├── TaskControllerTest.java
                ├── TaskServiceTest.java
                └── TaskRepositoryTest.java
```

---

## Main Application Files

### TaskApiApplication.java
```java
package com.taskapi;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@SpringBootApplication
@EnableJpaRepositories
public class TaskApiApplication {
    public static void main(String[] args) {
        SpringApplication.run(TaskApiApplication.class, args);
    }
}
```

---

## Controller Layer

### TaskController.java
```java
package com.taskapi.controller;

import com.taskapi.dto.TaskCreateRequest;
import com.taskapi.dto.TaskUpdateRequest;
import com.taskapi.dto.TaskResponse;
import com.taskapi.service.TaskService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;

@RestController
@RequestMapping("/api/tasks")
@RequiredArgsConstructor
public class TaskController {

    private final TaskService taskService;

    @GetMapping
    public ResponseEntity<Page<TaskResponse>> getAllTasks(Pageable pageable) {
        return ResponseEntity.ok(taskService.getAllTasks(pageable));
    }

    @GetMapping("/{id}")
    public ResponseEntity<TaskResponse> getTaskById(@PathVariable Long id) {
        return ResponseEntity.ok(taskService.getTaskById(id));
    }

    @PostMapping
    public ResponseEntity<TaskResponse> createTask(@Valid @RequestBody TaskCreateRequest request) {
        TaskResponse created = taskService.createTask(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @PutMapping("/{id}")
    public ResponseEntity<TaskResponse> updateTask(@PathVariable Long id, 
                                                 @Valid @RequestBody TaskUpdateRequest request) {
        return ResponseEntity.ok(taskService.updateTask(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTask(@PathVariable Long id) {
        taskService.deleteTask(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/status/{status}")
    public ResponseEntity<List<TaskResponse>> getTasksByStatus(@PathVariable String status) {
        return ResponseEntity.ok(taskService.getTasksByStatus(status));
    }
}
```

---

## Model Layer

### Task.java
```java
package com.taskapi.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import javax.persistence.*;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;
import java.time.LocalDateTime;

@Entity
@Table(name = "tasks")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Task {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "Title is required")
    @Size(max = 255, message = "Title must not exceed 255 characters")
    @Column(nullable = false)
    private String title;

    @Size(max = 1000, message = "Description must not exceed 1000 characters")
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private TaskStatus status = TaskStatus.PENDING;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private Priority priority = Priority.MEDIUM;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Column(name = "due_date")
    private LocalDateTime dueDate;

    @Column(name = "assigned_to")
    private String assignedTo;
}
```

### TaskStatus.java
```java
package com.taskapi.model;

public enum TaskStatus {
    PENDING,
    IN_PROGRESS,
    COMPLETED,
    CANCELLED;

    public static TaskStatus fromString(String status) {
        for (TaskStatus taskStatus : TaskStatus.values()) {
            if (taskStatus.name().equalsIgnoreCase(status)) {
                return taskStatus;
            }
        }
        throw new IllegalArgumentException("Invalid task status: " + status);
    }
}
```

### Priority.java
```java
package com.taskapi.model;

public enum Priority {
    LOW,
    MEDIUM,
    HIGH,
    URGENT;

    public static Priority fromString(String priority) {
        for (Priority p : Priority.values()) {
            if (p.name().equalsIgnoreCase(priority)) {
                return p;
            }
        }
        throw new IllegalArgumentException("Invalid priority: " + priority);
    }
}
```

---

## Repository Layer

### TaskRepository.java
```java
package com.taskapi.repository;

import com.taskapi.model.Task;
import com.taskapi.model.TaskStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TaskRepository extends JpaRepository<Task, Long> {

    List<Task> findByStatus(TaskStatus status);
    
    List<Task> findByAssignedTo(String assignedTo);
    
    @Query("SELECT t FROM Task t WHERE t.title LIKE %:keyword% OR t.description LIKE %:keyword%")
    List<Task> searchTasks(@Param("keyword") String keyword);
    
    @Query("SELECT COUNT(t) FROM Task t WHERE t.status = :status")
    long countByStatus(@Param("status") TaskStatus status);
}
```

---

## Service Layer

### TaskService.java
```java
package com.taskapi.service;

import com.taskapi.dto.TaskCreateRequest;
import com.taskapi.dto.TaskUpdateRequest;
import com.taskapi.dto.TaskResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface TaskService {
    
    Page<TaskResponse> getAllTasks(Pageable pageable);
    
    TaskResponse getTaskById(Long id);
    
    TaskResponse createTask(TaskCreateRequest request);
    
    TaskResponse updateTask(Long id, TaskUpdateRequest request);
    
    void deleteTask(Long id);
    
    List<TaskResponse> getTasksByStatus(String status);
}
```

### TaskServiceImpl.java
```java
package com.taskapi.service;

import com.taskapi.dto.TaskCreateRequest;
import com.taskapi.dto.TaskUpdateRequest;
import com.taskapi.dto.TaskResponse;
import com.taskapi.exception.TaskNotFoundException;
import com.taskapi.model.Task;
import com.taskapi.model.TaskStatus;
import com.taskapi.model.Priority;
import com.taskapi.repository.TaskRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
@RequiredArgsConstructor
@Slf4j
public class TaskServiceImpl implements TaskService {

    private final TaskRepository taskRepository;

    @Override
    @Transactional(readOnly = true)
    public Page<TaskResponse> getAllTasks(Pageable pageable) {
        return taskRepository.findAll(pageable).map(this::mapToResponse);
    }

    @Override
    @Transactional(readOnly = true)
    public TaskResponse getTaskById(Long id) {
        Task task = taskRepository.findById(id)
                .orElseThrow(() -> new TaskNotFoundException("Task not found with id: " + id));
        return mapToResponse(task);
    }

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
        log.info("Created task with id: {}", savedTask.getId());
        return mapToResponse(savedTask);
    }

    @Override
    public TaskResponse updateTask(Long id, TaskUpdateRequest request) {
        Task existingTask = taskRepository.findById(id)
                .orElseThrow(() -> new TaskNotFoundException("Task not found with id: " + id));

        if (request.getTitle() != null) {
            existingTask.setTitle(request.getTitle());
        }
        if (request.getDescription() != null) {
            existingTask.setDescription(request.getDescription());
        }
        if (request.getStatus() != null) {
            existingTask.setStatus(TaskStatus.valueOf(request.getStatus().toUpperCase()));
        }
        if (request.getPriority() != null) {
            existingTask.setPriority(Priority.valueOf(request.getPriority().toUpperCase()));
        }
        if (request.getDueDate() != null) {
            existingTask.setDueDate(request.getDueDate());
        }
        if (request.getAssignedTo() != null) {
            existingTask.setAssignedTo(request.getAssignedTo());
        }

        Task updatedTask = taskRepository.save(existingTask);
        return mapToResponse(updatedTask);
    }

    @Override
    public void deleteTask(Long id) {
        if (!taskRepository.existsById(id)) {
            throw new TaskNotFoundException("Task not found with id: " + id);
        }
        taskRepository.deleteById(id);
        log.info("Deleted task with id: {}", id);
    }

    @Override
    @Transactional(readOnly = true)
    public List<TaskResponse> getTasksByStatus(String status) {
        TaskStatus taskStatus = TaskStatus.fromString(status);
        return taskRepository.findByStatus(taskStatus)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    private TaskResponse mapToResponse(Task task) {
        return TaskResponse.builder()
                .id(task.getId())
                .title(task.getTitle())
                .description(task.getDescription())
                .status(task.getStatus().name())
                .priority(task.getPriority().name())
                .createdAt(task.getCreatedAt())
                .updatedAt(task.getUpdatedAt())
                .dueDate(task.getDueDate())
                .assignedTo(task.getAssignedTo())
                .build();
    }
}
```

---

## DTO Layer

### TaskCreateRequest.java
```java
package com.taskapi.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TaskCreateRequest {

    @NotBlank(message = "Title is required")
    @Size(max = 255, message = "Title must not exceed 255 characters")
    private String title;

    @Size(max = 1000, message = "Description must not exceed 1000 characters")
    private String description;

    @Builder.Default
    private String status = "PENDING";

    @Builder.Default
    private String priority = "MEDIUM";

    private LocalDateTime dueDate;

    private String assignedTo;
}
```

### TaskUpdateRequest.java
```java
package com.taskapi.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import javax.validation.constraints.Size;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TaskUpdateRequest {

    @Size(max = 255, message = "Title must not exceed 255 characters")
    private String title;

    @Size(max = 1000, message = "Description must not exceed 1000 characters")
    private String description;

    private String status;

    private String priority;

    private LocalDateTime dueDate;

    private String assignedTo;
}
```

### TaskResponse.java
```java
package com.taskapi.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TaskResponse {

    private Long id;
    private String title;
    private String description;
    private String status;
    private String priority;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private LocalDateTime dueDate;
    private String assignedTo;
}
```

---

## Exception Handling

### TaskNotFoundException.java
```java
package com.taskapi.exception;

public class TaskNotFoundException extends RuntimeException {
    
    public TaskNotFoundException(String message) {
        super(message);
    }
}
```

### GlobalExceptionHandler.java
```java
package com.taskapi.exception;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(TaskNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleTaskNotFoundException(TaskNotFoundException ex) {
        log.error("Task not found: {}", ex.getMessage());
        
        ErrorResponse error = ErrorResponse.builder()
                .timestamp(LocalDateTime.now())
                .status(HttpStatus.NOT_FOUND.value())
                .error("Not Found")
                .message(ex.getMessage())
                .build();
                
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidationExceptions(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getAllErrors().forEach((error) -> {
            String fieldName = ((FieldError) error).getField();
            String errorMessage = error.getDefaultMessage();
            errors.put(fieldName, errorMessage);
        });

        ErrorResponse error = ErrorResponse.builder()
                .timestamp(LocalDateTime.now())
                .status(HttpStatus.BAD_REQUEST.value())
                .error("Validation Failed")
                .message("Invalid input parameters")
                .validationErrors(errors)
                .build();

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ErrorResponse {
        private LocalDateTime timestamp;
        private int status;
        private String error;
        private String message;
        private Map<String, String> validationErrors;
    }
}
```

---

## Configuration Files

### application.yml
```yaml
server:
  port: 8080

spring:
  application:
    name: task-management-api
  
  datasource:
    url: jdbc:mysql://localhost:3306/taskdb
    username: ${DB_USERNAME:root}
    password: ${DB_PASSWORD:password123}
    driver-class-name: com.mysql.cj.jdbc.Driver
  
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: false
    properties:
      hibernate:
        dialect: org.hibernate.dialect.MySQL8Dialect

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
    com.taskapi: INFO
```

### application-dev.yml
```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/taskdb_dev
  
  jpa:
    show-sql: true
    hibernate:
      ddl-auto: update

logging:
  level:
    com.taskapi: DEBUG
    org.springframework.web: DEBUG
```

### application-prod.yml
```yaml
spring:
  datasource:
    url: jdbc:mysql://${DB_HOST:mysql-service}:${DB_PORT:3306}/${DB_NAME:taskdb}
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
  
  jpa:
    show-sql: false
    hibernate:
      ddl-auto: validate

logging:
  level:
    com.taskapi: INFO
    org.springframework.web: WARN
```

---

## Test Files

### TaskControllerTest.java
```java
package com.taskapi;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.taskapi.dto.TaskCreateRequest;
import com.taskapi.dto.TaskResponse;
import com.taskapi.service.TaskService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest
class TaskControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private TaskService taskService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void createTask_ShouldReturnCreatedTask() throws Exception {
        TaskCreateRequest request = TaskCreateRequest.builder()
                .title("Test Task")
                .description("Test Description")
                .build();

        TaskResponse response = TaskResponse.builder()
                .id(1L)
                .title("Test Task")
                .description("Test Description")
                .status("PENDING")
                .priority("MEDIUM")
                .createdAt(LocalDateTime.now())
                .build();

        when(taskService.createTask(any())).thenReturn(response);

        mockMvc.perform(post("/api/tasks")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.title").value("Test Task"));
    }
}
```

### TaskServiceTest.java
```java
package com.taskapi;

import com.taskapi.dto.TaskCreateRequest;
import com.taskapi.dto.TaskResponse;
import com.taskapi.exception.TaskNotFoundException;
import com.taskapi.model.Task;
import com.taskapi.model.TaskStatus;
import com.taskapi.model.Priority;
import com.taskapi.repository.TaskRepository;
import com.taskapi.service.TaskServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TaskServiceTest {

    @Mock
    private TaskRepository taskRepository;

    private TaskServiceImpl taskService;

    @BeforeEach
    void setUp() {
        taskService = new TaskServiceImpl(taskRepository);
    }

    @Test
    void getTaskById_ExistingTask_ShouldReturnTask() {
        Task task = Task.builder()
                .id(1L)
                .title("Test Task")
                .status(TaskStatus.PENDING)
                .priority(Priority.MEDIUM)
                .createdAt(LocalDateTime.now())
                .build();

        when(taskRepository.findById(1L)).thenReturn(Optional.of(task));

        TaskResponse result = taskService.getTaskById(1L);

        assertNotNull(result);
        assertEquals(1L, result.getId());
        assertEquals("Test Task", result.getTitle());
    }

    @Test
    void getTaskById_NonExistingTask_ShouldThrowException() {
        when(taskRepository.findById(1L)).thenReturn(Optional.empty());

        assertThrows(TaskNotFoundException.class, () -> taskService.getTaskById(1L));
    }
}
```

### TaskRepositoryTest.java
```java
package com.taskapi;

import com.taskapi.model.Task;
import com.taskapi.model.TaskStatus;
import com.taskapi.model.Priority;
import com.taskapi.repository.TaskRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@DataJpaTest
class TaskRepositoryTest {

    @Autowired
    private TestEntityManager entityManager;

    @Autowired
    private TaskRepository taskRepository;

    @Test
    void findByStatus_ShouldReturnTasksWithGivenStatus() {
        Task task = Task.builder()
                .title("Test Task")
                .status(TaskStatus.PENDING)
                .priority(Priority.MEDIUM)
                .build();

        entityManager.persistAndFlush(task);

        List<Task> pendingTasks = taskRepository.findByStatus(TaskStatus.PENDING);

        assertEquals(1, pendingTasks.size());
        assertEquals("Test Task", pendingTasks.get(0).getTitle());
    }
}
```

---

## Summary

This source code provides:

- **Complete REST API** with CRUD operations
- **Layered Architecture** with proper separation of concerns
- **Data Validation** and error handling
- **JPA Integration** with MySQL database
- **Environment Configuration** for dev/prod deployments
- **Basic Testing** for all layers
- **Production Ready** with logging and monitoring endpoints

The code follows Spring Boot best practices and is ready for containerization and Kubernetes deployment.
