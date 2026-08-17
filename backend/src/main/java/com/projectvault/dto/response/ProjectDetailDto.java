package com.projectvault.dto.response;

import com.projectvault.entity.ProjectStatus;
import com.projectvault.entity.ProjectVisibility;

import java.time.LocalDateTime;
import java.util.List;

public class ProjectDetailDto {

    private Long id;
    private String title;
    private String abstractText;
    private String academicYear;
    private Integer semester;
    private String projectType;
    private ProjectStatus status;
    private ProjectVisibility visibility;
    private Long departmentId;
    private String departmentName;
    private Long createdByUserId;
    private String createdByUserName;
    private String repositoryUrl;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private List<ProjectMemberDto> members;
    private List<ProjectWorkflowHistoryDto> workflowHistory;
    private List<ProjectFileDto> files;

    public ProjectDetailDto() {}

    public ProjectDetailDto(Long id, String title, String abstractText, String academicYear, Integer semester, String projectType, ProjectStatus status, ProjectVisibility visibility, Long departmentId, String departmentName, Long createdByUserId, String createdByUserName, String repositoryUrl, LocalDateTime createdAt, LocalDateTime updatedAt, List<ProjectMemberDto> members) {
        this.id = id;
        this.title = title;
        this.abstractText = abstractText;
        this.academicYear = academicYear;
        this.semester = semester;
        this.projectType = projectType;
        this.status = status;
        this.visibility = visibility;
        this.departmentId = departmentId;
        this.departmentName = departmentName;
        this.createdByUserId = createdByUserId;
        this.createdByUserName = createdByUserName;
        this.repositoryUrl = repositoryUrl;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
        this.members = members;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getAbstractText() {
        return abstractText;
    }

    public void setAbstractText(String abstractText) {
        this.abstractText = abstractText;
    }

    public String getAcademicYear() {
        return academicYear;
    }

    public void setAcademicYear(String academicYear) {
        this.academicYear = academicYear;
    }

    public Integer getSemester() {
        return semester;
    }

    public void setSemester(Integer semester) {
        this.semester = semester;
    }

    public String getProjectType() {
        return projectType;
    }

    public void setProjectType(String projectType) {
        this.projectType = projectType;
    }

    public ProjectStatus getStatus() {
        return status;
    }

    public void setStatus(ProjectStatus status) {
        this.status = status;
    }

    public ProjectVisibility getVisibility() {
        return visibility;
    }

    public void setVisibility(ProjectVisibility visibility) {
        this.visibility = visibility;
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

    public Long getCreatedByUserId() {
        return createdByUserId;
    }

    public void setCreatedByUserId(Long createdByUserId) {
        this.createdByUserId = createdByUserId;
    }

    public String getCreatedByUserName() {
        return createdByUserName;
    }

    public void setCreatedByUserName(String createdByUserName) {
        this.createdByUserName = createdByUserName;
    }

    public String getRepositoryUrl() {
        return repositoryUrl;
    }

    public void setRepositoryUrl(String repositoryUrl) {
        this.repositoryUrl = repositoryUrl;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    public List<ProjectMemberDto> getMembers() {
        return members;
    }

    public void setMembers(List<ProjectMemberDto> members) {
        this.members = members;
    }

    public List<ProjectWorkflowHistoryDto> getWorkflowHistory() {
        return workflowHistory;
    }

    public void setWorkflowHistory(List<ProjectWorkflowHistoryDto> workflowHistory) {
        this.workflowHistory = workflowHistory;
    }

    public List<ProjectFileDto> getFiles() {
        return files;
    }

    public void setFiles(List<ProjectFileDto> files) {
        this.files = files;
    }
}
