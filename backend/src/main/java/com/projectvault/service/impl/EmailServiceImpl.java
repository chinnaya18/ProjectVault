package com.projectvault.service.impl;

import com.projectvault.service.EmailService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import jakarta.mail.internet.MimeMessage;

@Service
public class EmailServiceImpl implements EmailService {

    private static final Logger logger = LoggerFactory.getLogger(EmailServiceImpl.class);

    @Autowired(required = false)
    private JavaMailSender mailSender;

    @Value("${spring.mail.username:noreply@psgtech.ac.in}")
    private String fromEmail;

    @Value("${spring.mail.host:}")
    private String mailHost;

    @Override
    public void sendOtpEmail(String toEmail, String otpCode, String purpose, String recipientName) {
        String cleanEmail = toEmail != null ? toEmail.trim().toLowerCase() : "";
        String displayName = (recipientName != null && !recipientName.isBlank()) ? recipientName : "ProjectVault User";

        logger.info("===============================================================================");
        logger.info("PSG TECH PROJECTVAULT - OTP DISPATCH FOR: {}", cleanEmail);
        logger.info("PURPOSE: {} | RECIPIENT: {}", purpose, displayName);
        logger.info("ONE-TIME PASSWORD (OTP): >>> {} <<<", otpCode);
        logger.info("VALIDITY: 10 MINUTES");
        logger.info("===============================================================================");

        if (mailSender != null && mailHost != null && !mailHost.trim().isEmpty()) {
            try {
                MimeMessage message = mailSender.createMimeMessage();
                MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
                helper.setFrom(fromEmail, "PSG Tech ProjectVault");
                helper.setTo(cleanEmail);
                helper.setSubject("PSG Tech MCA ProjectVault - Verification Security OTP");

                String htmlContent = "<div style=\"font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 12px; padding: 24px;\">"
                        + "<div style=\"text-align: center; border-bottom: 2px solid #4f46e5; padding-bottom: 16px; margin-bottom: 20px;\">"
                        + "<h2 style=\"color: #1e1b4b; margin: 0;\">PSG College of Technology</h2>"
                        + "<p style=\"color: #64748b; margin: 4px 0 0 0; font-size: 14px;\">Department of Computer Applications (MCA) &bull; ProjectVault</p>"
                        + "</div>"
                        + "<p style=\"color: #334155; font-size: 15px;\">Dear " + displayName + ",</p>"
                        + "<p style=\"color: #334155; font-size: 15px;\">Your verification OTP for <strong>" + purpose + "</strong> is:</p>"
                        + "<div style=\"background: #eef2ff; border-radius: 8px; padding: 16px; text-align: center; margin: 24px 0;\">"
                        + "<span style=\"font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #4338ca; font-family: monospace;\">" + otpCode + "</span>"
                        + "</div>"
                        + "<p style=\"color: #64748b; font-size: 13px;\">This code expires in 10 minutes. If you did not initiate this request, please contact the MCA department administrator immediately.</p>"
                        + "<hr style=\"border: none; border-top: 1px solid #f1f5f9; margin: 20px 0;\"/>"
                        + "<p style=\"color: #94a3b8; font-size: 12px; text-align: center;\">&copy; PSG College of Technology &bull; MCA Department Project Repository</p>"
                        + "</div>";

                helper.setText(htmlContent, true);
                mailSender.send(message);
                logger.info("Successfully delivered SMTP OTP email to {}", cleanEmail);
            } catch (Exception ex) {
                logger.warn("SMTP delivery attempt to {} failed: {}. Logged OTP for console review.", cleanEmail, ex.getMessage());
            }
        }
    }
}
