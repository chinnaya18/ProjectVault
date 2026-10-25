package com.projectvault.service;

import com.projectvault.dto.request.StudentRosterBulkRequest;
import com.projectvault.dto.response.PageResponse;
import com.projectvault.dto.response.StudentRosterDto;
import com.projectvault.dto.response.StudentRosterStatsDto;
import org.springframework.data.domain.Pageable;

import java.util.Map;

public interface StudentRosterService {
    PageResponse<StudentRosterDto> getRoster(Long departmentId, String batch, Boolean isEligible, String search, Pageable pageable);
    Map<String, Object> importBulkRoster(StudentRosterBulkRequest request, Long currentUserId);
    StudentRosterDto toggleEligibility(Long id, Long currentUserId);
    void deleteRosterItem(Long id, Long currentUserId);
    Map<String, Object> purgeBatch(String batch, Long departmentId, Long currentUserId);
    StudentRosterStatsDto getStats();
}
