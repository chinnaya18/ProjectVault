package com.projectvault.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class ChangePasswordOtpRequest {

    @NotBlank(message = "OTP verification code is required")
    @Size(min = 6, max = 10, message = "OTP must be 6 digits")
    private String otp;

    @NotBlank(message = "New private password is required")
    @Size(min = 8, max = 50, message = "Password must be at least 8 characters long")
    private String newPassword;

    public ChangePasswordOtpRequest() {}

    public ChangePasswordOtpRequest(String otp, String newPassword) {
        this.otp = otp;
        this.newPassword = newPassword;
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
