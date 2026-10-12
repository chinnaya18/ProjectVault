package com.projectvault.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class FacultyActivateRequest {

    @NotBlank(message = "Faculty email is required")
    @Email(message = "Invalid email format")
    private String email;

    @NotBlank(message = "One-Time Password (OTP) is required")
    @Size(min = 6, max = 10, message = "OTP must be 6 digits")
    private String otp;

    @NotBlank(message = "New private password is required")
    @Size(min = 8, max = 50, message = "Password must be at least 8 characters long")
    private String newPassword;

    public FacultyActivateRequest() {}

    public FacultyActivateRequest(String email, String otp, String newPassword) {
        this.email = email;
        this.otp = otp;
        this.newPassword = newPassword;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getOtp() {
        return otp;
    }

    public void setOtp(String otp) {
        this.otp = otp;
    }

    public String getNewPassword() {
        return newPassword;
    }

    public void setNewPassword(String newPassword) {
        this.newPassword = newPassword;
    }
}
