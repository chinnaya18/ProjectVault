package com.projectvault.mapper;

import com.projectvault.dto.response.UserSummaryDto;
import com.projectvault.entity.User;
import org.springframework.stereotype.Component;

@Component
public class UserMapper {

    public UserSummaryDto toUserSummaryDto(User user) {
        if (user == null) {
            return null;
        }

        Long deptId = user.getDepartment() != null ? user.getDepartment().getId() : null;
        String deptName = user.getDepartment() != null ? user.getDepartment().getName() : null;

        return new UserSummaryDto(
                user.getId(),
                user.getEmail(),
                user.getName(),
                user.getRollNo(),
                user.getRole(),
                user.getUserStatus(),
                deptId,
                deptName
        );
    }
}
