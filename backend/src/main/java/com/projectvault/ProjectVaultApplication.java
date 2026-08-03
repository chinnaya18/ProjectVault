package com.projectvault;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableAsync
public class ProjectVaultApplication {

    public static void main(String[] args) {
        SpringApplication.run(ProjectVaultApplication.class, args);
    }
}
