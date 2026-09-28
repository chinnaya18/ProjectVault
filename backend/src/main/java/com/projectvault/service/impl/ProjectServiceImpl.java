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
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

@Service
public class ProjectServiceImpl implements ProjectService {

    private final ProjectRepository projectRepository;
    private final ProjectMemberRepository projectMemberRepository;
    private final DepartmentRepository departmentRepository;
    private final UserRepository userRepository;
    private final ProjectWorkflowHistoryRepository projectWorkflowHistoryRepository;
    private final ProjectFileRepository projectFileRepository;
    private final ProjectMapper projectMapper;
    private final com.projectvault.service.AiPlagiarismService aiPlagiarismService;
    private final com.projectvault.service.AuditLogService auditLogService;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient;

    @Value("${projectvault.storage.local-dir:d:/projectvault/storage/projects}")
    private String localStorageDir;

    @Value("${projectvault.ai-service.url:http://localhost:8000}")
    private String aiServiceUrl;

    public ProjectServiceImpl(
            ProjectRepository projectRepository,
            ProjectMemberRepository projectMemberRepository,
            DepartmentRepository departmentRepository,
            UserRepository userRepository,
            ProjectWorkflowHistoryRepository projectWorkflowHistoryRepository,
            ProjectFileRepository projectFileRepository,
            ProjectMapper projectMapper,
            com.projectvault.service.AiPlagiarismService aiPlagiarismService,
            com.projectvault.service.AuditLogService auditLogService,
            ObjectMapper objectMapper) {
        this.projectRepository = projectRepository;
        this.projectMemberRepository = projectMemberRepository;
        this.departmentRepository = departmentRepository;
        this.userRepository = userRepository;
        this.projectWorkflowHistoryRepository = projectWorkflowHistoryRepository;
        this.projectFileRepository = projectFileRepository;
        this.projectMapper = projectMapper;
        this.aiPlagiarismService = aiPlagiarismService;
        this.auditLogService = auditLogService;
        this.objectMapper = objectMapper;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(6))
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<ProjectSummaryDto> getAllProjects(Long departmentId, ProjectStatus status, ProjectVisibility visibility, Pageable pageable, UserPrincipal currentUser) {
        return getAllProjects(departmentId, status, visibility, null, pageable, currentUser);
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<ProjectSummaryDto> getAllProjects(Long departmentId, ProjectStatus status, ProjectVisibility visibility, String query, Pageable pageable, UserPrincipal currentUser) {
        String cleanQuery = (query != null && !query.trim().isEmpty()) ? query.trim() : null;
        Page<Project> page;

        if (currentUser == null) {
            page = projectRepository.findVisitorProjects(departmentId, cleanQuery, pageable);
        } else {
            String role = currentUser.getRole();
            if ("ADMIN".equalsIgnoreCase(role)) {
                page = projectRepository.findAdminProjects(departmentId, status, cleanQuery, pageable);
            } else if ("FACULTY".equalsIgnoreCase(role)) {
                page = projectRepository.findFacultyProjects(currentUser.getId(), departmentId, status, cleanQuery, pageable);
            } else {
                page = projectRepository.findStudentProjects(currentUser.getId(), departmentId, status, cleanQuery, pageable);
            }
        }

        Page<ProjectSummaryDto> dtoPage = page.map(projectMapper::toProjectSummaryDto);
        return PageResponse.fromPage(dtoPage);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ProjectSummaryDto> getProjectRecommendations(Long projectId, UserPrincipal currentUser) {
        if (!projectRepository.existsById(projectId)) {
            throw new ResourceNotFoundException("Project", "id", projectId);
        }

        // Attempt AI Microservice semantic similarity recommendation
        try {
            String targetUrl = aiServiceUrl + "/api/v1/ai/recommendations/" + projectId + "?limit=5";
            HttpRequest httpRequest = HttpRequest.newBuilder()
                    .uri(URI.create(targetUrl))
                    .timeout(Duration.ofSeconds(6))
                    .GET()
                    .build();

            HttpResponse<String> response = httpClient.send(httpRequest, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() == 200) {
                JsonNode root = objectMapper.readTree(response.body());
                JsonNode results = root.path("results");
                if (results.isArray() && results.size() > 0) {
                    List<ProjectSummaryDto> recList = new ArrayList<>();
                    for (JsonNode item : results) {
                        Long recId = item.path("id").asLong();
                        projectRepository.findById(recId).ifPresent(p -> {
                            ProjectSummaryDto dto = projectMapper.toProjectSummaryDto(p);
                            if (item.has("similarity_score")) {
                                dto.setDuplicationScore(item.path("similarity_score").asDouble());
                            }
                            recList.add(dto);
                        });
                    }
                    if (!recList.isEmpty()) {
                        return recList;
                    }
                }
            }
        } catch (Exception e) {
            // Log and use relational fallback
        }

        // Fallback: Top 5 approved public projects excluding current
        List<Project> fallbacks = projectRepository.findTop5ByStatusAndVisibilityAndIdNotOrderByCreatedAtDesc(
                ProjectStatus.APPROVED, ProjectVisibility.PUBLIC, projectId);
        return fallbacks.stream()
                .map(projectMapper::toProjectSummaryDto)
                .collect(Collectors.toList());
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

        if (request.getGuideFacultyId() != null) {
            User guide = userRepository.findById(request.getGuideFacultyId()).orElse(null);
            project.setGuideFaculty(guide);
        }

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
                if (!mr.getUserId().equals(creator.getId())) {
                    User memberUser = userRepository.findById(mr.getUserId())
                            .orElseThrow(() -> new ResourceNotFoundException("User", "id", mr.getUserId()));
                    ProjectMember member = new ProjectMember(savedProject, memberUser, mr.getMemberRole());
                    members.add(projectMemberRepository.save(member));
                }
            }
        }

        ProjectDetailDto dto = projectMapper.toProjectDetailDto(savedProject, members);
        dto.setWorkflowHistory(List.of(projectMapper.toProjectWorkflowHistoryDto(history)));
        auditLogService.logEvent(creator.getId(), "PROJECT_CREATED", "PROJECT", savedProject.getId(), "Created project draft: '" + savedProject.getTitle() + "'", null);

        // Pre-emptive duplication check right at initial draft creation stage
        try {
            java.util.concurrent.CompletableFuture.runAsync(() -> {
                try {
                    aiPlagiarismService.evaluateProjectPlagiarism(savedProject);
                } catch (Exception ignored) {}
            });
        } catch (Exception ignored) {}

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
        ProjectWorkflowHistory history = new ProjectWorkflowHistory(updated, currentStatus, targetStatus, actor, request.getFeedback());
        projectWorkflowHistoryRepository.save(history);

        // Automatically trigger AI Plagiarism & Duplication analysis upon submission
        if (currentStatus == ProjectStatus.DRAFT && targetStatus == ProjectStatus.SUBMITTED) {
            try {
                aiPlagiarismService.evaluateProjectPlagiarism(updated);
            } catch (Exception ex) {
                // Ensure lifecycle state update succeeds even if external AI call encounters issue
            }
        }

        // Automatically trigger AI vector embedding generation upon approval for instant semantic search
        if (targetStatus == ProjectStatus.APPROVED) {
            try {
                aiPlagiarismService.triggerProjectEmbeddingSync(updated.getId());
            } catch (Exception ex) {
                // Non-blocking: Ensure approval succeeds even if external AI call encounters issue
            }
        }

        List<ProjectMember> members = projectMemberRepository.findByProjectId(id);
        ProjectDetailDto dto = projectMapper.toProjectDetailDto(updated, members);

        List<ProjectWorkflowHistory> histories = projectWorkflowHistoryRepository.findByProjectIdOrderByCreatedAtAsc(id);
        dto.setWorkflowHistory(histories.stream().map(projectMapper::toProjectWorkflowHistoryDto).collect(Collectors.toList()));

        List<ProjectFile> files = projectFileRepository.findByProjectId(id);
        dto.setFiles(files.stream().map(projectMapper::toProjectFileDto).collect(Collectors.toList()));

        String feedbackInfo = request.getFeedback() != null && !request.getFeedback().isBlank() ? " | Feedback: " + request.getFeedback() : "";
        auditLogService.logEvent(actor.getId(), "PROJECT_STATUS_TRANSITION", "PROJECT", updated.getId(),
                "Status transitioned from " + currentStatus + " to " + targetStatus + feedbackInfo, null);

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

        projectWorkflowHistoryRepository.deleteByProjectId(id);
        projectFileRepository.deleteByProjectId(id);
        projectMemberRepository.deleteByProjectId(id);
        projectRepository.delete(project);

        auditLogService.logEvent(currentUser.getId(), "PROJECT_DELETED", "PROJECT", id, "Project entry #" + id + " was deleted", null);
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

            ProjectFile projectFile = new ProjectFile(
                    project,
                    file.getOriginalFilename(),
                    file.getContentType() != null ? file.getContentType() : "application/octet-stream",
                    filePath.toString(),
                    file.getSize()
            );

            ProjectFile savedFile = projectFileRepository.save(projectFile);

            auditLogService.logEvent(currentUser.getId(), "PROJECT_FILE_UPLOADED", "PROJECT_FILE", savedFile.getId(),
                    "Uploaded file '" + savedFile.getFileName() + "' (" + (savedFile.getFileSize() / 1024) + " KB) for project #" + projectId, null);

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

        try {
            Path filePath = Paths.get(projectFile.getFilePath());
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
            Path path = Paths.get(projectFile.getFilePath());
            Files.deleteIfExists(path);
        } catch (IOException e) {
            // Log file deletion issue but proceed to remove DB entry
        }

        projectFileRepository.delete(projectFile);

        auditLogService.logEvent(currentUser.getId(), "PROJECT_FILE_DELETED", "PROJECT_FILE", fileId,
                "Deleted file '" + projectFile.getFileName() + "' from project #" + projectId, null);
    }

    @Override
    @Transactional
    public ProjectDetailDto triggerPlagiarismCheck(Long id, UserPrincipal currentUser) {
        if (currentUser == null) {
            throw new ForbiddenException("Authentication required.");
        }

        Project project = projectRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Project", "id", id));

        boolean isAdmin = currentUser.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        boolean isFaculty = currentUser.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_FACULTY"));
        boolean isCreator = project.getCreatedBy() != null && project.getCreatedBy().getId().equals(currentUser.getId());

        if (!isAdmin && !isFaculty && !isCreator) {
            throw new ForbiddenException("Access denied: You do not have permission to run plagiarism evaluation on this project.");
        }

        aiPlagiarismService.evaluateProjectPlagiarism(project);

        return getProjectById(id, currentUser);
    }
}
