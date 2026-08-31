package com.projectvault.dto.request;

import com.projectvault.entity.ProjectVisibility;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;

import java.util.List;

public class CreateProjectRequest {

    @NotBlank(message = "Title is required")
    @Size(max = 255, message = "Title cannot exceed 255 characters")
    private String title;

    @NotBlank(message = "Abstract is required")
    private String abstractText;

    @NotBlank(message = "Academic year is required")
    @Pattern(regexp = "^\\d{4}-\\d{4}$", message = "Academic year must follow YYYY-YYYY format")
    private String academicYear;

    @NotNull(message = "Semester is required")
    @Min(value = 1, message = "Semester must be at least 1")
    @Max(value = 10, message = "Semester cannot exceed 10")
    private Integer semester;

    @NotBlank(message = "Project type is required")
    private String projectType;

    private ProjectVisibility visibility;

    @NotNull(message = "Department ID is required")
    private Long departmentId;

    private String repositoryUrl;

    @NotNull(message = "Faculty guide is required")
    private Long guideFacultyId;

    @Valid
    private List<ProjectMemberRequest> members;

    public CreateProjectRequest() {}

    public CreateProjectRequest(String title, String abstractText, String academicYear, Integer semester, String projectType, ProjectVisibility visibility, Long departmentId, String repositoryUrl, Long guideFacultyId, List<ProjectMemberRequest> members) {
        this.title = title;
        this.abstractText = abstractText;
        this.academicYear = academicYear;
        this.semester = semester;
        this.projectType = projectType;
        this.visibility = visibility;
        this.departmentId = departmentId;
        this.repositoryUrl = repositoryUrl;
        this.guideFacultyId = guideFacultyId;
        this.members = members;
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

    public String getRepositoryUrl() {
        return repositoryUrl;
    }

    public void setRepositoryUrl(String repositoryUrl) {
        this.repositoryUrl = repositoryUrl;
    }

    public Long getGuideFacultyId() {
        return guideFacultyId;
    }

    public void setGuideFacultyId(Long guideFacultyId) {
        this.guideFacultyId = guideFacultyId;
    }

    public List<ProjectMemberRequest> getMembers() {
        return members;
    }

    public void setMembers(List<ProjectMemberRequest> members) {
        this.members = members;
    }
}
