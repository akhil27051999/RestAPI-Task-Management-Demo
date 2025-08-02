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
