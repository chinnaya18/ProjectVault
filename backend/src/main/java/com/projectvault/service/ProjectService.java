package com.projectvault.service;

import com.projectvault.dto.request.CreateProjectRequest;
import com.projectvault.dto.request.ProjectStatusTransitionRequest;
import com.projectvault.dto.request.UpdateProjectRequest;
import com.projectvault.dto.response.PageResponse;
import com.projectvault.dto.response.ProjectDetailDto;
import com.projectvault.dto.response.ProjectSummaryDto;
import com.projectvault.entity.ProjectStatus;
import com.projectvault.entity.ProjectVisibility;
import com.projectvault.security.UserPrincipal;
import org.springframework.data.domain.Pageable;

public interface ProjectService {
    PageResponse<ProjectSummaryDto> getAllProjects(Long departmentId, ProjectStatus status, ProjectVisibility visibility, Pageable pageable, UserPrincipal currentUser);
    ProjectDetailDto getProjectById(Long id, UserPrincipal currentUser);
    ProjectDetailDto createProject(CreateProjectRequest request, UserPrincipal currentUser);
    ProjectDetailDto updateProject(Long id, UpdateProjectRequest request, UserPrincipal currentUser);
    ProjectDetailDto transitionProjectStatus(Long id, ProjectStatusTransitionRequest request, UserPrincipal currentUser);
    void deleteProject(Long id, UserPrincipal currentUser);
}
