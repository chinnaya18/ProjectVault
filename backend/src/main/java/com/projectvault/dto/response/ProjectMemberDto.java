package com.projectvault.dto.response;

public class ProjectMemberDto {

    private Long id;
    private Long userId;
    private String userEmail;
    private String userName;
    private String userRollNo;
    private String userRole;
    private String memberRole;

    public ProjectMemberDto() {}

    public ProjectMemberDto(Long id, Long userId, String userEmail, String userName, String userRollNo, String userRole, String memberRole) {
        this.id = id;
        this.userId = userId;
        this.userEmail = userEmail;
        this.userName = userName;
        this.userRollNo = userRollNo;
        this.userRole = userRole;
        this.memberRole = memberRole;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getUserEmail() {
        return userEmail;
    }

    public void setUserEmail(String userEmail) {
        this.userEmail = userEmail;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public String getUserRollNo() {
        return userRollNo;
    }

    public void setUserRollNo(String userRollNo) {
        this.userRollNo = userRollNo;
    }

    public String getUserRole() {
        return userRole;
    }

    public void setUserRole(String userRole) {
        this.userRole = userRole;
    }

    public String getMemberRole() {
        return memberRole;
    }

    public void setMemberRole(String memberRole) {
        this.memberRole = memberRole;
    }
}
