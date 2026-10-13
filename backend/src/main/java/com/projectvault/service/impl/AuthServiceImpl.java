package com.projectvault.service.impl;

import com.projectvault.dto.request.LoginRequest;
import com.projectvault.dto.request.RegisterRequest;
import com.projectvault.dto.response.AuthResponse;
import com.projectvault.dto.response.UserSummaryDto;
import com.projectvault.entity.Department;
import com.projectvault.entity.Role;
import com.projectvault.entity.User;
import com.projectvault.exception.BadRequestException;
import com.projectvault.exception.ResourceNotFoundException;
import com.projectvault.exception.UnauthorizedException;
import com.projectvault.mapper.UserMapper;
import com.projectvault.repository.DepartmentRepository;
import com.projectvault.repository.UserRepository;
import com.projectvault.security.JwtProvider;
import com.projectvault.security.UserPrincipal;
import com.projectvault.service.AuthService;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final DepartmentRepository departmentRepository;
    private final com.projectvault.repository.StudentRosterRepository studentRosterRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtProvider jwtProvider;
    private final UserMapper userMapper;
    private final com.projectvault.service.AuditLogService auditLogService;
    private final com.projectvault.service.EmailService emailService;
    private static final org.slf4j.Logger logger = org.slf4j.LoggerFactory.getLogger(AuthServiceImpl.class);

    public AuthServiceImpl(
            UserRepository userRepository,
            DepartmentRepository departmentRepository,
            com.projectvault.repository.StudentRosterRepository studentRosterRepository,
            PasswordEncoder passwordEncoder,
            AuthenticationManager authenticationManager,
            JwtProvider jwtProvider,
            UserMapper userMapper,
            com.projectvault.service.AuditLogService auditLogService,
            com.projectvault.service.EmailService emailService) {
        this.userRepository = userRepository;
        this.departmentRepository = departmentRepository;
        this.studentRosterRepository = studentRosterRepository;
        this.passwordEncoder = passwordEncoder;
        this.authenticationManager = authenticationManager;
        this.jwtProvider = jwtProvider;
        this.userMapper = userMapper;
        this.auditLogService = auditLogService;
        this.emailService = emailService;
    }

    @Override
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String email = request.getEmail() != null ? request.getEmail().trim().toLowerCase() : "";
        if (!email.endsWith("@psgtech.ac.in")) {
            throw new BadRequestException("Registration is restricted to official PSG College of Technology accounts (@psgtech.ac.in).");
        }

        if (userRepository.existsByEmail(email)) {
            throw new BadRequestException("Email is already registered: " + email);
        }

        String rollNo = request.getRollNo();
        if (rollNo == null || rollNo.isBlank()) {
            rollNo = email.split("@")[0].toUpperCase();
        } else {
            rollNo = rollNo.trim().toUpperCase();
        }

        String studentName = request.getName();

        // Strict Roster Whitelist Verification (Discontinued & External Student Protection)
        if (studentRosterRepository.count() > 0) {
            final String finalRollNo = rollNo;
            com.projectvault.entity.StudentRoster roster = studentRosterRepository.findByRollNoIgnoreCase(finalRollNo)
                    .orElseThrow(() -> new BadRequestException("Roll number '" + finalRollNo + "' is not registered in the official MCA nominal roll. Please contact Department Admin."));

            if (!roster.isEligible()) {
                throw new BadRequestException("This roll number is marked as discontinued or ineligible. Registration is blocked. Please contact HOD.");
            }

            if (roster.isRegistered()) {
                throw new BadRequestException("An account has already been registered for roll number '" + finalRollNo + "'. Please sign in.");
            }

            if (roster.getEmail() != null && !roster.getEmail().equalsIgnoreCase(email)) {
                throw new BadRequestException("Email '" + email + "' does not match official institutional email registered for roll number " + finalRollNo + " (" + roster.getEmail() + ").");
            }

            // Adopt official name from verified department roster
            if (roster.getName() != null && !roster.getName().isBlank()) {
                studentName = roster.getName();
            }

            roster.setRegistered(true);
            studentRosterRepository.save(roster);
        }

        Department department = departmentRepository.findById(1L).orElse(null);
        if (request.getDepartmentId() != null) {
            department = departmentRepository.findById(request.getDepartmentId()).orElse(department);
        }

        User user = new User(
                email,
                passwordEncoder.encode(request.getPassword()),
                studentName,
                rollNo,
                Role.STUDENT,
                department
        );
        user.setMustChangePassword(true);

        User savedUser = userRepository.save(user);
        auditLogService.logEvent(savedUser.getId(), "USER_REGISTER", "USER", savedUser.getId(), "Student registered account: " + savedUser.getEmail() + " [Roll: " + rollNo + "]", null);

        String token = jwtProvider.generateTokenFromUser(savedUser.getId(), savedUser.getEmail());
        UserSummaryDto userSummary = userMapper.toUserSummaryDto(savedUser);

        return new AuthResponse(token, jwtProvider.getJwtExpirationMs(), userSummary);
    }

    @Override
    @Transactional
    public AuthResponse login(LoginRequest request) {
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            request.getEmail(),
                            request.getPassword()
                    )
            );

            SecurityContextHolder.getContext().setAuthentication(authentication);

            UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
            User user = userRepository.findById(userPrincipal.getId())
                    .orElseThrow(() -> new ResourceNotFoundException("User", "id", userPrincipal.getId()));

            String token = jwtProvider.generateToken(authentication);
            UserSummaryDto userSummary = userMapper.toUserSummaryDto(user);

            auditLogService.logEvent(user.getId(), "USER_LOGIN", "USER", user.getId(), "User successfully authenticated", null);

            return new AuthResponse(token, jwtProvider.getJwtExpirationMs(), userSummary);
        } catch (BadCredentialsException ex) {
            throw new UnauthorizedException("Invalid email or password");
        }
    }

    @Override
    @Transactional(readOnly = true)
    public UserSummaryDto getCurrentUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));
        return userMapper.toUserSummaryDto(user);
    }

    @Override
    @Transactional
    public String requestOtp(String email) {
        String cleanEmail = email != null ? email.trim().toLowerCase() : "";
        User user = userRepository.findByEmail(cleanEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", cleanEmail));

        String otp = String.format("%06d", new java.security.SecureRandom().nextInt(1000000));
        user.setOtpCode(otp);
        user.setOtpExpiry(java.time.LocalDateTime.now().plusMinutes(10));
        userRepository.save(user);

        logger.info("=================================================================");
        logger.info("INSTITUTIONAL SECURITY OTP FOR [{} ({})]: {}", cleanEmail, user.getRole(), otp);
        logger.info("=================================================================");

        emailService.sendOtpEmail(cleanEmail, otp, "Account Verification / Password Security", user.getName());

        auditLogService.logEvent(user.getId(), "OTP_REQUESTED", "USER", user.getId(),
                "Verification OTP generated and dispatched for: " + cleanEmail + " (" + user.getRole() + ")", null);

        return otp;
    }

    @Override
    @Transactional
    public AuthResponse verifyOtpAndActivate(String email, String otp, String newPassword) {
        String cleanEmail = email != null ? email.trim().toLowerCase() : "";
        User user = userRepository.findByEmail(cleanEmail)
                .orElseThrow(() -> new ResourceNotFoundException("User", "email", cleanEmail));

        if (user.getOtpCode() == null || !user.getOtpCode().equals(otp.trim())) {
            throw new BadRequestException("Invalid One-Time Password (OTP). Please check your email or request a new code.");
        }

        if (user.getOtpExpiry() == null || java.time.LocalDateTime.now().isAfter(user.getOtpExpiry())) {
            throw new BadRequestException("The OTP has expired. Please request a new verification code.");
        }

        if (newPassword == null || newPassword.length() < 8) {
            throw new BadRequestException("Password must be at least 8 characters long.");
        }

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        user.setMustChangePassword(false);
        user.setOtpCode(null);
        user.setOtpExpiry(null);
        userRepository.save(user);

        auditLogService.logEvent(user.getId(), "ACCOUNT_ACTIVATED_VIA_OTP", "USER", user.getId(),
                "Account successfully activated with private password: " + cleanEmail + " (" + user.getRole() + ")", null);

        String token = jwtProvider.generateTokenFromUser(user.getId(), user.getEmail());
        UserSummaryDto summary = userMapper.toUserSummaryDto(user);

        return new AuthResponse(token, jwtProvider.getJwtExpirationMs(), summary);
    }

    @Override
    @Transactional
    public String requestPasswordResetOtp(String email) {
        return requestOtp(email);
    }

    @Override
    @Transactional
    public void resetPasswordWithOtp(String email, String otp, String newPassword) {
        verifyOtpAndActivate(email, otp, newPassword);
    }

    @Override
    @Transactional
    public void changePasswordWithOtp(Long userId, String otp, String newPassword) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        if (user.getOtpCode() == null || !user.getOtpCode().equals(otp.trim())) {
            throw new BadRequestException("Invalid One-Time Password (OTP). Please check your email.");
        }

        if (user.getOtpExpiry() == null || java.time.LocalDateTime.now().isAfter(user.getOtpExpiry())) {
            throw new BadRequestException("The OTP has expired. Please request a new verification code.");
        }

        if (newPassword == null || newPassword.length() < 8) {
            throw new BadRequestException("New password must be at least 8 characters long.");
        }

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        user.setMustChangePassword(false);
        user.setOtpCode(null);
        user.setOtpExpiry(null);
        userRepository.save(user);

        auditLogService.logEvent(user.getId(), "PASSWORD_CHANGED_WITH_OTP", "USER", user.getId(),
                "Password successfully updated via OTP for: " + user.getEmail(), null);
    }

    @Override
    @Transactional
    public String requestFacultyOtp(String email) {
        return requestOtp(email);
    }

    @Override
    @Transactional
    public AuthResponse activateFacultyAccount(String email, String otp, String newPassword) {
        return verifyOtpAndActivate(email, otp, newPassword);
    }

    @Override
    @Transactional
    public void changePassword(Long userId, String currentPassword, String newPassword) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        if (!passwordEncoder.matches(currentPassword, user.getPasswordHash())) {
            throw new BadRequestException("Incorrect current password.");
        }

        if (newPassword == null || newPassword.length() < 8) {
            throw new BadRequestException("New password must be at least 8 characters long.");
        }

        user.setPasswordHash(passwordEncoder.encode(newPassword));
        user.setMustChangePassword(false);
        userRepository.save(user);

        auditLogService.logEvent(user.getId(), "USER_PASSWORD_CHANGED", "USER", user.getId(),
                "User changed private password: " + user.getEmail(), null);
    }
}
