package com.projectvault.service;

import com.projectvault.dto.response.AuditLogDto;
import com.projectvault.dto.response.PageResponse;
import org.springframework.data.domain.Pageable;

public interface AuditLogService {

    void logEvent(Long userId, String action, String entityType, Long entityId, String details, String ipAddress);

    PageResponse<AuditLogDto> getAuditLogs(String action, String entityType, Pageable pageable);
}
