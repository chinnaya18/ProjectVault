package com.projectvault.service.impl;

import com.projectvault.dto.request.CreateProjectRequest;
import com.projectvault.dto.request.ProjectMemberRequest;
import com.projectvault.dto.request.ProjectStatusTransitionRequest;
import com.projectvault.dto.request.UpdateProjectRequest;
import com.projectvault.dto.response.*;
import com.projectvault.entity.*;
import com.projectvault.exception.BadRequestException;
import com.projectvault.exception.ForbiddenException;
import com.projectvault.exception.ResourceNotFoundException;
import com.projectvault.mapper.ProjectMapper;
import com.projectvault.repository.*;
import com.projectvault.security.UserPrincipal;
import com.projectvault.service.ProjectService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class ProjectServiceImpl implements ProjectService {

    private final ProjectRepository projectRepository;
    private final ProjectMemberRepository projectMemberRepository;
    private final DepartmentRepository departmentRepository;
    private final UserRepository userRepository;
    private final ProjectWorkflowHistoryRepository projectWorkflowHistoryRepository;
    private final ProjectFileRepository projectFileRepository;
    private final ProjectMapper projectMapper;

    @Value("${projectvault.storage.local-dir:d:/projectvault/storage/projects}")
    private String localStorageDir;

    public ProjectServiceImpl(
            ProjectRepository projectRepository,
            ProjectMemberRepository projectMemberRepository,
            DepartmentRepository departmentRepository,
            UserRepository userRepository,
            ProjectWorkflowHistoryRepository projectWorkflowHistoryRepository,
            ProjectFileRepository projectFileRepository,
            ProjectMapper projectMapper) {
        this.projectRepository = projectRepository;
        this.projectMemberRepository = projectMemberRepository;
        this.departmentRepository = departmentRepository;
        this.userRepository = userRepository;
        this.projectWorkflowHistoryRepository = projectWorkflowHistoryRepository;
        this.projectFileRepository = projectFileRepository;
        this.projectMapper = projectMapper;
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<ProjectSummaryDto> getAllProjects(Long departmentId, ProjectStatus status, ProjectVisibility visibility, Pageable pageable, UserPrincipal currentUser) {
        Page<Project> page;

        if (currentUser == null) {
            page = projectRepository.findVisitorProjects(departmentId, pageable);
        } else {
            String role = currentUser.getRole();
            if ("ADMIN".equalsIgnoreCase(role)) {
                page = projectRepository.findAdminProjects(departmentId, status, pageable);
            } else if ("FACULTY".equalsIgnoreCase(role)) {
                page = projectRepository.findFacultyProjects(currentUser.getId(), departmentId, status, pageable);
            } else {
                page = projectRepository.findStudentProjects(currentUser.getId(), departmentId, status, pageable);
            }
        }

        Page<ProjectSummaryDto> dtoPage = page.map(projectMapper::toProjectSummaryDto);
        return PageResponse.fromPage(dtoPage);
    }

    @Override
    @Transactional(readOnly = true)
    public ProjectDetailDto getProjectById(Long id, UserPrincipal currentUser) {
        Project project = projectRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Project", "id", id));

        // Enforce strict data privacy and abstraction
        if (project.getStatus() != ProjectStatus.APPROVED || project.getVisibility() != ProjectVisibility.PUBLIC) {
            if (currentUser == null) {
                throw new ForbiddenException("Public access is restricted to approved public projects.");
            }

            String role = currentUser.getRole();
            if (!"ADMIN".equalsIgnoreCase(role)) {
                boolean isCreator = project.getCreatedBy() != null && project.getCreatedBy().getId().equals(currentUser.getId());
                boolean isGuide = project.getGuideFaculty() != null && project.getGuideFaculty().getId().equals(currentUser.getId());
                boolean isMember = projectMemberRepository.findByProjectId(id).stream()
                        .anyMatch(m -> m.getUser() != null && m.getUser().getId().equals(currentUser.getId()));

                if (!isCreator && !isGuide && !isMember) {
                    throw new ForbiddenException("Access denied: You do not have permission to view this non-approved project.");
                }
            }
        }

        List<ProjectMember> members = projectMemberRepository.findByProjectId(id);
        ProjectDetailDto dto = projectMapper.toProjectDetailDto(project, members);

        // Fetch DB Workflow History
        List<ProjectWorkflowHistory> histories = projectWorkflowHistoryRepository.findByProjectIdOrderByCreatedAtAsc(id);
        List<ProjectWorkflowHistoryDto> historyDtos = histories.stream()
                .map(projectMapper::toProjectWorkflowHistoryDto)
                .collect(Collectors.toList());
        dto.setWorkflowHistory(historyDtos);

        // Fetch DB Files
        List<ProjectFile> files = projectFileRepository.findByProjectId(id);
        List<ProjectFileDto> fileDtos = files.stream()
                .map(projectMapper::toProjectFileDto)
                .collect(Collectors.toList());
        dto.setFiles(fileDtos);

        return dto;
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

        if (request.getGuideFacultyId() == null) {
            throw new BadRequestException("A designated Faculty Guide is required for the project.");
        }

        User guide = userRepository.findById(request.getGuideFacultyId())
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", request.getGuideFacultyId()));
        project.setGuideFaculty(guide);

        Project savedProject = projectRepository.save(project);

        // Add creator as Lead Developer member automatically
        ProjectMember leadMember = new ProjectMember(savedProject, creator, "Project Lead / Author");
        projectMemberRepository.save(leadMember);

        // Record initial creation in DB Workflow History
        ProjectWorkflowHistory history = new ProjectWorkflowHistory(savedProject, ProjectStatus.DRAFT, ProjectStatus.DRAFT, creator);
        projectWorkflowHistoryRepository.save(history);

        List<ProjectMember> members = new ArrayList<>();
        members.add(leadMember);

        if (request.getMembers() != null) {
            for (ProjectMemberRequest mr : request.getMembers()) {
                User memberUser = null;
                if (mr.getUserId() != null && mr.getUserId() > 0 && !mr.getUserId().equals(creator.getId())) {
                    memberUser = userRepository.findById(mr.getUserId()).orElse(null);
                }
                if (memberUser == null && mr.getEmail() != null && !mr.getEmail().trim().isEmpty() && !mr.getEmail().equalsIgnoreCase(creator.getEmail())) {
                    memberUser = userRepository.findByEmail(mr.getEmail().trim()).orElse(null);
                }
                if (memberUser != null && !memberUser.getId().equals(creator.getId())) {
                    final Long uid = memberUser.getId();
                    if (members.stream().noneMatch(m -> m.getUser() != null && m.getUser().getId().equals(uid))) {
                        String role = (mr.getMemberRole() != null && !mr.getMemberRole().isBlank()) ? mr.getMemberRole() : "Team Member";
                        ProjectMember member = new ProjectMember(savedProject, memberUser, role);
                        members.add(projectMemberRepository.save(member));
                    }
                }
            }
        }

        ProjectDetailDto dto = projectMapper.toProjectDetailDto(savedProject, members);
        dto.setWorkflowHistory(List.of(projectMapper.toProjectWorkflowHistoryDto(history)));
        dto.setFiles(List.of());
        return dto;
    }

    @Override
    @Transactional
    public ProjectDetailDto updateProject(Long id, UpdateProjectRequest request, UserPrincipal currentUser) {
        if (currentUser == null) {
            throw new ForbiddenException("Authentication required.");
        }

        Project project = projectRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Project", "id", id));

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
        if (request.getGuideFacultyId() != null) {
            User guide = userRepository.findById(request.getGuideFacultyId())
                    .orElseThrow(() -> new ResourceNotFoundException("User", "id", request.getGuideFacultyId()));
            project.setGuideFaculty(guide);
        }

        Project updated = projectRepository.save(project);
        List<ProjectMember> members = projectMemberRepository.findByProjectId(id);

        ProjectDetailDto dto = projectMapper.toProjectDetailDto(updated, members);

        List<ProjectWorkflowHistory> histories = projectWorkflowHistoryRepository.findByProjectIdOrderByCreatedAtAsc(id);
        dto.setWorkflowHistory(histories.stream().map(projectMapper::toProjectWorkflowHistoryDto).collect(Collectors.toList()));

        List<ProjectFile> files = projectFileRepository.findByProjectId(id);
        dto.setFiles(files.stream().map(projectMapper::toProjectFileDto).collect(Collectors.toList()));

        return dto;
    }

    @Override
    @Transactional
    public ProjectDetailDto transitionProjectStatus(Long id, ProjectStatusTransitionRequest request, UserPrincipal currentUser) {
        if (currentUser == null) {
            throw new ForbiddenException("Authentication required.");
        }

        Project project = projectRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Project", "id", id));

        User actor = userRepository.findById(currentUser.getId())
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", currentUser.getId()));

        ProjectStatus currentStatus = project.getStatus();
        ProjectStatus targetStatus = request.getStatus();

        validateStatusTransition(currentStatus, targetStatus, currentUser, project);

        project.setStatus(targetStatus);
        Project updated = projectRepository.save(project);

        // Record Workflow History in DB
        ProjectWorkflowHistory history = new ProjectWorkflowHistory(updated, currentStatus, targetStatus, actor);
        projectWorkflowHistoryRepository.save(history);

        List<ProjectMember> members = projectMemberRepository.findByProjectId(id);
        ProjectDetailDto dto = projectMapper.toProjectDetailDto(updated, members);

        List<ProjectWorkflowHistory> histories = projectWorkflowHistoryRepository.findByProjectIdOrderByCreatedAtAsc(id);
        dto.setWorkflowHistory(histories.stream().map(projectMapper::toProjectWorkflowHistoryDto).collect(Collectors.toList()));

        List<ProjectFile> files = projectFileRepository.findByProjectId(id);
        dto.setFiles(files.stream().map(projectMapper::toProjectFileDto).collect(Collectors.toList()));

        return dto;
    }

    private void validateStatusTransition(ProjectStatus current, ProjectStatus target, UserPrincipal user, Project project) {
        boolean isAdmin = user.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        boolean isFaculty = user.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_FACULTY"));
        boolean isCreator = project.getCreatedBy().getId().equals(user.getId());

        if (current == target) {
            throw new BadRequestException("Project is already in status " + current);
        }

        if (current == ProjectStatus.DRAFT && target == ProjectStatus.SUBMITTED) {
            if (!isCreator && !isAdmin) {
                throw new ForbiddenException("Only the project author can submit a draft project.");
            }
            if (project.getGuideFaculty() == null) {
                throw new BadRequestException("Cannot submit draft for review: A designated Faculty Guide must be selected.");
            }
            // Mandatory Document / Repository URL check before draft submission
            boolean hasFiles = !projectFileRepository.findByProjectId(project.getId()).isEmpty();
            boolean hasRepoUrl = project.getRepositoryUrl() != null && !project.getRepositoryUrl().trim().isEmpty();
            if (!hasFiles && !hasRepoUrl) {
                throw new BadRequestException("Cannot submit draft for review: At least one project document attachment or repository URL is mandatory before submission.");
            }
            if (project.getTitle() == null || project.getTitle().trim().isEmpty()) {
                throw new BadRequestException("Cannot submit draft for review: Project Title is required.");
            }
            if (project.getAbstractText() == null || project.getAbstractText().trim().isEmpty()) {
                throw new BadRequestException("Cannot submit draft for review: Abstract summary is required.");
            }
        } else if (current == ProjectStatus.SUBMITTED && target == ProjectStatus.UNDER_REVIEW) {
            if (!isFaculty && !isAdmin) {
                throw new ForbiddenException("Only Faculty or Admin can move a project under review.");
            }
            if (isFaculty && !isAdmin && project.getGuideFaculty() != null && !project.getGuideFaculty().getId().equals(user.getId())) {
                throw new ForbiddenException("Only the designated Faculty Guide or Admin can evaluate this project submission.");
            }
        } else if (current == ProjectStatus.UNDER_REVIEW && (target == ProjectStatus.APPROVED || target == ProjectStatus.REJECTED)) {
            if (!isFaculty && !isAdmin) {
                throw new ForbiddenException("Only Faculty or Admin can approve or reject projects.");
            }
            if (isFaculty && !isAdmin && project.getGuideFaculty() != null && !project.getGuideFaculty().getId().equals(user.getId())) {
                throw new ForbiddenException("Only the designated Faculty Guide or Admin can evaluate this project submission.");
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

        List<ProjectFile> files = projectFileRepository.findByProjectId(id);
        for (ProjectFile f : files) {
            try {
                Path path = Paths.get(f.getStoragePath());
                Files.deleteIfExists(path);
            } catch (IOException ignored) {}
        }
        projectWorkflowHistoryRepository.deleteByProjectId(id);
        projectFileRepository.deleteByProjectId(id);
        projectMemberRepository.deleteByProjectId(id);
        projectRepository.delete(project);
    }

    @Override
    @Transactional
    public ProjectFileDto uploadProjectFile(Long projectId, MultipartFile file, UserPrincipal currentUser) {
        if (currentUser == null) {
            throw new ForbiddenException("Authentication required.");
        }

        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project", "id", projectId));

        boolean isCreator = project.getCreatedBy().getId().equals(currentUser.getId());
        boolean isAdmin = currentUser.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));

        if (!isCreator && !isAdmin) {
            throw new ForbiddenException("Only project creator can upload documents.");
        }

        // Lock File Upload after Submission Rule: Uploads allowed ONLY in DRAFT status!
        if (project.getStatus() != ProjectStatus.DRAFT && !isAdmin) {
            throw new BadRequestException("Documents can only be uploaded while the project is in DRAFT status. Uploads are locked after submission.");
        }

        try {
            Path targetDir = Paths.get(localStorageDir, projectId.toString());
            Files.createDirectories(targetDir);

            String cleanFileName = System.currentTimeMillis() + "_" + file.getOriginalFilename();
            Path filePath = targetDir.resolve(cleanFileName);

            Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

            User uploader = userRepository.findById(currentUser.getId())
                    .orElseThrow(() -> new ResourceNotFoundException("User", "id", currentUser.getId()));

            ProjectFile projectFile = new ProjectFile(
                    project,
                    file.getOriginalFilename(),
                    file.getContentType() != null ? file.getContentType() : "application/octet-stream",
                    filePath.toString(),
                    file.getSize(),
                    "LOCAL",
                    uploader
            );

            ProjectFile savedFile = projectFileRepository.save(projectFile);
            return projectMapper.toProjectFileDto(savedFile);

        } catch (IOException e) {
            throw new BadRequestException("Could not store file. Error: " + e.getMessage());
        }
    }

    @Override
    @Transactional(readOnly = true)
    public Resource getProjectFileResource(Long projectId, Long fileId, UserPrincipal currentUser) {
        ProjectFile projectFile = projectFileRepository.findById(fileId)
                .orElseThrow(() -> new ResourceNotFoundException("ProjectFile", "id", fileId));

        if (!projectFile.getProject().getId().equals(projectId)) {
            throw new BadRequestException("File does not belong to specified project.");
        }

        Project project = projectFile.getProject();
        if (project.getStatus() != ProjectStatus.APPROVED || project.getVisibility() != ProjectVisibility.PUBLIC) {
            if (currentUser == null) {
                throw new ForbiddenException("Authentication required to download attachments of non-approved projects.");
            }
            boolean isCreator = project.getCreatedBy() != null && project.getCreatedBy().getId().equals(currentUser.getId());
            boolean isAdmin = currentUser.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
            boolean isGuide = project.getGuideFaculty() != null && project.getGuideFaculty().getId().equals(currentUser.getId());
            boolean isMember = projectMemberRepository.findByProjectId(projectId).stream()
                    .anyMatch(m -> m.getUser() != null && m.getUser().getId().equals(currentUser.getId()));
            if (!isCreator && !isAdmin && !isGuide && !isMember) {
                throw new ForbiddenException("Access denied: You do not have permission to download this attachment.");
            }
        }

        try {
            Path filePath = Paths.get(projectFile.getStoragePath());
            Resource resource = new UrlResource(filePath.toUri());

            if (resource.exists() || resource.isReadable()) {
                return resource;
            } else {
                throw new ResourceNotFoundException("File", "id", fileId);
            }
        } catch (MalformedURLException e) {
            throw new BadRequestException("File path is invalid.");
        }
    }

    @Override
    @Transactional
    public void deleteProjectFile(Long projectId, Long fileId, UserPrincipal currentUser) {
        if (currentUser == null) {
            throw new ForbiddenException("Authentication required.");
        }

        ProjectFile projectFile = projectFileRepository.findById(fileId)
                .orElseThrow(() -> new ResourceNotFoundException("ProjectFile", "id", fileId));

        Project project = projectFile.getProject();
        if (!project.getId().equals(projectId)) {
            throw new BadRequestException("File does not belong to specified project.");
        }

        boolean isCreator = project.getCreatedBy().getId().equals(currentUser.getId());
        boolean isAdmin = currentUser.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));

        if (!isCreator && !isAdmin) {
            throw new ForbiddenException("Not authorized to delete this file.");
        }

        if (project.getStatus() != ProjectStatus.DRAFT && !isAdmin) {
            throw new BadRequestException("Files can only be deleted while the project is in DRAFT status.");
        }

        try {
            Path path = Paths.get(projectFile.getStoragePath());
            Files.deleteIfExists(path);
        } catch (IOException e) {
            // Log file deletion issue but proceed to remove DB entry
        }

        projectFileRepository.delete(projectFile);
    }
}
