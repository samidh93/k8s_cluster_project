package com.todoapp.repository;

import com.todoapp.entity.Todo;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Repository interface for Todo entity operations
 */
@Repository
public interface TodoRepository extends JpaRepository<Todo, Long> {

    /**
     * Find todos by completion status
     */
    List<Todo> findByCompleted(boolean completed);

    /**
     * Find todos by completion status with pagination
     */
    Page<Todo> findByCompleted(boolean completed, Pageable pageable);

    /**
     * Find todos by priority
     */
    List<Todo> findByPriority(Todo.Priority priority);

    /**
     * Find todos by title containing the given text (case-insensitive)
     */
    List<Todo> findByTitleContainingIgnoreCase(String title);

    /**
     * Find todos by description containing the given text (case-insensitive)
     */
    List<Todo> findByDescriptionContainingIgnoreCase(String description);

    /**
     * Find overdue todos (due date is in the past and not completed)
     */
    @Query("SELECT t FROM Todo t WHERE t.dueDate < :now AND t.completed = false")
    List<Todo> findOverdueTodos(@Param("now") LocalDateTime now);

    /**
     * Find todos due today
     */
    @Query("SELECT t FROM Todo t WHERE DATE(t.dueDate) = DATE(:today) AND t.completed = false")
    List<Todo> findTodosDueToday(@Param("today") LocalDateTime today);

    /**
     * Find todos due this week
     */
    @Query("SELECT t FROM Todo t WHERE t.dueDate BETWEEN :startOfWeek AND :endOfWeek AND t.completed = false")
    List<Todo> findTodosDueThisWeek(@Param("startOfWeek") LocalDateTime startOfWeek, 
                                   @Param("endOfWeek") LocalDateTime endOfWeek);

    /**
     * Count todos by completion status
     */
    long countByCompleted(boolean completed);

    /**
     * Count todos by priority
     */
    long countByPriority(Todo.Priority priority);

    /**
     * Find completed todos created in the last N days
     */
    @Query("SELECT t FROM Todo t WHERE t.completed = true AND t.createdAt >= :since")
    List<Todo> findRecentlyCompletedTodos(@Param("since") LocalDateTime since);

    /**
     * Find high priority incomplete todos
     */
    @Query("SELECT t FROM Todo t WHERE t.priority IN ('HIGH', 'URGENT') AND t.completed = false ORDER BY t.dueDate ASC")
    List<Todo> findHighPriorityIncompleteTodos();

    /**
     * Delete completed todos older than specified date
     */
    @Query("DELETE FROM Todo t WHERE t.completed = true AND t.updatedAt < :olderThan")
    void deleteOldCompletedTodos(@Param("olderThan") LocalDateTime olderThan);
}
