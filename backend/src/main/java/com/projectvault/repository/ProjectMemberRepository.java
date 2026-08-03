package com.projectvault.repository;

import com.projectvault.entity.ProjectMember;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProjectMemberRepository extends JpaRepository<ProjectMember, Long> {
    List<ProjectMember> findByProjectId(Long projectId);
    void deleteByProjectId(Long projectId);
    boolean existsByProjectIdAndUserId(Long projectId, Long userId);
}
