package com.projectvault.controller;

import com.projectvault.dto.request.LoginRequest;
import com.projectvault.dto.request.RegisterRequest;
import com.projectvault.dto.response.ApiResponse;
import com.projectvault.dto.response.AuthResponse;
import com.projectvault.dto.response.UserSummaryDto;
import com.projectvault.security.UserPrincipal;
import com.projectvault.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Authentication", description = "User Registration, Login, and Profile Management APIs")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    @Operation(summary = "Register New Account", description = "Creates a new Student user account and returns JWT token.")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@Valid @RequestBody RegisterRequest request) {
        AuthResponse authResponse = authService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("User registered successfully", authResponse));
    }

    @PostMapping("/login")
    @Operation(summary = "User Login", description = "Authenticates user credentials and issues JWT token.")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody LoginRequest request) {
        AuthResponse authResponse = authService.login(request);
        return ResponseEntity.ok(ApiResponse.success("Authentication successful", authResponse));
    }

    @GetMapping("/me")
    @SecurityRequirement(name = "bearerAuth")
    @Operation(summary = "Get Current User Profile", description = "Returns details of the currently authenticated user based on JWT.")
    public ResponseEntity<ApiResponse<UserSummaryDto>> getCurrentUser(@AuthenticationPrincipal UserPrincipal userPrincipal) {
        if (userPrincipal == null) {
            throw new com.projectvault.exception.UnauthorizedException("User is not authenticated. Please log in.");
        }
        UserSummaryDto userSummary = authService.getCurrentUser(userPrincipal.getId());
        return ResponseEntity.ok(ApiResponse.success("User profile fetched successfully", userSummary));
    }

    @PostMapping("/request-otp")
    @Operation(summary = "Request Universal Account OTP", description = "Dispatches a secure 6-digit cryptographic OTP to the registered PSG Tech email for any account (Student, Faculty, or Admin).")
    public ResponseEntity<ApiResponse<String>> requestUniversalOtp(@Valid @RequestBody com.projectvault.dto.request.FacultyOtpRequest request) {
        authService.requestOtp(request.getEmail());
        return ResponseEntity.ok(ApiResponse.success("A 6-digit verification code has been dispatched to your official PSG Tech email address. Valid for 10 minutes.", "OTP_DISPATCHED"));
    }

    @PostMapping("/activate")
    @Operation(summary = "Activate Any Account with OTP", description = "Verifies 6-digit OTP, sets private password, unlocks account, and returns JWT token for any user (Student, Faculty, Admin).")
    public ResponseEntity<ApiResponse<AuthResponse>> activateAccount(@Valid @RequestBody com.projectvault.dto.request.FacultyActivateRequest request) {
        AuthResponse response = authService.verifyOtpAndActivate(request.getEmail(), request.getOtp(), request.getNewPassword());
        return ResponseEntity.ok(ApiResponse.success("Account successfully activated with your private password.", response));
    }

    @PostMapping("/faculty/request-otp")
    @Operation(summary = "Request Faculty 1st-Login Activation OTP", description = "Dispatches a secure 6-digit cryptographic OTP to the official @psgtech.ac.in email of the faculty member.")
    public ResponseEntity<ApiResponse<String>> requestFacultyOtp(@Valid @RequestBody com.projectvault.dto.request.FacultyOtpRequest request) {
        authService.requestFacultyOtp(request.getEmail());
        return ResponseEntity.ok(ApiResponse.success("A 6-digit verification code has been dispatched to your official PSG Tech email address. Valid for 10 minutes.", "OTP_DISPATCHED"));
    }

    @PostMapping("/faculty/activate")
    @Operation(summary = "Activate Faculty Account with OTP", description = "Verifies 6-digit OTP, sets private password, unlocks account, and returns JWT.")
    public ResponseEntity<ApiResponse<AuthResponse>> activateFacultyAccount(@Valid @RequestBody com.projectvault.dto.request.FacultyActivateRequest request) {
        AuthResponse response = authService.activateFacultyAccount(request.getEmail(), request.getOtp(), request.getNewPassword());
        return ResponseEntity.ok(ApiResponse.success("Faculty account successfully activated with your private password.", response));
    }

    @PostMapping("/change-password-otp")
    @SecurityRequirement(name = "bearerAuth")
    @Operation(summary = "Request Password Change OTP", description = "Dispatches an OTP to the authenticated user's registered college email prior to password update.")
    public ResponseEntity<ApiResponse<String>> requestPasswordChangeOtp(@AuthenticationPrincipal UserPrincipal userPrincipal) {
        if (userPrincipal == null) {
            throw new com.projectvault.exception.UnauthorizedException("Authentication required.");
        }
        authService.requestOtp(userPrincipal.getEmail());
        return ResponseEntity.ok(ApiResponse.success("Verification code dispatched to your registered email address.", "OTP_DISPATCHED"));
    }

    @PostMapping("/change-password-with-otp")
    @SecurityRequirement(name = "bearerAuth")
    @Operation(summary = "Change Password with Email OTP Verification", description = "Verifies the 6-digit email OTP and updates the account password for any role.")
    public ResponseEntity<ApiResponse<String>> changePasswordWithOtp(
            @Valid @RequestBody com.projectvault.dto.request.ChangePasswordOtpRequest request,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        if (userPrincipal == null) {
            throw new com.projectvault.exception.UnauthorizedException("Authentication required.");
        }
        authService.changePasswordWithOtp(userPrincipal.getId(), request.getOtp(), request.getNewPassword());
        return ResponseEntity.ok(ApiResponse.success("Password updated successfully via email OTP verification.", "PASSWORD_UPDATED"));
    }

    @PostMapping("/change-password")
    @SecurityRequirement(name = "bearerAuth")
    @Operation(summary = "Change Password", description = "Allows authenticated users to change their account password.")
    public ResponseEntity<ApiResponse<String>> changePassword(
            @Valid @RequestBody com.projectvault.dto.request.ChangePasswordRequest request,
            @AuthenticationPrincipal UserPrincipal userPrincipal) {
        if (userPrincipal == null) {
            throw new com.projectvault.exception.UnauthorizedException("Authentication required.");
        }
        authService.changePassword(userPrincipal.getId(), request.getCurrentPassword(), request.getNewPassword());
        return ResponseEntity.ok(ApiResponse.success("Password updated successfully.", "PASSWORD_UPDATED"));
    }
}
