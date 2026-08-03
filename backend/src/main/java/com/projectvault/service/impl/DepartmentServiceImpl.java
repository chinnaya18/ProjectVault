package com.projectvault.service.impl;

import com.projectvault.dto.request.CreateDepartmentRequest;
import com.projectvault.dto.request.UpdateDepartmentRequest;
import com.projectvault.dto.response.DepartmentDto;
import com.projectvault.dto.response.PageResponse;
import com.projectvault.entity.Department;
import com.projectvault.exception.BadRequestException;
import com.projectvault.exception.ResourceNotFoundException;
import com.projectvault.mapper.DepartmentMapper;
import com.projectvault.repository.DepartmentRepository;
import com.projectvault.service.DepartmentService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class DepartmentServiceImpl implements DepartmentService {

    private final DepartmentRepository departmentRepository;
    private final DepartmentMapper departmentMapper;

    public DepartmentServiceImpl(DepartmentRepository departmentRepository, DepartmentMapper departmentMapper) {
        this.departmentRepository = departmentRepository;
        this.departmentMapper = departmentMapper;
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<DepartmentDto> getAllDepartments(Pageable pageable) {
        Page<Department> page = departmentRepository.findAll(pageable);
        Page<DepartmentDto> dtoPage = page.map(departmentMapper::toDepartmentDto);
        return PageResponse.fromPage(dtoPage);
    }

    @Override
    @Transactional(readOnly = true)
    public DepartmentDto getDepartmentById(Long id) {
        Department department = departmentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Department", "id", id));
        return departmentMapper.toDepartmentDto(department);
    }

    @Override
    @Transactional
    public DepartmentDto createDepartment(CreateDepartmentRequest request) {
        if (departmentRepository.existsByName(request.getName())) {
            throw new BadRequestException("Department name already exists: " + request.getName());
        }
        if (departmentRepository.existsByCode(request.getCode())) {
            throw new BadRequestException("Department code already exists: " + request.getCode());
        }

        Department department = new Department(request.getName(), request.getCode(), request.getDescription());
        Department saved = departmentRepository.save(department);
        return departmentMapper.toDepartmentDto(saved);
    }

    @Override
    @Transactional
    public DepartmentDto updateDepartment(Long id, UpdateDepartmentRequest request) {
        Department department = departmentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Department", "id", id));

        if (request.getName() != null && !request.getName().equals(department.getName())) {
            if (departmentRepository.existsByName(request.getName())) {
                throw new BadRequestException("Department name already exists: " + request.getName());
            }
            department.setName(request.getName());
        }

        if (request.getCode() != null && !request.getCode().equals(department.getCode())) {
            if (departmentRepository.existsByCode(request.getCode())) {
                throw new BadRequestException("Department code already exists: " + request.getCode());
            }
            department.setCode(request.getCode());
        }

        if (request.getDescription() != null) {
            department.setDescription(request.getDescription());
        }

        Department updated = departmentRepository.save(department);
        return departmentMapper.toDepartmentDto(updated);
    }

    @Override
    @Transactional
    public void deleteDepartment(Long id) {
        Department department = departmentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Department", "id", id));
        departmentRepository.delete(department);
    }
}
