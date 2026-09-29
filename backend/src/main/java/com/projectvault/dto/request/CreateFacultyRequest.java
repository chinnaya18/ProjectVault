package com.projectvault.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class CreateFacultyRequest {

    @NotBlank(message = "Faculty name is required")
    @Size(max = 100, message = "Name must not exceed 100 characters")
    private String name;

    @NotBlank(message = "Official email is required")
    @Email(message = "Invalid email format")
    private String email;

    @NotBlank(message = "Academic designation is required")
    private String designation; // e.g. "Assistant Professor", "Associate Professor", "Professor"

    private Long departmentId = 1L; // Defaults to MCA

    private String password = "Password@123"; // Default initial password

    public CreateFacultyRequest() {}

    public CreateFacultyRequest(String name, String email, String designation, Long departmentId, String password) {
        this.name = name;
        this.email = email;
        this.designation = designation;
        this.departmentId = departmentId;
        this.password = password != null && !password.isBlank() ? password : "Password@123";
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

    public String getDesignation() {
        return designation;
    }

    public void setDesignation(String designation) {
        this.designation = designation;
    }

    public Long getDepartmentId() {
        return departmentId;
    }

    public void setDepartmentId(Long departmentId) {
        this.departmentId = departmentId;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }
}
