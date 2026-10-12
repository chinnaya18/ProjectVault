package com.projectvault.dto.response;

import java.time.LocalDateTime;

public class StudentRosterDto {
    private Long id;
    private String rollNo;
    private String name;
    private String email;
    private String batch;
    private Long departmentId;
    private String departmentName;
    private boolean isEligible;
    private boolean isRegistered;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public StudentRosterDto() {}

    public StudentRosterDto(Long id, String rollNo, String name, String email, String batch,
                            Long departmentId, String departmentName, boolean isEligible,
                            boolean isRegistered, LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id;
        this.rollNo = rollNo;
        this.name = name;
        this.email = email;
        this.batch = batch;
        this.departmentId = departmentId;
        this.departmentName = departmentName;
        this.isEligible = isEligible;
        this.isRegistered = isRegistered;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getRollNo() {
        return rollNo;
    }

    public void setRollNo(String rollNo) {
        this.rollNo = rollNo;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getBatch() {
        return batch;
    }

    public void setBatch(String batch) {
        this.batch = batch;
    }

    public Long getDepartmentId() {
        return departmentId;
    }

    public void setDepartmentId(Long departmentId) {
        this.departmentId = departmentId;
    }

    public String getDepartmentName() {
        return departmentName;
    }

    public void setDepartmentName(String departmentName) {
        this.departmentName = departmentName;
    }

    public boolean isEligible() {
        return isEligible;
    }

    public void setEligible(boolean eligible) {
        isEligible = eligible;
    }

    public boolean isRegistered() {
        return isRegistered;
    }

    public void setRegistered(boolean registered) {
        isRegistered = registered;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
