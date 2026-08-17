package com.projectvault.dto.response;

import com.projectvault.entity.ProjectStatus;
import java.time.LocalDateTime;

public class ProjectWorkflowHistoryDto {

    private Long id;
    private ProjectStatus fromStatus;
    private ProjectStatus toStatus;
    private Long changedByUserId;
    private String changedByFullName;
    private LocalDateTime createdAt;

    public ProjectWorkflowHistoryDto() {}

    public ProjectWorkflowHistoryDto(Long id, ProjectStatus fromStatus, ProjectStatus toStatus, Long changedByUserId, String changedByFullName, LocalDateTime createdAt) {
        this.id = id;
        this.fromStatus = fromStatus;
        this.toStatus = toStatus;
        this.changedByUserId = changedByUserId;
        this.changedByFullName = changedByFullName;
        this.createdAt = createdAt;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public ProjectStatus getFromStatus() {
        return fromStatus;
    }

    public void setFromStatus(ProjectStatus fromStatus) {
        this.fromStatus = fromStatus;
    }

    public ProjectStatus getToStatus() {
        return toStatus;
    }

    public void setToStatus(ProjectStatus toStatus) {
        this.toStatus = toStatus;
    }

    public Long getChangedByUserId() {
        return changedByUserId;
    }

    public void setChangedByUserId(Long changedByUserId) {
        this.changedByUserId = changedByUserId;
    }

    public String getChangedByFullName() {
        return changedByFullName;
    }

    public void setChangedByFullName(String changedByFullName) {
        this.changedByFullName = changedByFullName;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
