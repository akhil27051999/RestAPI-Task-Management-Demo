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
