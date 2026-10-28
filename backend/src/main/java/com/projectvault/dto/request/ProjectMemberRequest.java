package com.projectvault.dto.request;

import jakarta.validation.constraints.NotBlank;

public class ProjectMemberRequest {

    private Long userId;
    private String email;
    private String rollNo;

    @NotBlank(message = "Member role is required")
    private String memberRole;

    public ProjectMemberRequest() {}

    public ProjectMemberRequest(Long userId, String memberRole) {
        this.userId = userId;
        this.memberRole = memberRole;
    }

    public ProjectMemberRequest(String email, String memberRole) {
        this.email = email;
        this.memberRole = memberRole;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getRollNo() {
        return rollNo;
    }

    public void setRollNo(String rollNo) {
        this.rollNo = rollNo;
    }

    public String getMemberRole() {
        return memberRole;
    }

    public void setMemberRole(String memberRole) {
        this.memberRole = memberRole;
    }
}
