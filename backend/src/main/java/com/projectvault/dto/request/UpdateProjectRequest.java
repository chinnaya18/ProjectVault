package com.projectvault.dto.request;

import com.projectvault.entity.ProjectVisibility;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import java.util.List;

public class UpdateProjectRequest {

    @Size(max = 255, message = "Title cannot exceed 255 characters")
    private String title;

    private String abstractText;

    @Pattern(regexp = "^\\d{4}-\\d{4}$", message = "Academic year must follow YYYY-YYYY format")
    private String academicYear;

    @Min(value = 1, message = "Semester must be at least 1")
    @Max(value = 10, message = "Semester cannot exceed 10")
    private Integer semester;

    private String projectType;

    private ProjectVisibility visibility;

    private String repositoryUrl;

    @Valid
    private List<ProjectMemberRequest> members;

    public UpdateProjectRequest() {}

    public UpdateProjectRequest(String title, String abstractText, String academicYear, Integer semester, String projectType, ProjectVisibility visibility, String repositoryUrl, List<ProjectMemberRequest> members) {
        this.title = title;
        this.abstractText = abstractText;
        this.academicYear = academicYear;
        this.semester = semester;
        this.projectType = projectType;
        this.visibility = visibility;
        this.repositoryUrl = repositoryUrl;
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

    public String getRepositoryUrl() {
        return repositoryUrl;
    }

    public void setRepositoryUrl(String repositoryUrl) {
        this.repositoryUrl = repositoryUrl;
    }

    public List<ProjectMemberRequest> getMembers() {
        return members;
    }

    public void setMembers(List<ProjectMemberRequest> members) {
        this.members = members;
    }
}
