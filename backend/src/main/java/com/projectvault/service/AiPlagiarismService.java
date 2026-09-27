package com.projectvault.service;

import com.projectvault.entity.Project;

public interface AiPlagiarismService {
    void evaluateProjectPlagiarism(Project project);
    void triggerProjectEmbeddingSync(Long projectId);
}
