package com.todoapp.service.impl;

import com.todoapp.entity.Todo;
import com.todoapp.repository.TodoRepository;
import com.todoapp.service.TodoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import edu.umd.cs.findbugs.annotations.SuppressFBWarnings;

/**
 * Implementation of TodoService with business logic
 */
@Service
public class TodoServiceImpl implements TodoService {

    private final TodoRepository todoRepository;

    @Autowired
    @SuppressFBWarnings("EI_EXPOSE_REP2")
    public TodoServiceImpl(TodoRepository todoRepository) {
        this.todoRepository = todoRepository;
    }

    @Override
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
    public Page<Todo> getAllTodos(Pageable pageable) {
        return todoRepository.findAll(pageable);
    }

    @Override
    public List<Todo> getAllTodos() {
        return todoRepository.findAll();
    }

    @Override
    public Optional<Todo> getTodoById(Long id) {
        return todoRepository.findById(id);
    }

    @Override
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
    public void deleteTodo(Long id) {
        if (!todoRepository.existsById(id)) {
            throw new RuntimeException("Todo not found with id: " + id);
        }
        todoRepository.deleteById(id);
    }

    @Override
    public Todo markAsCompleted(Long id) {
        Todo todo = todoRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Todo not found with id: " + id));
        
        todo.setCompleted(true);
        return todoRepository.save(todo);
    }

    @Override
    public Todo markAsIncomplete(Long id) {
        Todo todo = todoRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Todo not found with id: " + id));
        
        todo.setCompleted(false);
        return todoRepository.save(todo);
    }

    @Override
    public List<Todo> getTodosByStatus(boolean completed) {
        return todoRepository.findByCompleted(completed);
    }

    @Override
    public List<Todo> getTodosByPriority(Todo.Priority priority) {
        return todoRepository.findByPriority(priority);
    }

    @Override
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
    public List<Todo> getOverdueTodos() {
        return todoRepository.findOverdueTodos(LocalDateTime.now());
    }

    @Override
    public List<Todo> getTodosDueToday() {
        return todoRepository.findTodosDueToday(LocalDateTime.now());
    }

    @Override
    public List<Todo> getTodosDueThisWeek() {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime startOfWeek = now.toLocalDate().atStartOfDay();
        LocalDateTime endOfWeek = startOfWeek.plusDays(7);
        
        return todoRepository.findTodosDueThisWeek(startOfWeek, endOfWeek);
    }

    @Override
    public List<Todo> getHighPriorityIncompleteTodos() {
        return todoRepository.findHighPriorityIncompleteTodos();
    }

    @Override
    public TodoStatistics getTodoStatistics() {
        long totalTodos = todoRepository.count();
        long completedTodos = todoRepository.countByCompleted(true);
        long incompleteTodos = todoRepository.countByCompleted(false);
        long overdueTodos = getOverdueTodos().size();
        long highPriorityTodos = todoRepository.countByPriority(Todo.Priority.HIGH) + 
                                todoRepository.countByPriority(Todo.Priority.URGENT);

        return new TodoStatistics(totalTodos, completedTodos, incompleteTodos, overdueTodos,
                                highPriorityTodos);
    }

    @Override
    public void cleanupOldCompletedTodos(int daysToKeep) {
        LocalDateTime cutoffDate = LocalDateTime.now().minusDays(daysToKeep);
        todoRepository.deleteOldCompletedTodos(cutoffDate);
    }
}
