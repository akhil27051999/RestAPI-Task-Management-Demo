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
