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
           "AND (:departmentId IS NULL OR p.department.id = :departmentId) " +
           "AND (:query IS NULL OR LOWER(p.title) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(p.abstractText) LIKE LOWER(CONCAT('%', :query, '%')))")
    Page<Project> findVisitorProjects(@Param("departmentId") Long departmentId, @Param("query") String query, Pageable pageable);

    @Query("SELECT DISTINCT p FROM Project p WHERE " +
           "((p.status = com.projectvault.entity.ProjectStatus.APPROVED AND p.visibility = com.projectvault.entity.ProjectVisibility.PUBLIC) " +
           " OR p.createdBy.id = :studentId " +
           " OR EXISTS (SELECT m FROM ProjectMember m WHERE m.project = p AND m.user.id = :studentId)) " +
           "AND (:departmentId IS NULL OR p.department.id = :departmentId) " +
           "AND (:status IS NULL OR p.status = :status) " +
           "AND (:query IS NULL OR LOWER(p.title) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(p.abstractText) LIKE LOWER(CONCAT('%', :query, '%')))")
    Page<Project> findStudentProjects(@Param("studentId") Long studentId, @Param("departmentId") Long departmentId, @Param("status") ProjectStatus status, @Param("query") String query, Pageable pageable);

    @Query("SELECT DISTINCT p FROM Project p WHERE " +
           "((p.status = com.projectvault.entity.ProjectStatus.APPROVED AND p.visibility = com.projectvault.entity.ProjectVisibility.PUBLIC) " +
           " OR (p.guideFaculty IS NOT NULL AND p.guideFaculty.id = :facultyId) " +
           " OR p.createdBy.id = :facultyId) " +
           "AND (:departmentId IS NULL OR p.department.id = :departmentId) " +
           "AND (:status IS NULL OR p.status = :status) " +
           "AND (:query IS NULL OR LOWER(p.title) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(p.abstractText) LIKE LOWER(CONCAT('%', :query, '%')))")
    Page<Project> findFacultyProjects(@Param("facultyId") Long facultyId, @Param("departmentId") Long departmentId, @Param("status") ProjectStatus status, @Param("query") String query, Pageable pageable);

    @Query("SELECT p FROM Project p WHERE " +
           "(:departmentId IS NULL OR p.department.id = :departmentId) " +
           "AND (:status IS NULL OR p.status = :status) " +
           "AND (:query IS NULL OR LOWER(p.title) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(p.abstractText) LIKE LOWER(CONCAT('%', :query, '%')))")
    Page<Project> findAdminProjects(@Param("departmentId") Long departmentId, @Param("status") ProjectStatus status, @Param("query") String query, Pageable pageable);

    java.util.List<Project> findTop5ByStatusAndVisibilityAndIdNotOrderByCreatedAtDesc(ProjectStatus status, ProjectVisibility visibility, Long id);

    long countByStatus(ProjectStatus status);

    @Query("SELECT p.department.name, COUNT(p) FROM Project p GROUP BY p.department.name")
    java.util.List<Object[]> countProjectsByDepartment();

    @Query("SELECT p.status, COUNT(p) FROM Project p GROUP BY p.status")
    java.util.List<Object[]> countProjectsByStatus();
}
