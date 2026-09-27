package com.projectvault.dto.response;

import com.projectvault.entity.ProjectStatus;
import com.projectvault.entity.ProjectVisibility;

import java.time.LocalDateTime;

public class ProjectSummaryDto {

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
    private String createdByRollNo;
    private Long guideFacultyId;
    private String guideFacultyName;
    private Double plagiarismScore;
    private Double duplicationScore;
    private String plagiarismReport;
    private String plagiarismStatus;
    private LocalDateTime createdAt;

    public ProjectSummaryDto() {}

    public ProjectSummaryDto(Long id, String title, String abstractText, String academicYear, Integer semester, String projectType, ProjectStatus status, ProjectVisibility visibility, Long departmentId, String departmentName, Long createdByUserId, String createdByUserName, String createdByRollNo, LocalDateTime createdAt) {
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
        this.createdByRollNo = createdByRollNo;
        this.createdAt = createdAt;
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

    public String getCreatedByRollNo() {
        return createdByRollNo;
    }

    public void setCreatedByRollNo(String createdByRollNo) {
        this.createdByRollNo = createdByRollNo;
    }

    public Long getGuideFacultyId() {
        return guideFacultyId;
    }

    public void setGuideFacultyId(Long guideFacultyId) {
        this.guideFacultyId = guideFacultyId;
    }

    public String getGuideFacultyName() {
        return guideFacultyName;
    }

    public void setGuideFacultyName(String guideFacultyName) {
        this.guideFacultyName = guideFacultyName;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public Double getPlagiarismScore() {
        return plagiarismScore;
    }

    public void setPlagiarismScore(Double plagiarismScore) {
        this.plagiarismScore = plagiarismScore;
    }

    public Double getDuplicationScore() {
        return duplicationScore;
    }

    public void setDuplicationScore(Double duplicationScore) {
        this.duplicationScore = duplicationScore;
    }

    public String getPlagiarismReport() {
        return plagiarismReport;
    }

    public void setPlagiarismReport(String plagiarismReport) {
        this.plagiarismReport = plagiarismReport;
    }

    public String getPlagiarismStatus() {
        return plagiarismStatus;
    }

    public void setPlagiarismStatus(String plagiarismStatus) {
        this.plagiarismStatus = plagiarismStatus;
    }
}
