package com.projectvault.dto.request;

import jakarta.validation.constraints.NotEmpty;
import java.util.List;

public class StudentRosterBulkRequest {

    @NotEmpty(message = "Student list must not be empty")
    private List<StudentRosterItemRequest> students;

    private String defaultBatch;
    private Long defaultDepartmentId;

    public StudentRosterBulkRequest() {}

    public StudentRosterBulkRequest(List<StudentRosterItemRequest> students, String defaultBatch, Long defaultDepartmentId) {
        this.students = students;
        this.defaultBatch = defaultBatch;
        this.defaultDepartmentId = defaultDepartmentId;
    }

    public List<StudentRosterItemRequest> getStudents() {
        return students;
    }

    public void setStudents(List<StudentRosterItemRequest> students) {
        this.students = students;
    }

    public String getDefaultBatch() {
        return defaultBatch;
    }

    public void setDefaultBatch(String defaultBatch) {
        this.defaultBatch = defaultBatch;
    }

    public Long getDefaultDepartmentId() {
        return defaultDepartmentId;
    }

    public void setDefaultDepartmentId(Long defaultDepartmentId) {
        this.defaultDepartmentId = defaultDepartmentId;
    }
}
