package com.todoapp.config;

import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.transaction.TransactionAutoConfiguration;
import org.springframework.context.annotation.Configuration;

/**
 * Configuration to disable transaction management
 */
@Configuration
@EnableAutoConfiguration(exclude = {TransactionAutoConfiguration.class})
public class TransactionConfig {
    // This class disables Spring's automatic transaction management
}
