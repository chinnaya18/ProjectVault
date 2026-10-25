package com.projectvault.controller;

import com.projectvault.dto.request.StudentRosterBulkRequest;
import com.projectvault.dto.request.StudentRosterItemRequest;
import com.projectvault.dto.response.ApiResponse;
import com.projectvault.dto.response.PageResponse;
import com.projectvault.dto.response.StudentRosterDto;
import com.projectvault.dto.response.StudentRosterStatsDto;
import com.projectvault.security.UserPrincipal;
import com.projectvault.service.StudentRosterService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/roster")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Student Nominal Roll Whitelist", description = "Admin Student Roster Ingestion & Whitelist Management APIs")
public class StudentRosterController {

    private final StudentRosterService studentRosterService;

    public StudentRosterController(StudentRosterService studentRosterService) {
        this.studentRosterService = studentRosterService;
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'FACULTY')")
    @Operation(summary = "Get Student Roster", description = "Returns a paginated list of students on the nominal roll whitelist.")
    public ResponseEntity<ApiResponse<PageResponse<StudentRosterDto>>> getRoster(
            @RequestParam(required = false) Long departmentId,
            @RequestParam(required = false) String batch,
            @RequestParam(required = false) Boolean isEligible,
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "rollNo") String sortBy,
            @RequestParam(defaultValue = "asc") String sortDir) {

        Sort sort = sortDir.equalsIgnoreCase("desc") ? Sort.by(sortBy).descending() : Sort.by(sortBy).ascending();
        Pageable pageable = PageRequest.of(page, size, sort);
        PageResponse<StudentRosterDto> response = studentRosterService.getRoster(departmentId, batch, isEligible, search, pageable);
        return ResponseEntity.ok(ApiResponse.success("Student roster retrieved successfully", response));
    }

    @PostMapping("/bulk")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Bulk Ingest Students", description = "Ingests a list of students parsed from Excel or CSV directly into the nominal roll.")
    public ResponseEntity<ApiResponse<Map<String, Object>>> bulkIngest(
            @Valid @RequestBody StudentRosterBulkRequest request,
            @AuthenticationPrincipal UserPrincipal currentUser) {

        Long adminId = currentUser != null ? currentUser.getId() : 1L;
        Map<String, Object> result = studentRosterService.importBulkRoster(request, adminId);
        return ResponseEntity.ok(ApiResponse.success("Roster ingested successfully", result));
    }

    @PostMapping(value = "/upload-csv", consumes = "multipart/form-data")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Upload Roster CSV", description = "Uploads a CSV file containing Roll Number and Name to ingest students.")
    public ResponseEntity<ApiResponse<Map<String, Object>>> uploadCsv(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "batch", defaultValue = "2025-2027") String batch,
            @RequestParam(value = "departmentId", defaultValue = "1") Long departmentId,
            @RequestParam(value = "syncMode", defaultValue = "false") Boolean syncMode,
            @AuthenticationPrincipal UserPrincipal currentUser) throws Exception {

        List<StudentRosterItemRequest> items = new ArrayList<>();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(file.getInputStream(), StandardCharsets.UTF_8))) {
            String line;
            boolean isHeader = true;
            while ((line = reader.readLine()) != null) {
                line = line.trim();
                if (line.isEmpty()) continue;
                String[] cols = line.split(",");
                if (isHeader) {
                    isHeader = false;
                    // Check if first row is header
                    if (cols.length > 0 && (cols[0].toLowerCase().contains("roll") || cols[0].toLowerCase().contains("s.no") || cols[0].toLowerCase().contains("sno"))) {
                        continue;
                    }
                }
                if (cols.length >= 2) {
                    int rollIdx = 0;
                    int nameIdx = 1;
                    int emailIdx = -1;
                    if (cols.length >= 3 && (cols[0].matches("\\d+") || cols[0].length() <= 3)) {
                        // S.No, RollNo, Name
                        rollIdx = 1;
                        nameIdx = 2;
                        if (cols.length >= 4) emailIdx = 3;
                    } else if (cols.length >= 3) {
                        emailIdx = 2;
                    }

                    String roll = cols[rollIdx].trim().replace("\"", "");
                    String name = cols[nameIdx].trim().replace("\"", "");
                    String email = (emailIdx != -1 && emailIdx < cols.length) ? cols[emailIdx].trim().replace("\"", "") : null;

                    if (!roll.isEmpty() && !name.isEmpty()) {
                        items.add(new StudentRosterItemRequest(roll, name, email, batch, departmentId, true));
                    }
                }
            }
        }

        StudentRosterBulkRequest bulkReq = new StudentRosterBulkRequest(items, batch, departmentId, syncMode);
        Long adminId = currentUser != null ? currentUser.getId() : 1L;
        Map<String, Object> result = studentRosterService.importBulkRoster(bulkReq, adminId);
        return ResponseEntity.ok(ApiResponse.success("CSV roster imported successfully", result));
    }

    @DeleteMapping("/batch")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Purge Unregistered Students in Batch", description = "Removes all unregistered nominal roll entries in a specified batch.")
    public ResponseEntity<ApiResponse<Map<String, Object>>> purgeBatch(
            @RequestParam String batch,
            @RequestParam(required = false) Long departmentId,
            @AuthenticationPrincipal UserPrincipal currentUser) {

        Long adminId = currentUser != null ? currentUser.getId() : 1L;
        Map<String, Object> result = studentRosterService.purgeBatch(batch, departmentId, adminId);
        return ResponseEntity.ok(ApiResponse.success("Batch nominal roll purged successfully", result));
    }

    @PutMapping("/{id}/toggle-eligibility")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Toggle Student Eligibility", description = "Toggles active vs discontinued status for a student.")
    public ResponseEntity<ApiResponse<StudentRosterDto>> toggleEligibility(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal currentUser) {

        Long adminId = currentUser != null ? currentUser.getId() : 1L;
        StudentRosterDto result = studentRosterService.toggleEligibility(id, adminId);
        return ResponseEntity.ok(ApiResponse.success("Student eligibility status updated successfully", result));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Delete Student From Roster", description = "Removes a student from the nominal roll whitelist (only if unregistered).")
    public ResponseEntity<ApiResponse<Void>> deleteRoster(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal currentUser) {

        Long adminId = currentUser != null ? currentUser.getId() : 1L;
        studentRosterService.deleteRosterItem(id, adminId);
        return ResponseEntity.ok(ApiResponse.success("Student removed from nominal roll successfully", null));
    }

    @GetMapping("/stats")
    @PreAuthorize("hasAnyRole('ADMIN', 'FACULTY')")
    @Operation(summary = "Get Roster Statistics", description = "Returns summary counts of registered, eligible, and discontinued students.")
    public ResponseEntity<ApiResponse<StudentRosterStatsDto>> getStats() {
        StudentRosterStatsDto stats = studentRosterService.getStats();
        return ResponseEntity.ok(ApiResponse.success("Roster statistics retrieved successfully", stats));
    }
}
