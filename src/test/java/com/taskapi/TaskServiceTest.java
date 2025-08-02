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
