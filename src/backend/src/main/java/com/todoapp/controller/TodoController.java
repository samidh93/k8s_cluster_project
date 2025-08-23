package com.todoapp.controller;

import com.todoapp.entity.Todo;
import com.todoapp.service.TodoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.List;

/**
 * REST controller for Todo operations
 */
@RestController
@RequestMapping("/api/todos")
@CrossOrigin(origins = "*") // In production, restrict to specific domains
public class TodoController {

    private final TodoService todoService;

    @Autowired
    public TodoController(TodoService todoService) {
        this.todoService = todoService;
    }

    /**
     * Create a new todo
     */
    @PostMapping
    public ResponseEntity<Todo> createTodo(@Valid @RequestBody Todo todo) {
        try {
            Todo createdTodo = todoService.createTodo(todo);
            return new ResponseEntity<>(createdTodo, HttpStatus.CREATED);
        } catch (IllegalArgumentException e) {
            return new ResponseEntity<>(HttpStatus.BAD_REQUEST);
        }
    }

    /**
     * Get all todos with pagination
     */
    @GetMapping
    public ResponseEntity<Page<Todo>> getAllTodos(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "id") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir) {
        
        Sort sort = sortDir.equalsIgnoreCase("desc") ? 
            Sort.by(sortBy).descending() : Sort.by(sortBy).ascending();
        
        Pageable pageable = PageRequest.of(page, size, sort);
        Page<Todo> todos = todoService.getAllTodos(pageable);
        
        return ResponseEntity.ok(todos);
    }

    /**
     * Get all todos without pagination
     */
    @GetMapping("/all")
    public ResponseEntity<List<Todo>> getAllTodosList() {
        List<Todo> todos = todoService.getAllTodos();
        return ResponseEntity.ok(todos);
    }

    /**
     * Get todo by ID
     */
    @GetMapping("/{id}")
    public ResponseEntity<Todo> getTodoById(@PathVariable Long id) {
        return todoService.getTodoById(id)
                .map(todo -> ResponseEntity.ok(todo))
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Update an existing todo
     */
    @PutMapping("/{id}")
    public ResponseEntity<Todo> updateTodo(@PathVariable Long id, @Valid @RequestBody Todo todoDetails) {
        try {
            Todo updatedTodo = todoService.updateTodo(id, todoDetails);
            return ResponseEntity.ok(updatedTodo);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * Delete a todo
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTodo(@PathVariable Long id) {
        try {
            todoService.deleteTodo(id);
            return ResponseEntity.noContent().build();
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * Mark todo as completed
     */
    @PatchMapping("/{id}/complete")
    public ResponseEntity<Todo> markAsCompleted(@PathVariable Long id) {
        try {
            Todo completedTodo = todoService.markAsCompleted(id);
            return ResponseEntity.ok(completedTodo);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * Mark todo as incomplete
     */
    @PatchMapping("/{id}/incomplete")
    public ResponseEntity<Todo> markAsIncomplete(@PathVariable Long id) {
        try {
            Todo incompleteTodo = todoService.markAsIncomplete(id);
            return ResponseEntity.ok(incompleteTodo);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * Get todos by completion status
     */
    @GetMapping("/status/{completed}")
    public ResponseEntity<List<Todo>> getTodosByStatus(@PathVariable boolean completed) {
        List<Todo> todos = todoService.getTodosByStatus(completed);
        return ResponseEntity.ok(todos);
    }

    /**
     * Get todos by priority
     */
    @GetMapping("/priority/{priority}")
    public ResponseEntity<List<Todo>> getTodosByPriority(@PathVariable Todo.Priority priority) {
        List<Todo> todos = todoService.getTodosByPriority(priority);
        return ResponseEntity.ok(todos);
    }

    /**
     * Search todos by title or description
     */
    @GetMapping("/search")
    public ResponseEntity<List<Todo>> searchTodos(@RequestParam String q) {
        List<Todo> todos = todoService.searchTodos(q);
        return ResponseEntity.ok(todos);
    }

    /**
     * Get overdue todos
     */
    @GetMapping("/overdue")
    public ResponseEntity<List<Todo>> getOverdueTodos() {
        List<Todo> todos = todoService.getOverdueTodos();
        return ResponseEntity.ok(todos);
    }

    /**
     * Get todos due today
     */
    @GetMapping("/due-today")
    public ResponseEntity<List<Todo>> getTodosDueToday() {
        List<Todo> todos = todoService.getTodosDueToday();
        return ResponseEntity.ok(todos);
    }

    /**
     * Get todos due this week
     */
    @GetMapping("/due-this-week")
    public ResponseEntity<List<Todo>> getTodosDueThisWeek() {
        List<Todo> todos = todoService.getTodosDueThisWeek();
        return ResponseEntity.ok(todos);
    }

    /**
     * Get high priority incomplete todos
     */
    @GetMapping("/high-priority")
    public ResponseEntity<List<Todo>> getHighPriorityIncompleteTodos() {
        List<Todo> todos = todoService.getHighPriorityIncompleteTodos();
        return ResponseEntity.ok(todos);
    }

    /**
     * Get todo statistics
     */
    @GetMapping("/statistics")
    public ResponseEntity<TodoService.TodoStatistics> getTodoStatistics() {
        TodoService.TodoStatistics stats = todoService.getTodoStatistics();
        return ResponseEntity.ok(stats);
    }

    /**
     * Clean up old completed todos
     */
    @DeleteMapping("/cleanup")
    public ResponseEntity<Void> cleanupOldCompletedTodos(@RequestParam(defaultValue = "30") int daysToKeep) {
        todoService.cleanupOldCompletedTodos(daysToKeep);
        return ResponseEntity.noContent().build();
    }

    /**
     * Health check endpoint
     */
    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("Todo API is healthy!");
    }
}
