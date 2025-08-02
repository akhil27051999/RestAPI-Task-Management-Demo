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
