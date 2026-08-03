package com.projectvault.repository;

import com.projectvault.entity.Project;
import com.projectvault.entity.ProjectStatus;
import com.projectvault.entity.ProjectVisibility;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

@Repository
public interface ProjectRepository extends JpaRepository<Project, Long>, JpaSpecificationExecutor<Project> {
    Page<Project> findByStatusAndVisibility(ProjectStatus status, ProjectVisibility visibility, Pageable pageable);
    Page<Project> findByDepartmentId(Long departmentId, Pageable pageable);
    Page<Project> findByCreatedById(Long createdByUserId, Pageable pageable);
}
