package com.projectvault.service.impl;

import com.projectvault.dto.response.AuditLogDto;
import com.projectvault.dto.response.PageResponse;
import com.projectvault.entity.AuditLog;
import com.projectvault.entity.User;
import com.projectvault.repository.AuditLogRepository;
import com.projectvault.repository.UserRepository;
import com.projectvault.service.AuditLogService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuditLogServiceImpl implements AuditLogService {

    private static final Logger logger = LoggerFactory.getLogger(AuditLogServiceImpl.class);

    private final AuditLogRepository auditLogRepository;
    private final UserRepository userRepository;

    public AuditLogServiceImpl(AuditLogRepository auditLogRepository, UserRepository userRepository) {
        this.auditLogRepository = auditLogRepository;
        this.userRepository = userRepository;
    }

    @Override
    @Transactional(propagation = org.springframework.transaction.annotation.Propagation.REQUIRES_NEW)
    public void logEvent(Long userId, String action, String entityType, Long entityId, String details, String ipAddress) {
        try {
            User user = null;
            if (userId != null) {
                user = userRepository.findById(userId).orElse(null);
            }

            AuditLog log = new AuditLog(user, action, entityType, entityId, details, ipAddress);
            auditLogRepository.save(log);
            logger.info("AUDIT: action='{}' entityType='{}' entityId={} userId={}", action, entityType, entityId, userId);
        } catch (Exception ex) {
            logger.error("Failed to persist audit log: {}", ex.getMessage());
        }
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<AuditLogDto> getAuditLogs(String action, String entityType, Pageable pageable) {
        String cleanAction = (action != null && !action.trim().isEmpty()) ? action.trim() : null;
        String cleanType = (entityType != null && !entityType.trim().isEmpty()) ? entityType.trim() : null;

        Page<AuditLog> page = auditLogRepository.findFilteredAuditLogs(cleanAction, cleanType, pageable);

        Page<AuditLogDto> dtoPage = page.map(log -> {
            Long uid = log.getUser() != null ? log.getUser().getId() : null;
            String uName = log.getUser() != null ? log.getUser().getName() : "System / Anonymous";
            String uEmail = log.getUser() != null ? log.getUser().getEmail() : null;

            return new AuditLogDto(
                    log.getId(),
                    uid,
                    uName,
                    uEmail,
                    log.getAction(),
                    log.getEntityType(),
                    log.getEntityId(),
                    log.getDetails(),
                    log.getIpAddress(),
                    log.getTimestamp()
            );
        });

        return PageResponse.fromPage(dtoPage);
    }
}
