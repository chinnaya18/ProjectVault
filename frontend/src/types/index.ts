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
  remarks?: string;
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
  plagiarismScore?: number;
  duplicationScore?: number;
  plagiarismReport?: string;
  plagiarismStatus?: string;
  similarityScore?: number;
  createdAt: string;
}

export interface MatchedArchivedProject {
  project_id: number;
  title: string;
  similarity_score: number;
  status: string;
  department_name?: string;
  similarity_summary?: string;
}

export interface PlagiarismReportDetail {
  plagiarism_score: number;
  plagiarism_verdict: string;
  duplication_score: number;
  duplication_verdict: string;
  text_similarity_score?: number;
  code_similarity_score?: number;
  repo_duplicate_detected?: boolean;
  internet_sources_detected?: { source_name?: string; match_percentage?: number; is_properly_cited?: boolean; details?: string }[];
  valid_citations_detected?: { citation_text: string; source_type: string; status: string }[];
  uncited_matches?: string[];
  matched_archived_projects?: MatchedArchivedProject[];
  summary_explanation?: string;
  recommendation_for_faculty?: string;
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

// ==========================================
// AI Microservice Types
// ==========================================

export interface ProjectSearchResult {
  id: number;
  title: string;
  abstract: string;
  academic_year: string;
  semester: number;
  project_type: string;
  status: string;
  visibility: string;
  department_id: number;
  department_name?: string;
  author_name?: string;
  similarity_score: number;
  domain?: string;
  tech_stack: string[];
  keywords: string[];
  repository_url?: string;
}

export interface TopicFeedback {
  query: string;
  is_novel: boolean;
  verdict: string;
  domain: string;
  academic_value: string;
  recommended_tech_stack: string[];
  implementation_roadmap: string[];
  key_challenges: string[];
  faculty_guidance: string;
}

export interface SemanticSearchResponse {
  query: string;
  total_results: number;
  results: ProjectSearchResult[];
  execution_time_ms: number;
  topic_feedback?: TopicFeedback | null;
}

export interface ProjectCitation {
  id: number;
  title: string;
  similarity_score: number;
  domain?: string;
  tech_stack: string[];
}

export interface AskQuestionResponse {
  question: string;
  answer: string;
  grounded: boolean;
  referenced_projects: ProjectCitation[];
  retrieved_count: number;
  confidence: 'HIGH' | 'MEDIUM' | 'LOW' | 'INSUFFICIENT_CONTEXT' | string;
  execution_time_ms: number;
}

export interface ChatMessage {
  id: string;
  sender: 'user' | 'assistant';
  content: string;
  timestamp: string;
  referenced_projects?: ProjectCitation[];
  grounded?: boolean;
  confidence?: string;
  execution_time_ms?: number;
  isLoading?: boolean;
}

export interface DashboardAnalytics {
  totalProjects: number;
  approvedProjects: number;
  underReviewProjects: number;
  submittedProjects: number;
  draftProjects: number;
  rejectedProjects: number;
  archivedProjects: number;
  totalUsers: number;
  studentUsers: number;
  facultyUsers: number;
  adminUsers: number;
  alumniUsers: number;
  totalDepartments: number;
  departmentProjectCounts: Record<string, number>;
  statusCounts: Record<string, number>;
  domainDistribution: Record<string, number>;
  topTechStacks: Record<string, number>;
}

export interface AuditLog {
  id: number;
  userId?: number;
  userName?: string;
  userEmail?: string;
  action: string;
  entityType: string;
  entityId?: number;
  details?: string;
  ipAddress?: string;
  timestamp: string;
}

export interface ProjectRecommendation extends ProjectSummary {
  similarityScore?: number;
}


