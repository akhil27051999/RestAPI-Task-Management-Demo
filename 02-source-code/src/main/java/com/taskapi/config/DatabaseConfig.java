package com.taskapi.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@Configuration
@EnableJpaRepositories(basePackages = "com.taskapi.repository")
public class DatabaseConfig {
    // Additional database configuration if needed
}
