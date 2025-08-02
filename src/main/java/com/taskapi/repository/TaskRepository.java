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
