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
