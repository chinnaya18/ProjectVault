package com.projectvault.repository;

import com.projectvault.entity.ProjectWorkflowHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProjectWorkflowHistoryRepository extends JpaRepository<ProjectWorkflowHistory, Long> {
    List<ProjectWorkflowHistory> findByProjectIdOrderByCreatedAtAsc(Long projectId);
    void deleteByProjectId(Long projectId);
}
