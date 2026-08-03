package com.projectvault.controller;

import com.projectvault.dto.request.CreateProjectRequest;
import com.projectvault.dto.request.ProjectStatusTransitionRequest;
import com.projectvault.dto.request.UpdateProjectRequest;
import com.projectvault.dto.response.ApiResponse;
import com.projectvault.dto.response.PageResponse;
import com.projectvault.dto.response.ProjectDetailDto;
import com.projectvault.dto.response.ProjectSummaryDto;
import com.projectvault.entity.ProjectStatus;
import com.projectvault.entity.ProjectVisibility;
import com.projectvault.security.UserPrincipal;
import com.projectvault.service.ProjectService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/projects")
@Tag(name = "Project Management", description = "Academic Projects CRUD & Lifecycle State Machine APIs")
public class ProjectController {

    private final ProjectService projectService;

    public ProjectController(ProjectService projectService) {
        this.projectService = projectService;
    }

    @GetMapping
    @Operation(summary = "List Projects", description = "Returns a paginated list of projects. Public Visitors can access APPROVED & PUBLIC projects.")
    public ResponseEntity<ApiResponse<PageResponse<ProjectSummaryDto>>> getAllProjects(
            @RequestParam(required = false) Long departmentId,
            @RequestParam(required = false) ProjectStatus status,
            @RequestParam(required = false) ProjectVisibility visibility,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir,
            @AuthenticationPrincipal UserPrincipal currentUser) {

        Sort sort = sortDir.equalsIgnoreCase("asc") ? Sort.by(sortBy).ascending() : Sort.by(sortBy).descending();
        Pageable pageable = PageRequest.of(page, size, sort);
        PageResponse<ProjectSummaryDto> response = projectService.getAllProjects(departmentId, status, visibility, pageable, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Projects retrieved successfully", response));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get Project Details", description = "Returns detailed metadata and team members for a project by ID.")
    public ResponseEntity<ApiResponse<ProjectDetailDto>> getProjectById(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal currentUser) {
        ProjectDetailDto project = projectService.getProjectById(id, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Project details retrieved successfully", project));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('STUDENT', 'FACULTY', 'ADMIN')")
    @SecurityRequirement(name = "bearerAuth")
    @Operation(summary = "Create Project Draft", description = "Creates a new academic project in DRAFT status.")
    public ResponseEntity<ApiResponse<ProjectDetailDto>> createProject(
            @Valid @RequestBody CreateProjectRequest request,
            @AuthenticationPrincipal UserPrincipal currentUser) {
        ProjectDetailDto created = projectService.createProject(request, currentUser);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Project draft created successfully", created));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('STUDENT', 'FACULTY', 'ADMIN')")
    @SecurityRequirement(name = "bearerAuth")
    @Operation(summary = "Update Project", description = "Updates a project draft or rejected project entry.")
    public ResponseEntity<ApiResponse<ProjectDetailDto>> updateProject(
            @PathVariable Long id,
            @Valid @RequestBody UpdateProjectRequest request,
            @AuthenticationPrincipal UserPrincipal currentUser) {
        ProjectDetailDto updated = projectService.updateProject(id, request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Project updated successfully", updated));
    }

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasAnyRole('STUDENT', 'FACULTY', 'ADMIN')")
    @SecurityRequirement(name = "bearerAuth")
    @Operation(summary = "Transition Project Lifecycle Status", description = "Transitions project status along the state machine: DRAFT -> SUBMITTED -> UNDER_REVIEW -> APPROVED / REJECTED -> ARCHIVED.")
    public ResponseEntity<ApiResponse<ProjectDetailDto>> transitionProjectStatus(
            @PathVariable Long id,
            @Valid @RequestBody ProjectStatusTransitionRequest request,
            @AuthenticationPrincipal UserPrincipal currentUser) {
        ProjectDetailDto updated = projectService.transitionProjectStatus(id, request, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Project status transitioned to " + updated.getStatus(), updated));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('STUDENT', 'ADMIN')")
    @SecurityRequirement(name = "bearerAuth")
    @Operation(summary = "Delete Project Entry", description = "Deletes a draft project entry. Students can delete drafts; Admins can delete any project.")
    public ResponseEntity<ApiResponse<Void>> deleteProject(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal currentUser) {
        projectService.deleteProject(id, currentUser);
        return ResponseEntity.ok(ApiResponse.success("Project deleted successfully", null));
    }
}
