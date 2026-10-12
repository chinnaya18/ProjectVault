package com.projectvault.service;

import com.projectvault.dto.request.LoginRequest;
import com.projectvault.dto.request.RegisterRequest;
import com.projectvault.dto.response.AuthResponse;
import com.projectvault.dto.response.UserSummaryDto;

public interface AuthService {
    AuthResponse register(RegisterRequest request);
    AuthResponse login(LoginRequest request);
    UserSummaryDto getCurrentUser(Long userId);

    // Universal Email OTP methods (Students, Faculty, and Admin)
    void requestOtp(String email);
    AuthResponse verifyOtpAndActivate(String email, String otp, String newPassword);
    void requestPasswordResetOtp(String email);
    void resetPasswordWithOtp(String email, String otp, String newPassword);
    void changePasswordWithOtp(Long userId, String otp, String newPassword);

    // Backwards-compatible aliases
    void requestFacultyOtp(String email);
    AuthResponse activateFacultyAccount(String email, String otp, String newPassword);
    void changePassword(Long userId, String currentPassword, String newPassword);
}

