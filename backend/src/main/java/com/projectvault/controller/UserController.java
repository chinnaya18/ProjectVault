package com.projectvault.controller;

import com.projectvault.dto.request.UpdateUserRoleRequest;
import com.projectvault.dto.request.UpdateUserStatusRequest;
import com.projectvault.dto.response.ApiResponse;
import com.projectvault.dto.response.PageResponse;
import com.projectvault.dto.response.UserSummaryDto;
import com.projectvault.entity.Role;
import com.projectvault.entity.UserStatus;
import com.projectvault.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/users")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "User Management", description = "User Administration & Role/Status Management APIs")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'FACULTY', 'STUDENT')")
    @Operation(summary = "List Users", description = "Returns a paginated list of system users. Filterable by departmentId, role, or userStatus.")
    public ResponseEntity<ApiResponse<PageResponse<UserSummaryDto>>> getAllUsers(
            @RequestParam(required = false) Long departmentId,
            @RequestParam(required = false) Role role,
            @RequestParam(required = false) UserStatus userStatus,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "name") String sortBy,
            @RequestParam(defaultValue = "asc") String sortDir) {

        Sort sort = sortDir.equalsIgnoreCase("desc") ? Sort.by(sortBy).descending() : Sort.by(sortBy).ascending();
        Pageable pageable = PageRequest.of(page, size, sort);
        PageResponse<UserSummaryDto> response = userService.getAllUsers(departmentId, role, userStatus, pageable);
        return ResponseEntity.ok(ApiResponse.success("Users retrieved successfully", response));
    }

    @GetMapping("/faculty")
    @PreAuthorize("hasAnyRole('ADMIN', 'FACULTY', 'STUDENT')")
    @Operation(summary = "List Faculty Guides", description = "Returns a list of all active faculty members for project guide assignment.")
    public ResponseEntity<ApiResponse<java.util.List<UserSummaryDto>>> getFacultyGuides() {
        java.util.List<UserSummaryDto> faculty = userService.getFacultyMembers();
        return ResponseEntity.ok(ApiResponse.success("Faculty guides retrieved successfully", faculty));
    }

    @GetMapping("/students")
    @PreAuthorize("hasAnyRole('ADMIN', 'FACULTY', 'STUDENT')")
    @Operation(summary = "List Registered Students", description = "Returns a list of all active student accounts for team formation.")
    public ResponseEntity<ApiResponse<java.util.List<UserSummaryDto>>> getStudents() {
        java.util.List<UserSummaryDto> students = userService.getStudents();
        return ResponseEntity.ok(ApiResponse.success("Students retrieved successfully", students));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'FACULTY', 'STUDENT')")
    @Operation(summary = "Get User Profile", description = "Returns details of a user by ID.")
    public ResponseEntity<ApiResponse<UserSummaryDto>> getUserById(@PathVariable Long id) {
        UserSummaryDto user = userService.getUserById(id);
        return ResponseEntity.ok(ApiResponse.success("User retrieved successfully", user));
    }

    @PutMapping("/{id}/role")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Update User Role", description = "Updates a user's role (ADMIN, FACULTY, STUDENT). Admin access required.")
    public ResponseEntity<ApiResponse<UserSummaryDto>> updateUserRole(
            @PathVariable Long id,
            @Valid @RequestBody UpdateUserRoleRequest request) {
        UserSummaryDto updated = userService.updateUserRole(id, request);
        return ResponseEntity.ok(ApiResponse.success("User role updated successfully", updated));
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Update User Status (Graduation Lifecycle)", description = "Updates user status (ACTIVE, ALUMNI, INACTIVE). Handles student graduation without duplicate accounts.")
    public ResponseEntity<ApiResponse<UserSummaryDto>> updateUserStatus(
            @PathVariable Long id,
            @Valid @RequestBody UpdateUserStatusRequest request) {
        UserSummaryDto updated = userService.updateUserStatus(id, request);
        return ResponseEntity.ok(ApiResponse.success("User status updated successfully", updated));
    }
}
