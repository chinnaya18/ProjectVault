package com.projectvault.mapper;

import com.projectvault.dto.response.DepartmentDto;
import com.projectvault.entity.Department;
import org.springframework.stereotype.Component;

@Component
public class DepartmentMapper {

    public DepartmentDto toDepartmentDto(Department department) {
        if (department == null) {
            return null;
        }
        return new DepartmentDto(
                department.getId(),
                department.getName(),
                department.getCode(),
                department.getDescription(),
                department.getCreatedAt()
        );
    }
}
