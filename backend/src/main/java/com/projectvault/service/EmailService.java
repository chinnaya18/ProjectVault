package com.projectvault.service;

public interface EmailService {
    void sendOtpEmail(String toEmail, String otpCode, String purpose, String recipientName);
}
