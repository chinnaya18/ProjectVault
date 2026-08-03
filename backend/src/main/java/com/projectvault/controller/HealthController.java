package com.projectvault.controller;

import com.projectvault.dto.response.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/health")
@Tag(name = "Health Check", description = "System Health and Availability Endpoints")
public class HealthController {

    @GetMapping
    @Operation(summary = "Get Backend System Health", description = "Returns operational status and version details of the Spring Boot backend.")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getHealthStatus() {
        Map<String, Object> healthInfo = Map.of(
                "status", "UP",
                "application", "ProjectVault Core Backend",
                "version", "1.1.0",
                "environment", "Development"
        );
        return ResponseEntity.ok(ApiResponse.success("System operational", healthInfo));
    }
}
