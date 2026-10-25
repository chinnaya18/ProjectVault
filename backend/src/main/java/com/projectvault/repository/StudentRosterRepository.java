package com.projectvault.repository;

import com.projectvault.entity.StudentRoster;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface StudentRosterRepository extends JpaRepository<StudentRoster, Long> {
    Optional<StudentRoster> findByRollNoIgnoreCase(String rollNo);
    Optional<StudentRoster> findByEmailIgnoreCase(String email);
    boolean existsByRollNoIgnoreCase(String rollNo);
    boolean existsByEmailIgnoreCase(String email);
    List<StudentRoster> findByBatchIgnoreCase(String batch);
    List<StudentRoster> findByBatchIgnoreCaseAndDepartmentId(String batch, Long departmentId);

    @Query("SELECT r FROM StudentRoster r WHERE " +
           "LOWER(r.batch) = LOWER(:batch) OR " +
           "LOWER(r.rollNo) LIKE LOWER(CONCAT(:batch, '%'))")
    List<StudentRoster> findByBatchOrRollPrefix(@Param("batch") String batch);

    @Query("SELECT r FROM StudentRoster r WHERE " +
           "(:departmentId IS NULL OR r.department.id = :departmentId) AND " +
           "(:batch IS NULL OR r.batch = :batch) AND " +
           "(:isEligible IS NULL OR r.isEligible = :isEligible) AND " +
           "(:search IS NULL OR LOWER(r.rollNo) LIKE LOWER(CONCAT('%', :search, '%')) " +
           "OR LOWER(r.name) LIKE LOWER(CONCAT('%', :search, '%')) " +
           "OR LOWER(r.email) LIKE LOWER(CONCAT('%', :search, '%')))")
    Page<StudentRoster> searchRoster(
            @Param("departmentId") Long departmentId,
            @Param("batch") String batch,
            @Param("isEligible") Boolean isEligible,
            @Param("search") String search,
            Pageable pageable);

    long countByDepartmentId(Long departmentId);
    long countByIsRegisteredTrue();
    long countByIsEligibleTrue();
    long countByIsEligibleFalse();
}
