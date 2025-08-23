package com.todoapp.service;

import com.todoapp.entity.Todo;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Service interface for Todo business logic
 */
public interface TodoService {

    /**
     * Create a new todo
     */
    Todo createTodo(Todo todo);

    /**
     * Get all todos with pagination
     */
    Page<Todo> getAllTodos(Pageable pageable);

    /**
     * Get all todos without pagination
     */
    List<Todo> getAllTodos();

    /**
     * Get todo by ID
     */
    Optional<Todo> getTodoById(Long id);

    /**
     * Update an existing todo
     */
    Todo updateTodo(Long id, Todo todoDetails);

    /**
     * Delete a todo
     */
    void deleteTodo(Long id);

    /**
     * Mark todo as completed
     */
    Todo markAsCompleted(Long id);

    /**
     * Mark todo as incomplete
     */
    Todo markAsIncomplete(Long id);

    /**
     * Get todos by completion status
     */
    List<Todo> getTodosByStatus(boolean completed);

    /**
     * Get todos by priority
     */
    List<Todo> getTodosByPriority(Todo.Priority priority);

    /**
     * Search todos by title or description
     */
    List<Todo> searchTodos(String searchTerm);

    /**
     * Get overdue todos
     */
    List<Todo> getOverdueTodos();

    /**
     * Get todos due today
     */
    List<Todo> getTodosDueToday();

    /**
     * Get todos due this week
     */
    List<Todo> getTodosDueThisWeek();

    /**
     * Get high priority incomplete todos
     */
    List<Todo> getHighPriorityIncompleteTodos();

    /**
     * Get todo statistics
     */
    TodoStatistics getTodoStatistics();

    /**
     * Clean up old completed todos
     */
    void cleanupOldCompletedTodos(int daysToKeep);

    /**
     * Statistics class for todo metrics
     */
    class TodoStatistics {
        private long totalTodos;
        private long completedTodos;
        private long incompleteTodos;
        private long overdueTodos;
        private long highPriorityTodos;

        // Constructors
        public TodoStatistics() {}

        public TodoStatistics(long totalTodos, long completedTodos, long incompleteTodos, 
                           long overdueTodos, long highPriorityTodos) {
            this.totalTodos = totalTodos;
            this.completedTodos = completedTodos;
            this.incompleteTodos = incompleteTodos;
            this.overdueTodos = overdueTodos;
            this.highPriorityTodos = highPriorityTodos;
        }

        // Getters and Setters
        public long getTotalTodos() { return totalTodos; }
        public void setTotalTodos(long totalTodos) { this.totalTodos = totalTodos; }

        public long getCompletedTodos() { return completedTodos; }
        public void setCompletedTodos(long completedTodos) { this.completedTodos = completedTodos; }

        public long getIncompleteTodos() { return incompleteTodos; }
        public void setIncompleteTodos(long incompleteTodos) { this.incompleteTodos = incompleteTodos; }

        public long getOverdueTodos() { return overdueTodos; }
        public void setOverdueTodos(long overdueTodos) { this.overdueTodos = overdueTodos; }

        public long getHighPriorityTodos() { return highPriorityTodos; }
        public void setHighPriorityTodos(long highPriorityTodos) { this.highPriorityTodos = highPriorityTodos; }

        public double getCompletionRate() {
            return totalTodos > 0 ? (double) completedTodos / totalTodos * 100 : 0.0;
        }
    }
}
