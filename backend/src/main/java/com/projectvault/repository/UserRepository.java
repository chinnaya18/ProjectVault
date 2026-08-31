package com.projectvault.repository;

import com.projectvault.entity.Role;
import com.projectvault.entity.User;
import com.projectvault.entity.UserStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
    Page<User> findByDepartmentId(Long departmentId, Pageable pageable);
    Page<User> findByRole(Role role, Pageable pageable);
    java.util.List<User> findByRole(Role role);
    java.util.List<User> findByRoleAndIsActiveTrue(Role role);
    Page<User> findByUserStatus(UserStatus userStatus, Pageable pageable);
}
