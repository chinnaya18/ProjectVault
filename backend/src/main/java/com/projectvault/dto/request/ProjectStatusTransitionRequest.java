package com.projectvault.dto.request;

import com.projectvault.entity.ProjectStatus;
import jakarta.validation.constraints.NotNull;

public class ProjectStatusTransitionRequest {

    @NotNull(message = "Target status is required")
    private ProjectStatus status;

    private String feedback;

    public ProjectStatusTransitionRequest() {}

    public ProjectStatusTransitionRequest(ProjectStatus status, String feedback) {
        this.status = status;
        this.feedback = feedback;
    }

    public ProjectStatus getStatus() {
        return status;
    }

    public void setStatus(ProjectStatus status) {
        this.status = status;
    }

    public String getFeedback() {
        return feedback;
    }

    public void setFeedback(String feedback) {
        this.feedback = feedback;
    }
}
