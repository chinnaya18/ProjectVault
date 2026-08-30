package com.projectvault.dto.response;

import com.projectvault.entity.Role;
import com.projectvault.entity.UserStatus;

public class UserSummaryDto {

    private Long id;
    private String email;
    private String name;
    private String rollNo;
    private Role role;
    private UserStatus userStatus;
    private Long departmentId;
    private String departmentName;

    public UserSummaryDto() {}

    public UserSummaryDto(Long id, String email, String name, String rollNo, Role role, UserStatus userStatus, Long departmentId, String departmentName) {
        this.id = id;
        this.email = email;
        this.name = name;
        this.rollNo = rollNo;
        this.role = role;
        this.userStatus = userStatus;
        this.departmentId = departmentId;
        this.departmentName = departmentName;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getRollNo() {
        return rollNo;
    }

    public void setRollNo(String rollNo) {
        this.rollNo = rollNo;
    }

    public Role getRole() {
        return role;
    }

    public void setRole(Role role) {
        this.role = role;
    }

    public UserStatus getUserStatus() {
        return userStatus;
    }

    public void setUserStatus(UserStatus userStatus) {
        this.userStatus = userStatus;
    }

    public Long getDepartmentId() {
        return departmentId;
    }

    public void setDepartmentId(Long departmentId) {
        this.departmentId = departmentId;
    }

    public String getDepartmentName() {
        return departmentName;
    }

    public void setDepartmentName(String departmentName) {
        this.departmentName = departmentName;
    }
}
