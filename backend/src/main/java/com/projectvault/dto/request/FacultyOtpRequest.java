package com.projectvault.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public class FacultyOtpRequest {

    @NotBlank(message = "Faculty email is required")
    @Email(message = "Invalid email format")
    private String email;

    public FacultyOtpRequest() {}

    public FacultyOtpRequest(String email) {
        this.email = email;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }
}
