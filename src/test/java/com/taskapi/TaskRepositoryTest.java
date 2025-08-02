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
