export type Role = 'ADMIN' | 'FACULTY' | 'STUDENT';
export type UserStatus = 'ACTIVE' | 'ALUMNI' | 'INACTIVE';
export type ProjectStatus = 'DRAFT' | 'SUBMITTED' | 'UNDER_REVIEW' | 'APPROVED' | 'REJECTED' | 'ARCHIVED';
export type ProjectVisibility = 'PUBLIC' | 'DEPARTMENT_ONLY' | 'PRIVATE';

export interface Department {
  id: number;
  name: string;
  code: string;
  description?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface User {
  id: number;
  email: string;
  name: string;
  rollNo?: string;
  role: Role;
  userStatus: UserStatus;
  departmentId?: number;
  departmentName?: string;
  departmentCode?: string;
  isActive: boolean;
  createdAt?: string;
}

export interface ProjectMember {
  id: number;
  userId: number;
  userName?: string;
  userFullName?: string;
  userEmail: string;
  userRollNo?: string;
  userRole?: Role;
  memberRole: string;
}

export interface ProjectWorkflowHistory {
  id: number;
  fromStatus?: ProjectStatus;
  toStatus: ProjectStatus;
  changedByUserId: number;
  changedByUserName?: string;
  changedByFullName?: string;
  createdAt: string;
}

export interface ProjectFile {
  id: number;
  fileName: string;
  fileType: string;
  fileSize: number;
  uploadedAt: string;
}

export interface ProjectSummary {
  id: number;
  title: string;
  abstractText: string;
  academicYear: string;
  semester: number;
  projectType: string;
  status: ProjectStatus;
  visibility: ProjectVisibility;
  departmentId: number;
  departmentName: string;
  createdByUserId: number;
  createdByUserName?: string;
  createdByRollNo?: string;
  createdByFullName?: string;
  guideFacultyId?: number;
  guideFacultyName?: string;
  repositoryUrl?: string;
  createdAt: string;
}

export interface ProjectDetail extends ProjectSummary {
  members: ProjectMember[];
  workflowHistory?: ProjectWorkflowHistory[];
  files?: ProjectFile[];
}

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
  timestamp: string;
}

export interface PageResponse<T> {
  content: T[];
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
  last: boolean;
}

export interface AuthResponse {
  token?: string;
  accessToken?: string;
  tokenType?: string;
  expiresInMs?: number;
  expiresIn?: number;
  user: User;
}

export interface RegisterRequest {
  email: string;
  password: string;
  name: string;
  rollNo?: string;
  departmentId?: number;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface CreateProjectRequest {
  title: string;
  abstractText: string;
  academicYear: string;
  semester: number;
  projectType: string;
  visibility: ProjectVisibility;
  departmentId: number;
  repositoryUrl?: string;
  guideFacultyId?: number;
  members?: { userId?: number; userEmail?: string; memberRole: string }[];
}

export interface UpdateProjectRequest {
  title?: string;
  abstractText?: string;
  academicYear?: string;
  semester?: number;
  projectType?: string;
  visibility?: ProjectVisibility;
  repositoryUrl?: string;
}
