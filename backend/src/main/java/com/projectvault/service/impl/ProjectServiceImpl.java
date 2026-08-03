package com.projectvault.service.impl;

import com.projectvault.dto.request.CreateProjectRequest;
import com.projectvault.dto.request.ProjectMemberRequest;
import com.projectvault.dto.request.ProjectStatusTransitionRequest;
import com.projectvault.dto.request.UpdateProjectRequest;
import com.projectvault.dto.response.PageResponse;
import com.projectvault.dto.response.ProjectDetailDto;
import com.projectvault.dto.response.ProjectSummaryDto;
import com.projectvault.entity.*;
import com.projectvault.exception.BadRequestException;
import com.projectvault.exception.ForbiddenException;
import com.projectvault.exception.ResourceNotFoundException;
import com.projectvault.mapper.ProjectMapper;
import com.projectvault.repository.DepartmentRepository;
import com.projectvault.repository.ProjectMemberRepository;
import com.projectvault.repository.ProjectRepository;
import com.projectvault.repository.UserRepository;
import com.projectvault.security.UserPrincipal;
import com.projectvault.service.ProjectService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
public class ProjectServiceImpl implements ProjectService {

    private final ProjectRepository projectRepository;
    private final ProjectMemberRepository projectMemberRepository;
    private final DepartmentRepository departmentRepository;
    private final UserRepository userRepository;
    private final ProjectMapper projectMapper;

    public ProjectServiceImpl(
            ProjectRepository projectRepository,
            ProjectMemberRepository projectMemberRepository,
            DepartmentRepository departmentRepository,
            UserRepository userRepository,
            ProjectMapper projectMapper) {
        this.projectRepository = projectRepository;
        this.projectMemberRepository = projectMemberRepository;
        this.departmentRepository = departmentRepository;
        this.userRepository = userRepository;
        this.projectMapper = projectMapper;
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<ProjectSummaryDto> getAllProjects(Long departmentId, ProjectStatus status, ProjectVisibility visibility, Pageable pageable, UserPrincipal currentUser) {
        Page<Project> page;

        // Public Visitor / Unauthenticated or Filtered View
        if (currentUser == null) {
            // Unauthenticated visitors can ONLY view APPROVED and PUBLIC projects
            page = projectRepository.findByStatusAndVisibility(ProjectStatus.APPROVED, ProjectVisibility.PUBLIC, pageable);
        } else if (departmentId != null) {
            page = projectRepository.findByDepartmentId(departmentId, pageable);
        } else {
            page = projectRepository.findAll(pageable);
        }

        Page<ProjectSummaryDto> dtoPage = page.map(projectMapper::toProjectSummaryDto);
        return PageResponse.fromPage(dtoPage);
    }

    @Override
    @Transactional(readOnly = true)
    public ProjectDetailDto getProjectById(Long id, UserPrincipal currentUser) {
        Project project = projectRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Project", "id", id));

        // Public Visitor Restriction Check
        if (currentUser == null) {
            if (project.getStatus() != ProjectStatus.APPROVED || project.getVisibility() != ProjectVisibility.PUBLIC) {
                throw new ForbiddenException("Public access is restricted to approved public projects.");
            }
        }

        List<ProjectMember> members = projectMemberRepository.findByProjectId(id);
        return projectMapper.toProjectDetailDto(project, members);
    }

    @Override
    @Transactional
    public ProjectDetailDto createProject(CreateProjectRequest request, UserPrincipal currentUser) {
        if (currentUser == null) {
            throw new ForbiddenException("Authentication required to create a project.");
        }

        User creator = userRepository.findById(currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", currentUser.getId()));

        Department department = departmentRepository.findById(request.getDepartmentId())
                .orElseThrow(() -> new ResourceNotFoundException("Department", "id", request.getDepartmentId()));

        Project project = new Project(
                request.getTitle(),
                request.getAbstractText(),
                request.getAcademicYear(),
                request.getSemester(),
                request.getProjectType(),
                request.getVisibility(),
                department,
                creator,
                request.getRepositoryUrl()
        );

        Project savedProject = projectRepository.save(project);

        // Add creator as Lead Developer member automatically
        ProjectMember leadMember = new ProjectMember(savedProject, creator, "Project Lead / Author");
        projectMemberRepository.save(leadMember);

        // Process additional team members if provided
        List<ProjectMember> members = new ArrayList<>();
        members.add(leadMember);

        if (request.getMembers() != null) {
            for (ProjectMemberRequest mr : request.getMembers()) {
                if (!mr.getUserId().equals(creator.getId())) {
                    User memberUser = userRepository.findById(mr.getUserId())
                            .orElseThrow(() -> new ResourceNotFoundException("User", "id", mr.getUserId()));
                    ProjectMember member = new ProjectMember(savedProject, memberUser, mr.getMemberRole());
                    members.add(projectMemberRepository.save(member));
                }
            }
        }

        return projectMapper.toProjectDetailDto(savedProject, members);
    }

    @Override
    @Transactional
    public ProjectDetailDto updateProject(Long id, UpdateProjectRequest request, UserPrincipal currentUser) {
        if (currentUser == null) {
            throw new ForbiddenException("Authentication required.");
        }

        Project project = projectRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Project", "id", id));

        // Edit boundary rule: Student can edit ONLY when DRAFT or REJECTED
        boolean isCreator = project.getCreatedBy().getId().equals(currentUser.getId());
        boolean isAdmin = currentUser.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));

        if (!isCreator && !isAdmin) {
            throw new ForbiddenException("You are not authorized to edit this project.");
        }

        if (isCreator && !isAdmin && project.getStatus() != ProjectStatus.DRAFT && project.getStatus() != ProjectStatus.REJECTED) {
            throw new BadRequestException("Projects can only be edited when in DRAFT or REJECTED status.");
        }

        if (request.getTitle() != null) project.setTitle(request.getTitle());
        if (request.getAbstractText() != null) project.setAbstractText(request.getAbstractText());
        if (request.getAcademicYear() != null) project.setAcademicYear(request.getAcademicYear());
        if (request.getSemester() != null) project.setSemester(request.getSemester());
        if (request.getProjectType() != null) project.setProjectType(request.getProjectType());
        if (request.getVisibility() != null) project.setVisibility(request.getVisibility());
        if (request.getRepositoryUrl() != null) project.setRepositoryUrl(request.getRepositoryUrl());

        Project updated = projectRepository.save(project);
        List<ProjectMember> members = projectMemberRepository.findByProjectId(id);

        return projectMapper.toProjectDetailDto(updated, members);
    }

    @Override
    @Transactional
    public ProjectDetailDto transitionProjectStatus(Long id, ProjectStatusTransitionRequest request, UserPrincipal currentUser) {
        if (currentUser == null) {
            throw new ForbiddenException("Authentication required.");
        }

        Project project = projectRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Project", "id", id));

        ProjectStatus currentStatus = project.getStatus();
        ProjectStatus targetStatus = request.getStatus();

        // Enforce Formally Permitted Lifecycle Transitions
        validateStatusTransition(currentStatus, targetStatus, currentUser, project);

        project.setStatus(targetStatus);
        Project updated = projectRepository.save(project);

        List<ProjectMember> members = projectMemberRepository.findByProjectId(id);
        return projectMapper.toProjectDetailDto(updated, members);
    }

    private void validateStatusTransition(ProjectStatus current, ProjectStatus target, UserPrincipal user, Project project) {
        boolean isAdmin = user.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        boolean isFaculty = user.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_FACULTY"));
        boolean isCreator = project.getCreatedBy().getId().equals(user.getId());

        if (current == target) {
            throw new BadRequestException("Project is already in status " + current);
        }

        // Permitted transitions:
        // DRAFT -> SUBMITTED (Student / Creator)
        // SUBMITTED -> UNDER_REVIEW (Faculty / Admin)
        // UNDER_REVIEW -> APPROVED (Faculty / Admin)
        // UNDER_REVIEW -> REJECTED (Faculty / Admin)
        // REJECTED -> DRAFT (Student / Creator)
        // APPROVED -> ARCHIVED (Faculty / Admin)

        if (current == ProjectStatus.DRAFT && target == ProjectStatus.SUBMITTED) {
            if (!isCreator && !isAdmin) {
                throw new ForbiddenException("Only the project author can submit a draft project.");
            }
        } else if (current == ProjectStatus.SUBMITTED && target == ProjectStatus.UNDER_REVIEW) {
            if (!isFaculty && !isAdmin) {
                throw new ForbiddenException("Only Faculty or Admin can move a project under review.");
            }
        } else if (current == ProjectStatus.UNDER_REVIEW && (target == ProjectStatus.APPROVED || target == ProjectStatus.REJECTED)) {
            if (!isFaculty && !isAdmin) {
                throw new ForbiddenException("Only Faculty or Admin can approve or reject projects.");
            }
        } else if (current == ProjectStatus.REJECTED && target == ProjectStatus.DRAFT) {
            if (!isCreator && !isAdmin) {
                throw new ForbiddenException("Only the project author can re-open a rejected project as draft.");
            }
        } else if (current == ProjectStatus.APPROVED && target == ProjectStatus.ARCHIVED) {
            if (!isFaculty && !isAdmin) {
                throw new ForbiddenException("Only Faculty or Admin can archive an approved project.");
            }
        } else {
            throw new BadRequestException(String.format("Invalid lifecycle state transition from '%s' to '%s'. Direct jumps are forbidden.", current, target));
        }
    }

    @Override
    @Transactional
    public void deleteProject(Long id, UserPrincipal currentUser) {
        if (currentUser == null) {
            throw new ForbiddenException("Authentication required.");
        }

        Project project = projectRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Project", "id", id));

        boolean isCreator = project.getCreatedBy().getId().equals(currentUser.getId());
        boolean isAdmin = currentUser.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));

        if (!isCreator && !isAdmin) {
            throw new ForbiddenException("Only project author or Admin can delete a project draft.");
        }

        if (!isAdmin && project.getStatus() != ProjectStatus.DRAFT) {
            throw new BadRequestException("Non-admin users can only delete project entries in DRAFT status.");
        }

        projectMemberRepository.deleteByProjectId(id);
        projectRepository.delete(project);
    }
}
