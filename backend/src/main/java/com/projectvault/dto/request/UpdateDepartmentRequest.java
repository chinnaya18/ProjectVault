package com.projectvault.dto.request;

import jakarta.validation.constraints.Size;

public class UpdateDepartmentRequest {

    @Size(max = 100, message = "Department name cannot exceed 100 characters")
    private String name;

    @Size(max = 20, message = "Department code cannot exceed 20 characters")
    private String code;

    private String description;

    public UpdateDepartmentRequest() {}

    public UpdateDepartmentRequest(String name, String code, String description) {
        this.name = name;
        this.code = code;
        this.description = description;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }
}
