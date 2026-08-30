package com.projectvault.mapper;

import com.projectvault.dto.response.ProjectDetailDto;
import com.projectvault.dto.response.ProjectMemberDto;
import com.projectvault.dto.response.ProjectSummaryDto;
import com.projectvault.entity.Project;
import com.projectvault.entity.ProjectMember;
import com.projectvault.entity.User;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.stream.Collectors;

@Component
public class ProjectMapper {

    public ProjectSummaryDto toProjectSummaryDto(Project project) {
        if (project == null) {
            return null;
        }

        Long deptId = project.getDepartment() != null ? project.getDepartment().getId() : null;
        String deptName = project.getDepartment() != null ? project.getDepartment().getName() : null;
        Long createdById = project.getCreatedBy() != null ? project.getCreatedBy().getId() : null;
        String createdByName = project.getCreatedBy() != null ? project.getCreatedBy().getName() : null;
        String createdByRollNo = project.getCreatedBy() != null ? project.getCreatedBy().getRollNo() : null;
        Long guideId = project.getGuideFaculty() != null ? project.getGuideFaculty().getId() : null;
        String guideName = project.getGuideFaculty() != null ? project.getGuideFaculty().getName() : null;

        ProjectSummaryDto dto = new ProjectSummaryDto(
                project.getId(),
                project.getTitle(),
                project.getAbstractText(),
                project.getAcademicYear(),
                project.getSemester(),
                project.getProjectType(),
                project.getStatus(),
                project.getVisibility(),
                deptId,
                deptName,
                createdById,
                createdByName,
                createdByRollNo,
                project.getCreatedAt()
        );
        dto.setGuideFacultyId(guideId);
        dto.setGuideFacultyName(guideName);
        return dto;
    }

    public ProjectMemberDto toProjectMemberDto(ProjectMember member) {
        if (member == null) {
            return null;
        }
        User user = member.getUser();
        Long userId = user != null ? user.getId() : null;
        String email = user != null ? user.getEmail() : null;
        String name = user != null ? user.getName() : null;
        String rollNo = user != null ? user.getRollNo() : null;
        String role = user != null && user.getRole() != null ? user.getRole().name() : null;

        return new ProjectMemberDto(
                member.getId(),
                userId,
                email,
                name,
                rollNo,
                role,
                member.getMemberRole()
        );
    }

    public ProjectDetailDto toProjectDetailDto(Project project, List<ProjectMember> members) {
        if (project == null) {
            return null;
        }

        Long deptId = project.getDepartment() != null ? project.getDepartment().getId() : null;
        String deptName = project.getDepartment() != null ? project.getDepartment().getName() : null;
        Long createdById = project.getCreatedBy() != null ? project.getCreatedBy().getId() : null;
        String createdByName = project.getCreatedBy() != null ? project.getCreatedBy().getName() : null;
        String createdByRollNo = project.getCreatedBy() != null ? project.getCreatedBy().getRollNo() : null;
        Long guideId = project.getGuideFaculty() != null ? project.getGuideFaculty().getId() : null;
        String guideName = project.getGuideFaculty() != null ? project.getGuideFaculty().getName() : null;

        List<ProjectMemberDto> memberDtos = members != null ?
                members.stream().map(this::toProjectMemberDto).collect(Collectors.toList()) : List.of();

        ProjectDetailDto dto = new ProjectDetailDto(
                project.getId(),
                project.getTitle(),
                project.getAbstractText(),
                project.getAcademicYear(),
                project.getSemester(),
                project.getProjectType(),
                project.getStatus(),
                project.getVisibility(),
                deptId,
                deptName,
                createdById,
                createdByName,
                createdByRollNo,
                project.getRepositoryUrl(),
                project.getCreatedAt(),
                project.getUpdatedAt(),
                memberDtos
        );
        dto.setGuideFacultyId(guideId);
        dto.setGuideFacultyName(guideName);
        return dto;
    }

    public com.projectvault.dto.response.ProjectWorkflowHistoryDto toProjectWorkflowHistoryDto(com.projectvault.entity.ProjectWorkflowHistory history) {
        if (history == null) return null;
        Long userId = history.getChangedBy() != null ? history.getChangedBy().getId() : null;
        String userName = history.getChangedBy() != null ? history.getChangedBy().getName() : "System";
        return new com.projectvault.dto.response.ProjectWorkflowHistoryDto(
                history.getId(),
                history.getFromStatus(),
                history.getToStatus(),
                userId,
                userName,
                history.getCreatedAt()
        );
    }

    public com.projectvault.dto.response.ProjectFileDto toProjectFileDto(com.projectvault.entity.ProjectFile file) {
        if (file == null) return null;
        return new com.projectvault.dto.response.ProjectFileDto(
                file.getId(),
                file.getFileName(),
                file.getFileType(),
                file.getFileSize(),
                file.getUploadedAt()
        );
    }
}
