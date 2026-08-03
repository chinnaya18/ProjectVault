package com.projectvault.service;

import com.projectvault.dto.request.CreateDepartmentRequest;
import com.projectvault.dto.request.UpdateDepartmentRequest;
import com.projectvault.dto.response.DepartmentDto;
import com.projectvault.dto.response.PageResponse;
import org.springframework.data.domain.Pageable;

public interface DepartmentService {
    PageResponse<DepartmentDto> getAllDepartments(Pageable pageable);
    DepartmentDto getDepartmentById(Long id);
    DepartmentDto createDepartment(CreateDepartmentRequest request);
    DepartmentDto updateDepartment(Long id, UpdateDepartmentRequest request);
    void deleteDepartment(Long id);
}
