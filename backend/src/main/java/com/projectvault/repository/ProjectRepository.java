package com.projectvault.repository;

import com.projectvault.entity.Project;
import com.projectvault.entity.ProjectStatus;
import com.projectvault.entity.ProjectVisibility;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface ProjectRepository extends JpaRepository<Project, Long>, JpaSpecificationExecutor<Project> {
    Page<Project> findByStatusAndVisibility(ProjectStatus status, ProjectVisibility visibility, Pageable pageable);
    Page<Project> findByDepartmentId(Long departmentId, Pageable pageable);
    Page<Project> findByCreatedById(Long createdByUserId, Pageable pageable);

    @Query("SELECT p FROM Project p WHERE p.status = com.projectvault.entity.ProjectStatus.APPROVED AND p.visibility = com.projectvault.entity.ProjectVisibility.PUBLIC " +
           "AND (:departmentId IS NULL OR p.department.id = :departmentId)")
    Page<Project> findVisitorProjects(@Param("departmentId") Long departmentId, Pageable pageable);

    @Query("SELECT DISTINCT p FROM Project p WHERE " +
           "((p.status = com.projectvault.entity.ProjectStatus.APPROVED AND p.visibility = com.projectvault.entity.ProjectVisibility.PUBLIC) " +
           " OR p.createdBy.id = :studentId " +
           " OR EXISTS (SELECT m FROM ProjectMember m WHERE m.project = p AND m.user.id = :studentId)) " +
           "AND (:departmentId IS NULL OR p.department.id = :departmentId) " +
           "AND (:status IS NULL OR p.status = :status)")
    Page<Project> findStudentProjects(@Param("studentId") Long studentId, @Param("departmentId") Long departmentId, @Param("status") ProjectStatus status, Pageable pageable);

    @Query("SELECT DISTINCT p FROM Project p WHERE " +
           "((p.status = com.projectvault.entity.ProjectStatus.APPROVED AND p.visibility = com.projectvault.entity.ProjectVisibility.PUBLIC) " +
           " OR (p.guideFaculty IS NOT NULL AND p.guideFaculty.id = :facultyId) " +
           " OR p.createdBy.id = :facultyId) " +
           "AND (:departmentId IS NULL OR p.department.id = :departmentId) " +
           "AND (:status IS NULL OR p.status = :status)")
    Page<Project> findFacultyProjects(@Param("facultyId") Long facultyId, @Param("departmentId") Long departmentId, @Param("status") ProjectStatus status, Pageable pageable);

    @Query("SELECT p FROM Project p WHERE " +
           "(:departmentId IS NULL OR p.department.id = :departmentId) " +
           "AND (:status IS NULL OR p.status = :status)")
    Page<Project> findAdminProjects(@Param("departmentId") Long departmentId, @Param("status") ProjectStatus status, Pageable pageable);
}
