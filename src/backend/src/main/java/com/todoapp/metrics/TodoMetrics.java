package com.todoapp.metrics;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import io.micrometer.core.instrument.Gauge;
import org.springframework.stereotype.Component;

import java.util.concurrent.atomic.AtomicInteger;

@Component
public class TodoMetrics {
    
    private final Counter todosCreatedCounter;
    private final Counter todosCompletedCounter;
    private final Counter todosDeletedCounter;
    private final Counter todosUpdatedCounter;
    private final Counter userSessionsCounter;
    private final Counter featureUsageCounter;
    
    private final Timer todoCreationTimer;
    private final Timer todoCompletionTimer;
    private final Timer apiResponseTimer;
    
    private final AtomicInteger activeTodosGauge;
    private final AtomicInteger activeUsersGauge;
    
    public TodoMetrics(MeterRegistry meterRegistry) {
        // Counters for business metrics
        this.todosCreatedCounter = Counter.builder("todo_todos_created_total")
                .description("Total number of todos created")
                .register(meterRegistry);
                
        this.todosCompletedCounter = Counter.builder("todo_todos_completed_total")
                .description("Total number of todos completed")
                .register(meterRegistry);
                
        this.todosDeletedCounter = Counter.builder("todo_todos_deleted_total")
                .description("Total number of todos deleted")
                .register(meterRegistry);
                
        this.todosUpdatedCounter = Counter.builder("todo_todos_updated_total")
                .description("Total number of todos updated")
                .register(meterRegistry);
                
        this.userSessionsCounter = Counter.builder("todo_user_sessions_total")
                .description("Total number of user sessions")
                .tag("user_id", "anonymous")
                .register(meterRegistry);
                
        this.featureUsageCounter = Counter.builder("todo_feature_usage_total")
                .description("Feature usage tracking")
                .tag("feature", "unknown")
                .register(meterRegistry);
        
        // Timers for performance metrics
        this.todoCreationTimer = Timer.builder("todo_creation_duration_seconds")
                .description("Time taken to create a todo")
                .register(meterRegistry);
                
        this.todoCompletionTimer = Timer.builder("todo_completion_duration_seconds")
                .description("Time taken to complete a todo")
                .register(meterRegistry);
                
        this.apiResponseTimer = Timer.builder("http_request_duration_seconds")
                .description("HTTP request duration")
                .register(meterRegistry);
        
        // Gauges for current state
        this.activeTodosGauge = new AtomicInteger(0);
        Gauge.builder("todo_active_todos_total")
                .description("Current number of active todos")
                .register(meterRegistry, activeTodosGauge, AtomicInteger::get);
                
        this.activeUsersGauge = new AtomicInteger(0);
        Gauge.builder("todo_active_users_total")
                .description("Current number of active users")
                .register(meterRegistry, activeUsersGauge, AtomicInteger::get);
    }
    
    // Business metric methods
    public void incrementTodosCreated() {
        todosCreatedCounter.increment();
        activeTodosGauge.incrementAndGet();
    }
    
    public void incrementTodosCompleted() {
        todosCompletedCounter.increment();
        activeTodosGauge.decrementAndGet();
    }
    
    public void incrementTodosDeleted() {
        todosDeletedCounter.increment();
        activeTodosGauge.decrementAndGet();
    }
    
    public void incrementTodosUpdated() {
        todosUpdatedCounter.increment();
    }
    
    public void incrementUserSessions(String userId) {
        userSessionsCounter.increment();
        activeUsersGauge.incrementAndGet();
    }
    
    public void incrementFeatureUsage(String feature) {
        featureUsageCounter.increment();
    }
    
    // Performance metric methods
    public Timer.Sample startTodoCreationTimer() {
        return Timer.start();
    }
    
    public void stopTodoCreationTimer(Timer.Sample sample) {
        sample.stop(todoCreationTimer);
    }
    
    public Timer.Sample startTodoCompletionTimer() {
        return Timer.start();
    }
    
    public void stopTodoCompletionTimer(Timer.Sample sample) {
        sample.stop(todoCompletionTimer);
    }
    
    public Timer.Sample startApiResponseTimer() {
        return Timer.start();
    }
    
    public void stopApiResponseTimer(Timer.Sample sample) {
        sample.stop(apiResponseTimer);
    }
    
    // Gauge update methods
    public void setActiveTodos(int count) {
        activeTodosGauge.set(count);
    }
    
    public void setActiveUsers(int count) {
        activeUsersGauge.set(count);
    }
}
