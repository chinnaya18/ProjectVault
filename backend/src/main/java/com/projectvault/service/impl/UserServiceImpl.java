package com.projectvault.service.impl;

import com.projectvault.dto.request.UpdateUserRoleRequest;
import com.projectvault.dto.request.UpdateUserStatusRequest;
import com.projectvault.dto.response.PageResponse;
import com.projectvault.dto.response.UserSummaryDto;
import com.projectvault.entity.Role;
import com.projectvault.entity.User;
import com.projectvault.entity.UserStatus;
import com.projectvault.exception.ResourceNotFoundException;
import com.projectvault.mapper.UserMapper;
import com.projectvault.repository.UserRepository;
import com.projectvault.service.UserService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final UserMapper userMapper;
    private final com.projectvault.service.AuditLogService auditLogService;

    public UserServiceImpl(UserRepository userRepository, UserMapper userMapper, com.projectvault.service.AuditLogService auditLogService) {
        this.userRepository = userRepository;
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
