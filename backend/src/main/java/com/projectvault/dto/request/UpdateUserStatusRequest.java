package com.projectvault.dto.request;

import com.projectvault.entity.UserStatus;
import jakarta.validation.constraints.NotNull;

public class UpdateUserStatusRequest {

    @NotNull(message = "User status is required")
    private UserStatus userStatus;

    public UpdateUserStatusRequest() {}

    public UpdateUserStatusRequest(UserStatus userStatus) {
        this.userStatus = userStatus;
    }

    public UserStatus getUserStatus() {
        return userStatus;
    }

    public void setUserStatus(UserStatus userStatus) {
        this.userStatus = userStatus;
    }
}
