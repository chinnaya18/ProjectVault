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
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtProvider jwtProvider;
    private final UserMapper userMapper;

    public AuthServiceImpl(
            UserRepository userRepository,
            DepartmentRepository departmentRepository,
            PasswordEncoder passwordEncoder,
            AuthenticationManager authenticationManager,
            JwtProvider jwtProvider,
            UserMapper userMapper) {
        this.userRepository = userRepository;
        this.departmentRepository = departmentRepository;
        this.passwordEncoder = passwordEncoder;
        this.authenticationManager = authenticationManager;
        this.jwtProvider = jwtProvider;
        this.userMapper = userMapper;
    }

    @Override
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new BadRequestException("Email is already registered: " + request.getEmail());
        }

        Department department = null;
        if (request.getDepartmentId() != null) {
            department = departmentRepository.findById(request.getDepartmentId())
                    .orElseThrow(() -> new ResourceNotFoundException("Department", "id", request.getDepartmentId()));
        }

        String rollNo = request.getRollNo();
        if (rollNo == null || rollNo.isBlank()) {
            if (request.getEmail() != null && request.getEmail().contains("@")) {
                rollNo = request.getEmail().split("@")[0].toUpperCase();
            }
        }

        User user = new User(
                request.getEmail(),
                passwordEncoder.encode(request.getPassword()),
                request.getName(),
                rollNo,
                Role.STUDENT,
                department
        );

        User savedUser = userRepository.save(user);

        String token = jwtProvider.generateTokenFromUser(savedUser.getId(), savedUser.getEmail());
        UserSummaryDto userSummary = userMapper.toUserSummaryDto(savedUser);

        return new AuthResponse(token, jwtProvider.getJwtExpirationMs(), userSummary);
    }

    @Override
    @Transactional(readOnly = true)
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
}
