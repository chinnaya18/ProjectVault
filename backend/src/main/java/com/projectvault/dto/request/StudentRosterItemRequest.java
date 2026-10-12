package com.projectvault.dto.request;

public class StudentRosterItemRequest {
    private String rollNo;
    private String name;
    private String email;
    private String batch;
    private Long departmentId;
    private Boolean isEligible;

    public StudentRosterItemRequest() {}

    public StudentRosterItemRequest(String rollNo, String name, String email, String batch, Long departmentId, Boolean isEligible) {
        this.rollNo = rollNo;
        this.name = name;
        this.email = email;
        this.batch = batch;
        this.departmentId = departmentId;
        this.isEligible = isEligible != null ? isEligible : true;
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

    public Boolean getIsEligible() {
        return isEligible;
    }

    public void setIsEligible(Boolean isEligible) {
        this.isEligible = isEligible;
    }
}
