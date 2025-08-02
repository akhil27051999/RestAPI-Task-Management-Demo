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
