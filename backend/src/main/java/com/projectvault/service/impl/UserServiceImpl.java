package com.projectvault.service.impl;

import com.projectvault.dto.request.CreateFacultyRequest;
import com.projectvault.dto.request.UpdateUserRoleRequest;
import com.projectvault.dto.request.UpdateUserStatusRequest;
import com.projectvault.dto.response.PageResponse;
import com.projectvault.dto.response.UserSummaryDto;
import com.projectvault.entity.Role;
import com.projectvault.entity.User;
import com.projectvault.entity.UserStatus;
import com.projectvault.exception.ResourceNotFoundException;
import com.projectvault.exception.BadRequestException;
import com.projectvault.mapper.UserMapper;
import com.projectvault.repository.UserRepository;
import com.projectvault.repository.DepartmentRepository;
import com.projectvault.service.UserService;
import com.projectvault.service.AuditLogService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final DepartmentRepository departmentRepository;
    private final PasswordEncoder passwordEncoder;
    private final UserMapper userMapper;
    private final AuditLogService auditLogService;

    public UserServiceImpl(
            UserRepository userRepository,
            DepartmentRepository departmentRepository,
            PasswordEncoder passwordEncoder,
            UserMapper userMapper,
            AuditLogService auditLogService) {
        this.userRepository = userRepository;
        this.departmentRepository = departmentRepository;
        this.passwordEncoder = passwordEncoder;
        this.userMapper = userMapper;
        this.auditLogService = auditLogService;
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<UserSummaryDto> getAllUsers(Long departmentId, Role role, UserStatus userStatus, Pageable pageable) {
        Page<User> page;
        if (departmentId != null) {
            page = userRepository.findByDepartmentId(departmentId, pageable);
        } else if (role != null) {
            page = userRepository.findByRole(role, pageable);
        } else if (userStatus != null) {
            page = userRepository.findByUserStatus(userStatus, pageable);
        } else {
            page = userRepository.findAll(pageable);
        }

        Page<UserSummaryDto> dtoPage = page.map(userMapper::toUserSummaryDto);
        return PageResponse.fromPage(dtoPage);
    }

    @Override
    @Transactional(readOnly = true)
    public UserSummaryDto getUserById(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", id));
        return userMapper.toUserSummaryDto(user);
    }

    @Override
    @Transactional
    public UserSummaryDto createFacultyUser(CreateFacultyRequest request) {
        String email = request.getEmail() != null ? request.getEmail().trim().toLowerCase() : "";
        if (!email.endsWith("@psgtech.ac.in")) {
            throw new BadRequestException("Faculty email must belong to the @psgtech.ac.in institutional domain.");
        }

        if (userRepository.existsByEmail(email)) {
            throw new BadRequestException("User email already exists in system: " + email);
        }

        com.projectvault.entity.Department department = departmentRepository.findById(request.getDepartmentId() != null ? request.getDepartmentId() : 1L)
                .orElseThrow(() -> new ResourceNotFoundException("Department", "id", request.getDepartmentId()));

        User user = new User(
                email,
                passwordEncoder.encode(request.getPassword() != null && !request.getPassword().isBlank() ? request.getPassword() : "Password@123"),
                request.getName(),
                request.getDesignation(),
                Role.FACULTY,
                department
        );

        User saved = userRepository.save(user);
        auditLogService.logEvent(saved.getId(), "FACULTY_ONBOARDED", "USER", saved.getId(), "Admin onboarded faculty staff: " + saved.getName() + " (" + saved.getEmail() + ")", null);
        return userMapper.toUserSummaryDto(saved);
    }

    @Override
    @Transactional
    public UserSummaryDto updateUserRole(Long id, UpdateUserRoleRequest request) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", id));

        Role oldRole = user.getRole();
        user.setRole(request.getRole());
        User updated = userRepository.save(user);

        auditLogService.logEvent(id, "USER_ROLE_UPDATED", "USER", id, "Role updated from " + oldRole + " to " + request.getRole(), null);
        return userMapper.toUserSummaryDto(updated);
    }

    @Override
    @Transactional
    public UserSummaryDto updateUserStatus(Long id, UpdateUserStatusRequest request) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", id));

        UserStatus oldStatus = user.getUserStatus();
        user.setUserStatus(request.getUserStatus());
        if (request.getUserStatus() == UserStatus.INACTIVE) {
            user.setActive(false);
        } else {
            user.setActive(true);
        }

        User updated = userRepository.save(user);
        auditLogService.logEvent(id, "USER_STATUS_UPDATED", "USER", id, "Status updated from " + oldStatus + " to " + request.getUserStatus() + " (Graduation Lifecycle)", null);
        return userMapper.toUserSummaryDto(updated);
    }
}
