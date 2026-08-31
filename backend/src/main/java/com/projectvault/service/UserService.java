package com.projectvault.service;

import com.projectvault.dto.request.UpdateUserRoleRequest;
import com.projectvault.dto.request.UpdateUserStatusRequest;
import com.projectvault.dto.response.PageResponse;
import com.projectvault.dto.response.UserSummaryDto;
import com.projectvault.entity.Role;
import com.projectvault.entity.UserStatus;
import org.springframework.data.domain.Pageable;

public interface UserService {
    PageResponse<UserSummaryDto> getAllUsers(Long departmentId, Role role, UserStatus userStatus, Pageable pageable);
    java.util.List<UserSummaryDto> getFacultyMembers();
    java.util.List<UserSummaryDto> getStudents();
    UserSummaryDto getUserById(Long id);
    UserSummaryDto updateUserRole(Long id, UpdateUserRoleRequest request);
    UserSummaryDto updateUserStatus(Long id, UpdateUserStatusRequest request);
}
