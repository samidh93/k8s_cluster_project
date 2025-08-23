package com.todoapp.service.impl;

import com.todoapp.entity.Todo;
import com.todoapp.repository.TodoRepository;
import com.todoapp.service.TodoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Implementation of TodoService with business logic
 */
@Service
@Transactional
public class TodoServiceImpl implements TodoService {

    private final TodoRepository todoRepository;

    @Autowired
    public TodoServiceImpl(TodoRepository todoRepository) {
        this.todoRepository = todoRepository;
    }

    @Override
    @CacheEvict(value = "todos", allEntries = true)
    public Todo createTodo(Todo todo) {
        // Validate todo
        if (todo.getTitle() == null || todo.getTitle().trim().isEmpty()) {
            throw new IllegalArgumentException("Todo title cannot be empty");
        }

        // Set default values if not provided
        if (todo.getPriority() == null) {
            todo.setPriority(Todo.Priority.MEDIUM);
        }

        return todoRepository.save(todo);
    }

    @Override
    @Cacheable(value = "todos", key = "'all'")
    public Page<Todo> getAllTodos(Pageable pageable) {
        return todoRepository.findAll(pageable);
    }

    @Override
    @Cacheable(value = "todos", key = "'all'")
    public List<Todo> getAllTodos() {
        return todoRepository.findAll();
    }

    @Override
    @Cacheable(value = "todos", key = "#id")
    public Optional<Todo> getTodoById(Long id) {
        return todoRepository.findById(id);
    }

    @Override
    @CacheEvict(value = "todos", allEntries = true)
    public Todo updateTodo(Long id, Todo todoDetails) {
        Todo existingTodo = todoRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Todo not found with id: " + id));

        // Update fields if provided
        if (todoDetails.getTitle() != null) {
            existingTodo.setTitle(todoDetails.getTitle());
        }
        if (todoDetails.getDescription() != null) {
            existingTodo.setDescription(todoDetails.getDescription());
        }
        if (todoDetails.getDueDate() != null) {
            existingTodo.setDueDate(todoDetails.getDueDate());
        }
        if (todoDetails.getPriority() != null) {
            existingTodo.setPriority(todoDetails.getPriority());
        }

        return todoRepository.save(existingTodo);
    }

    @Override
    @CacheEvict(value = "todos", allEntries = true)
    public void deleteTodo(Long id) {
        if (!todoRepository.existsById(id)) {
            throw new RuntimeException("Todo not found with id: " + id);
        }
        todoRepository.deleteById(id);
    }

    @Override
    @CacheEvict(value = "todos", allEntries = true)
    public Todo markAsCompleted(Long id) {
        Todo todo = todoRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Todo not found with id: " + id));
        
        todo.setCompleted(true);
        return todoRepository.save(todo);
    }

    @Override
    @CacheEvict(value = "todos", allEntries = true)
    public Todo markAsIncomplete(Long id) {
        Todo todo = todoRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Todo not found with id: " + id));
        
        todo.setCompleted(false);
        return todoRepository.save(todo);
    }

    @Override
    @Cacheable(value = "todos", key = "'status_' + #completed")
    public List<Todo> getTodosByStatus(boolean completed) {
        return todoRepository.findByCompleted(completed);
    }

    @Override
    @Cacheable(value = "todos", key = "'priority_' + #priority")
    public List<Todo> getTodosByPriority(Todo.Priority priority) {
        return todoRepository.findByPriority(priority);
    }

    @Override
    @Cacheable(value = "todos", key = "'search_' + #searchTerm")
    public List<Todo> searchTodos(String searchTerm) {
        if (searchTerm == null || searchTerm.trim().isEmpty()) {
            return getAllTodos();
        }

        String trimmedTerm = searchTerm.trim();
        List<Todo> titleResults = todoRepository.findByTitleContainingIgnoreCase(trimmedTerm);
        List<Todo> descriptionResults = todoRepository.findByDescriptionContainingIgnoreCase(trimmedTerm);

        // Combine and remove duplicates
        titleResults.addAll(descriptionResults);
        return titleResults.stream()
                .distinct()
                .toList();
    }

    @Override
    @Cacheable(value = "todos", key = "'overdue'")
    public List<Todo> getOverdueTodos() {
        return todoRepository.findOverdueTodos(LocalDateTime.now());
    }

    @Override
    @Cacheable(value = "todos", key = "'due_today'")
    public List<Todo> getTodosDueToday() {
        return todoRepository.findTodosDueToday(LocalDateTime.now());
    }

    @Override
    @Cacheable(value = "todos", key = "'due_this_week'")
    public List<Todo> getTodosDueThisWeek() {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime startOfWeek = now.toLocalDate().atStartOfDay();
        LocalDateTime endOfWeek = startOfWeek.plusDays(7);
        
        return todoRepository.findTodosDueThisWeek(startOfWeek, endOfWeek);
    }

    @Override
    @Cacheable(value = "todos", key = "'high_priority'")
    public List<Todo> getHighPriorityIncompleteTodos() {
        return todoRepository.findHighPriorityIncompleteTodos();
    }

    @Override
    @Cacheable(value = "todos", key = "'statistics'")
    public TodoStatistics getTodoStatistics() {
        long totalTodos = todoRepository.count();
        long completedTodos = todoRepository.countByCompleted(true);
        long incompleteTodos = todoRepository.countByCompleted(false);
        long overdueTodos = getOverdueTodos().size();
        long highPriorityTodos = todoRepository.countByPriority(Todo.Priority.HIGH) + 
                                todoRepository.countByPriority(Todo.Priority.URGENT);

        return new TodoStatistics(totalTodos, completedTodos, incompleteTodos, overdueTodos, highPriorityTodos);
    }

    @Override
    @CacheEvict(value = "todos", allEntries = true)
    public void cleanupOldCompletedTodos(int daysToKeep) {
        LocalDateTime cutoffDate = LocalDateTime.now().minusDays(daysToKeep);
        todoRepository.deleteOldCompletedTodos(cutoffDate);
    }
}
