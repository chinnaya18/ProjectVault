package com.projectvault.service.impl;

import com.projectvault.dto.request.StudentRosterBulkRequest;
import com.projectvault.dto.request.StudentRosterItemRequest;
import com.projectvault.dto.response.PageResponse;
import com.projectvault.dto.response.StudentRosterDto;
import com.projectvault.dto.response.StudentRosterStatsDto;
import com.projectvault.entity.Department;
import com.projectvault.entity.StudentRoster;
import com.projectvault.exception.BadRequestException;
import com.projectvault.exception.ResourceNotFoundException;
import com.projectvault.repository.DepartmentRepository;
import com.projectvault.repository.StudentRosterRepository;
import com.projectvault.repository.UserRepository;
import com.projectvault.entity.UserStatus;
import com.projectvault.service.AuditLogService;
import com.projectvault.service.StudentRosterService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Service
public class StudentRosterServiceImpl implements StudentRosterService {

    private static final org.slf4j.Logger logger = org.slf4j.LoggerFactory.getLogger(StudentRosterServiceImpl.class);

    private final StudentRosterRepository studentRosterRepository;
    private final DepartmentRepository departmentRepository;
    private final UserRepository userRepository;
    private final AuditLogService auditLogService;

    public StudentRosterServiceImpl(
            StudentRosterRepository studentRosterRepository,
            DepartmentRepository departmentRepository,
            UserRepository userRepository,
            AuditLogService auditLogService) {
        this.studentRosterRepository = studentRosterRepository;
        this.departmentRepository = departmentRepository;
        this.userRepository = userRepository;
        this.auditLogService = auditLogService;
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<StudentRosterDto> getRoster(Long departmentId, String batch, Boolean isEligible, String search, Pageable pageable) {
        String cleanSearch = (search != null && !search.trim().isBlank()) ? search.trim() : null;
        String cleanBatch = (batch != null && !batch.trim().isBlank()) ? batch.trim() : null;

        Page<StudentRoster> page = studentRosterRepository.searchRoster(departmentId, cleanBatch, isEligible, cleanSearch, pageable);
        Page<StudentRosterDto> dtoPage = page.map(this::toDto);
        return PageResponse.fromPage(dtoPage);
    }

    @Override
    @Transactional
    public Map<String, Object> importBulkRoster(StudentRosterBulkRequest request, Long currentUserId) {
        if (request.getStudents() == null || request.getStudents().isEmpty()) {
            throw new BadRequestException("Student list cannot be empty");
        }

        String defaultBatch = request.getDefaultBatch() != null && !request.getDefaultBatch().isBlank()
                ? request.getDefaultBatch().trim() : "2025-2027";

        Long defaultDeptId = request.getDefaultDepartmentId() != null ? request.getDefaultDepartmentId() : 1L;
        Department defaultDepartment = departmentRepository.findById(defaultDeptId)
                .orElseThrow(() -> new ResourceNotFoundException("Department", "id", defaultDeptId));

        boolean syncMode = Boolean.TRUE.equals(request.getSyncMode());
        Set<String> uploadedRolls = new HashSet<>();

        int createdCount = 0;
        int updatedCount = 0;
        List<String> errors = new ArrayList<>();

        for (int i = 0; i < request.getStudents().size(); i++) {
            StudentRosterItemRequest item = request.getStudents().get(i);
            if (item.getRollNo() == null || item.getRollNo().trim().isBlank()) {
                errors.add("Row " + (i + 1) + ": Roll number is required.");
                continue;
            }
            if (item.getName() == null || item.getName().trim().isBlank()) {
                errors.add("Row " + (i + 1) + " (" + item.getRollNo() + "): Student name is required.");
                continue;
            }

            String rollNo = item.getRollNo().trim().toUpperCase();
            uploadedRolls.add(rollNo);
            String name = item.getName().trim();

            String email = item.getEmail();
            if (email == null || email.trim().isBlank() || !email.contains("@")) {
                email = rollNo.toLowerCase() + "@psgtech.ac.in";
            } else {
                email = email.trim().toLowerCase();
            }

            String batch = item.getBatch() != null && !item.getBatch().isBlank()
                    ? item.getBatch().trim() : defaultBatch;

            Department dept = defaultDepartment;
            if (item.getDepartmentId() != null && !item.getDepartmentId().equals(defaultDeptId)) {
                dept = departmentRepository.findById(item.getDepartmentId()).orElse(defaultDepartment);
            }

            boolean isEligible = item.getIsEligible() != null ? item.getIsEligible() : true;

            Optional<StudentRoster> existingOpt = studentRosterRepository.findByRollNoIgnoreCase(rollNo);
            if (existingOpt.isPresent()) {
                StudentRoster existing = existingOpt.get();
                existing.setName(name);
                existing.setEmail(email);
                existing.setBatch(batch);
                existing.setDepartment(dept);
                existing.setEligible(isEligible);
                studentRosterRepository.save(existing);

                // If student has already registered an active profile, keep profile synchronized
                if (existing.isRegistered()) {
                    final Department fDept = dept;
                    userRepository.findByRollNoIgnoreCase(rollNo).ifPresent(user -> {
                        user.setName(name);
                        user.setDepartment(fDept);
                        userRepository.save(user);
                    });
                }

                updatedCount++;
            } else {
                StudentRoster newRoster = new StudentRoster(
                        rollNo,
                        name,
                        email,
                        batch,
                        dept,
                        isEligible
                );
                studentRosterRepository.save(newRoster);
                createdCount++;
            }
        }

        int deletedCount = 0;
        int preservedActiveCount = 0;
        if (syncMode && defaultBatch != null && !defaultBatch.isBlank()) {
            List<StudentRoster> batchStudents = studentRosterRepository.findByBatchIgnoreCaseAndDepartmentId(defaultBatch.trim(), defaultDeptId);

            for (StudentRoster existing : batchStudents) {
                if (!uploadedRolls.contains(existing.getRollNo().toUpperCase())) {
                    if (existing.isRegistered()) {
                        preservedActiveCount++;
                        logger.warn("Sync mode safely preserved active registered student: {}", existing.getRollNo());
                    } else {
                        studentRosterRepository.delete(existing);
                        deletedCount++;
                    }
                }
            }
        }

        auditLogService.logEvent(
                currentUserId,
                syncMode ? "ROSTER_SYNC_INGEST" : "ROSTER_INGEST",
                "ROSTER",
                null,
                String.format("Bulk roster processed: %d created, %d updated, %d deleted (syncMode=%b), %d errors",
                        createdCount, updatedCount, deletedCount, syncMode, errors.size()),
                null
        );

        Map<String, Object> response = new HashMap<>();
        response.put("created", createdCount);
        response.put("updated", updatedCount);
        response.put("deleted", deletedCount);
        response.put("preservedActive", preservedActiveCount);
        response.put("totalProcessed", createdCount + updatedCount);
        response.put("errors", errors);
        response.put("message", String.format("Successfully processed: %d created, %d updated%s.",
                createdCount, updatedCount,
                syncMode ? String.format(", %d deleted (purged missing rows)", deletedCount) : ""));

        return response;
    }

    @Override
    @Transactional
    public StudentRosterDto toggleEligibility(Long id, Long currentUserId) {
        StudentRoster roster = studentRosterRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("StudentRoster", "id", id));

        boolean newStatus = !roster.isEligible();
        roster.setEligible(newStatus);
        StudentRoster saved = studentRosterRepository.save(roster);

        // Real-time bidirectional sync: update active user account state
        userRepository.findByRollNoIgnoreCase(saved.getRollNo()).ifPresent(user -> {
            user.setActive(newStatus);
            user.setUserStatus(newStatus ? UserStatus.ACTIVE : UserStatus.INACTIVE);
            userRepository.save(user);
            logger.info("Synchronized active user status for roll number {}: active={}, status={}",
                    user.getRollNo(), newStatus, user.getUserStatus());
        });

        auditLogService.logEvent(
                currentUserId,
                "ROSTER_STATUS_CHANGE",
                "ROSTER",
                saved.getId(),
                String.format("Toggled student roster eligibility for %s (%s) to %s (synchronized with active user account)",
                        saved.getRollNo(), saved.getName(), newStatus ? "ELIGIBLE" : "DISCONTINUED"),
                null
        );

        return toDto(saved);
    }

    @Override
    @Transactional
    public void deleteRosterItem(Long id, Long currentUserId) {
        StudentRoster roster = studentRosterRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("StudentRoster", "id", id));

        if (roster.isRegistered()) {
            throw new BadRequestException("Cannot delete roster entry for roll number " + roster.getRollNo() + " because this student has already registered an active system account.");
        }

        studentRosterRepository.delete(roster);

        auditLogService.logEvent(
                currentUserId,
                "ROSTER_DELETE",
                "ROSTER",
                id,
                String.format("Removed roll number %s (%s) from nominal roll whitelist", roster.getRollNo(), roster.getName()),
                null
        );
    }

    @Override
    @Transactional
    public Map<String, Object> purgeBatch(String batch, Long departmentId, Long currentUserId) {
        if (batch == null || batch.trim().isBlank()) {
            throw new BadRequestException("Batch name is required to purge batch records.");
        }
        String cleanBatch = batch.trim();
        List<StudentRoster> batchStudents = studentRosterRepository.findByBatchOrRollPrefix(cleanBatch);

        int deletedCount = 0;
        int preservedCount = 0;
        for (StudentRoster student : batchStudents) {
            if (student.isRegistered()) {
                preservedCount++;
            } else {
                studentRosterRepository.delete(student);
                deletedCount++;
            }
        }

        auditLogService.logEvent(
                currentUserId,
                "ROSTER_PURGE_BATCH",
                "ROSTER",
                null,
                String.format("Purged nominal roll for batch '%s': %d deleted, %d active accounts preserved", cleanBatch, deletedCount, preservedCount),
                null
        );

        Map<String, Object> result = new HashMap<>();
        result.put("batch", cleanBatch);
        result.put("deleted", deletedCount);
        result.put("preserved", preservedCount);
        result.put("message", String.format("Batch '%s' purged: %d unverified records removed, %d active student accounts preserved.",
                cleanBatch, deletedCount, preservedCount));
        return result;
    }

    @Override
    @Transactional(readOnly = true)
    public StudentRosterStatsDto getStats() {
        long total = studentRosterRepository.count();
        long registered = studentRosterRepository.countByIsRegisteredTrue();
        long eligible = studentRosterRepository.countByIsEligibleTrue();
        long discontinued = studentRosterRepository.countByIsEligibleFalse();

        return new StudentRosterStatsDto(total, registered, eligible, discontinued);
    }

    private StudentRosterDto toDto(StudentRoster entity) {
        return new StudentRosterDto(
                entity.getId(),
                entity.getRollNo(),
                entity.getName(),
                entity.getEmail(),
                entity.getBatch(),
                entity.getDepartment() != null ? entity.getDepartment().getId() : null,
                entity.getDepartment() != null ? entity.getDepartment().getName() : null,
                entity.isEligible(),
                entity.isRegistered(),
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }
}
