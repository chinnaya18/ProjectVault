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
        String createdByName = project.getCreatedBy() != null ?
                project.getCreatedBy().getFirstName() + " " + project.getCreatedBy().getLastName() : null;

        return new ProjectSummaryDto(
                project.getId(),
                project.getTitle(),
                project.getAcademicYear(),
                project.getSemester(),
                project.getProjectType(),
                project.getStatus(),
                project.getVisibility(),
                deptId,
                deptName,
                createdById,
                createdByName,
                project.getCreatedAt()
        );
    }

    public ProjectMemberDto toProjectMemberDto(ProjectMember member) {
        if (member == null) {
            return null;
        }
        User user = member.getUser();
        Long userId = user != null ? user.getId() : null;
        String email = user != null ? user.getEmail() : null;
        String name = user != null ? user.getFirstName() + " " + user.getLastName() : null;

        return new ProjectMemberDto(
                member.getId(),
                userId,
                email,
                name,
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
        String createdByName = project.getCreatedBy() != null ?
                project.getCreatedBy().getFirstName() + " " + project.getCreatedBy().getLastName() : null;

        List<ProjectMemberDto> memberDtos = members != null ?
                members.stream().map(this::toProjectMemberDto).collect(Collectors.toList()) : List.of();

        return new ProjectDetailDto(
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
                project.getRepositoryUrl(),
                project.getCreatedAt(),
                project.getUpdatedAt(),
                memberDtos
        );
    }
}
