import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { ProjectSummary, Department, ProjectStatus, ApiResponse, PageResponse } from '../types';
import api from '../api/client';
import { CreateProjectModal } from './CreateProjectModal';
import { ProjectDetailModal } from './ProjectDetailModal';
import { formatFacultyName, formatUserNameByRole } from '../utils/userFormat';
import { 
  Plus, 
  Search, 
  FolderGit2, 
  Calendar, 
  User as UserIcon, 
  Filter, 
  ChevronLeft, 
  ChevronRight, 
  CheckCircle2, 
  Clock, 
  FileEdit, 
  ShieldCheck, 
  RefreshCw, 
  Send, 
  Eye, 
  FolderOpen, 
  Users 
} from 'lucide-react';

export const UserDashboard: React.FC = () => {
  const { user, refreshProfile } = useAuth();

  const isStudent = user?.role === 'STUDENT';
  const isFaculty = user?.role === 'FACULTY';
  const isAdmin = user?.role === 'ADMIN';

  // All projects fetched from server
  const [allProjects, setAllProjects] = useState<ProjectSummary[]>([]);
  const [departments, setDepartments] = useState<Department[]>([]);

  // Active Main Tab
  const [activeTab, setActiveTab] = useState<'my-projects' | 'faculty-hub' | 'catalog' | 'review'>(
    isFaculty ? 'faculty-hub' : isAdmin ? 'catalog' : 'my-projects'
  );

  // Status Sub-filter
  const [selectedStatus, setSelectedStatus] = useState<string>('');
  const [selectedDept, setSelectedDept] = useState<string>('');
  const [searchTerm, setSearchTerm] = useState<string>('');
  
  // Pagination
  const [page, setPage] = useState<number>(0);
  const [totalPages, setTotalPages] = useState<number>(1);
  const [totalElements, setTotalElements] = useState<number>(0);

  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isRefreshing, setIsRefreshing] = useState<boolean>(false);
  const [isCreateOpen, setIsCreateOpen] = useState<boolean>(false);
  const [selectedProjectId, setSelectedProjectId] = useState<number | null>(null);

  // Initialize active tab on role load
  useEffect(() => {
    if (isFaculty) {
      setActiveTab('faculty-hub');
    } else if (isAdmin) {
      setActiveTab('catalog');
    } else {
      setActiveTab('my-projects');
    }
  }, [user?.role]);

  // Initial load
  useEffect(() => {
    fetchDepartments();
  }, []);

  // Fetch projects when page, dept, status, or user changes
  useEffect(() => {
    fetchProjects();
  }, [page, selectedDept, selectedStatus, user?.id]);

  const fetchDepartments = async () => {
    try {
      const res = await api.get<ApiResponse<PageResponse<Department>>>('/departments?size=100');
      if (res.data && res.data.data && res.data.data.content) {
        setDepartments(res.data.data.content);
      }
    } catch (err) {
      console.error('Error fetching departments:', err);
    }
  };

  const fetchProjects = async () => {
    setIsLoading(true);
    try {
      let url = `/projects?page=${page}&size=50`;
      if (selectedDept) url += `&departmentId=${selectedDept}`;
      if (selectedStatus) url += `&status=${selectedStatus}`;

      const res = await api.get<ApiResponse<PageResponse<ProjectSummary>>>(url);
      if (res.data && res.data.data) {
        setAllProjects(res.data.data.content || []);
        setTotalPages(res.data.data.totalPages || 1);
        setTotalElements(res.data.data.totalElements || 0);
      }
    } catch (err) {
      console.error('Error fetching projects:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const handleManualRefresh = async () => {
    setIsRefreshing(true);
    await refreshProfile();
    await fetchProjects();
    setIsRefreshing(false);
  };

  // Filter projects by search term
  const filterBySearch = (projectsList: ProjectSummary[]) => {
    if (!searchTerm.trim()) return projectsList;
    const term = searchTerm.toLowerCase().trim();
    return projectsList.filter((p) => {
      const title = (p.title || '').toLowerCase();
      const abs = (p.abstractText || '').toLowerCase();
      const authorName = (p.createdByUserName || p.createdByFullName || '').toLowerCase();
      const rollNo = (p.createdByRollNo || '').toLowerCase();
      const guide = (p.guideFacultyName || '').toLowerCase();
      return (
        title.includes(term) ||
        abs.includes(term) ||
        authorName.includes(term) ||
        rollNo.includes(term) ||
        guide.includes(term)
      );
    });
  };

  // 1. Projects for Student (Created by or Member of)
  const studentProjects = allProjects.filter(p => user && p.createdByUserId === user.id);
  const filteredStudentProjects = filterBySearch(studentProjects);

  // 2. Projects for Faculty (Guided by faculty or created by faculty, excluding unsubmitted student drafts)
  const facultyGuidedProjects = allProjects.filter(p => {
    if (!user) return false;
    if (p.createdByUserId === user.id) return true;
    return p.guideFacultyId === user.id && p.status !== 'DRAFT';
  });
  const filteredFacultyProjects = filterBySearch(facultyGuidedProjects);

  // 3. Projects for Review (Submitted & Under Review)
  const pendingReviewProjects = allProjects.filter(p => {
    const isPending = p.status === 'SUBMITTED' || p.status === 'UNDER_REVIEW';
    if (!isPending) return false;
    if (isAdmin) return true;
    if (isFaculty) {
      return !p.guideFacultyId || p.guideFacultyId === user?.id;
    }
    return false;
  });
  const filteredReviewProjects = filterBySearch(pendingReviewProjects);

  // 4. Catalog Projects (Admin or Public View)
  const filteredCatalogProjects = filterBySearch(allProjects);

  // Counts for Student View
  const studentTotalCount = studentProjects.length;
  const studentApprovedCount = studentProjects.filter(p => p.status === 'APPROVED').length;
  const studentPendingCount = studentProjects.filter(p => p.status === 'SUBMITTED' || p.status === 'UNDER_REVIEW').length;
  const studentDraftCount = studentProjects.filter(p => p.status === 'DRAFT').length;

  // Counts for Faculty View (Based on their guided submissions, excluding student drafts)
  const facultyTotalCount = facultyGuidedProjects.length;
  const facultySubmittedCount = facultyGuidedProjects.filter(p => p.status === 'SUBMITTED').length;
  const facultyUnderReviewCount = facultyGuidedProjects.filter(p => p.status === 'UNDER_REVIEW').length;
  const facultyApprovedCount = facultyGuidedProjects.filter(p => p.status === 'APPROVED').length;
  const facultyRejectedCount = facultyGuidedProjects.filter(p => p.status === 'REJECTED').length;

  const getStatusBadge = (status: ProjectStatus) => {
    const styles: Record<ProjectStatus, string> = {
      DRAFT: 'bg-amber-50 text-amber-700 border-amber-200',
      SUBMITTED: 'bg-sky-50 text-sky-700 border-sky-200',
      UNDER_REVIEW: 'bg-indigo-50 text-indigo-700 border-indigo-200',
      APPROVED: 'bg-emerald-50 text-emerald-700 border-emerald-200',
      REJECTED: 'bg-rose-50 text-rose-700 border-rose-200',
      ARCHIVED: 'bg-slate-100 text-slate-700 border-slate-200',
    };
    return (
      <span className={`px-2.5 py-0.5 text-xs font-bold rounded-full border ${styles[status]}`}>
        {status.replace('_', ' ')}
      </span>
    );
  };

  const handleQuickSubmitDraft = async (e: React.MouseEvent, proj: ProjectSummary) => {
    e.stopPropagation();
    if (!proj.repositoryUrl) {
      setSelectedProjectId(proj.id);
      return;
    }
    try {
      await api.patch(`/projects/${proj.id}/status`, { status: 'SUBMITTED' });
      fetchProjects();
    } catch (err) {
      console.error('Failed to submit draft:', err);
      setSelectedProjectId(proj.id);
    }
  };

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">
      {/* Personalized Welcome Banner */}
      <div className="bg-gradient-to-r from-indigo-700 via-indigo-800 to-slate-900 rounded-3xl p-6 sm:p-8 text-white shadow-xl relative overflow-hidden">
        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div className="space-y-3 max-w-2xl">
            <div className="flex flex-wrap items-center gap-2">
              {user?.role && (
                <span className="px-2.5 py-0.5 rounded-full text-xs font-extrabold bg-white/20 text-white border border-white/20 uppercase tracking-wider">
                  {user.role}
                </span>
              )}
              {user?.rollNo && (
                <span className="px-2.5 py-0.5 rounded-full text-xs font-mono font-bold bg-white/10 text-indigo-100 border border-white/20">
                  {user.rollNo}
                </span>
              )}
              {user?.userStatus && (
                <span className={`px-2.5 py-0.5 rounded-full text-xs font-extrabold border uppercase tracking-wider ${
                  user.userStatus === 'ACTIVE' ? 'bg-emerald-500/30 text-emerald-200 border-emerald-400/30' : 'bg-amber-500/30 text-amber-200 border-amber-400/30'
                }`}>
                  {user.userStatus}
                </span>
              )}
            </div>

            <h1 className="text-2xl sm:text-4xl font-extrabold tracking-tight">
              Welcome back, {formatUserNameByRole(user?.name || user?.email?.split('@')[0], user?.role)}!
            </h1>

            <p className="text-indigo-100 text-sm sm:text-base leading-relaxed">
              {isAdmin
                ? 'System Administrator Control Center. Manage students, staff, department data, and oversee all project submissions.'
                : isFaculty
                ? `Faculty Evaluator Hub. Track all assigned student teams, evaluate pending submissions, and review project lifecycles.`
                : user?.departmentName
                ? `Student Research Workspace — ${user.departmentName}`
                : 'Manage your research submissions, project drafts, and capstone progress.'}
            </p>
          </div>

          {/* Quick Action Buttons */}
          <div className="flex flex-wrap items-center gap-3 shrink-0">
            {isStudent && (
              <button
                onClick={() => setIsCreateOpen(true)}
                className="inline-flex items-center space-x-2 px-5 py-3 rounded-2xl bg-white text-indigo-700 font-bold text-sm hover:bg-indigo-50 transition-all shadow-lg hover:shadow-white/20"
              >
                <Plus className="w-4 h-4" />
                <span>Submit New Project</span>
              </button>
            )}

            {isAdmin && (
              <Link
                to="/users"
                className="inline-flex items-center space-x-2 px-5 py-3 rounded-2xl bg-white text-indigo-700 font-bold text-sm hover:bg-indigo-50 transition-all shadow-lg hover:shadow-white/20"
              >
                <Users className="w-4 h-4" />
                <span>Manage Students & Staff</span>
              </Link>
            )}

            <button
              onClick={handleManualRefresh}
              disabled={isRefreshing}
              className="p-3 rounded-2xl bg-white/10 hover:bg-white/20 text-white transition-colors border border-white/20"
              title="Refresh Data"
            >
              <RefreshCw className={`w-4 h-4 ${isRefreshing ? 'animate-spin' : ''}`} />
            </button>
          </div>
        </div>
      </div>

      {/* 1. STUDENT STATISTICS CARDS */}
      {isStudent && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-xs font-bold uppercase tracking-wider text-slate-400">My Submissions</span>
              <div className="text-2xl font-extrabold text-slate-900">{studentTotalCount}</div>
              <span className="text-xs text-slate-500 font-medium">Total projects created</span>
            </div>
            <div className="w-12 h-12 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center font-bold">
              <FolderOpen className="w-6 h-6" />
            </div>
          </div>

          <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-xs font-bold uppercase tracking-wider text-emerald-600">Approved Projects</span>
              <div className="text-2xl font-extrabold text-emerald-700">{studentApprovedCount}</div>
              <span className="text-xs text-slate-500 font-medium">Published in catalog</span>
            </div>
            <div className="w-12 h-12 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center font-bold">
              <CheckCircle2 className="w-6 h-6" />
            </div>
          </div>

          <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-xs font-bold uppercase tracking-wider text-sky-600">Under Review</span>
              <div className="text-2xl font-extrabold text-sky-700">{studentPendingCount}</div>
              <span className="text-xs text-slate-500 font-medium">Awaiting evaluation</span>
            </div>
            <div className="w-12 h-12 rounded-2xl bg-sky-50 text-sky-600 flex items-center justify-center font-bold">
              <Clock className="w-6 h-6" />
            </div>
          </div>

          <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-xs font-bold uppercase tracking-wider text-amber-600">Draft Entries</span>
              <div className="text-2xl font-extrabold text-amber-700">{studentDraftCount}</div>
              <span className="text-xs text-slate-500 font-medium">In preparation</span>
            </div>
            <div className="w-12 h-12 rounded-2xl bg-amber-50 text-amber-600 flex items-center justify-center font-bold">
              <FileEdit className="w-6 h-6" />
            </div>
          </div>
        </div>
      )}

      {/* 2. FACULTY STATISTICS CARDS */}
      {isFaculty && (
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4">
          <div 
            onClick={() => { setSelectedStatus(''); setPage(0); }}
            className={`bg-white rounded-2xl p-4 border transition-all cursor-pointer shadow-sm hover:-translate-y-0.5 ${
              selectedStatus === '' ? 'border-indigo-500 ring-2 ring-indigo-500/20' : 'border-slate-200'
            }`}
          >
            <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500">All Submissions</span>
            <div className="text-2xl font-extrabold text-slate-900 mt-1">{facultyTotalCount}</div>
            <span className="text-[10px] text-slate-400 font-medium">Guided Projects</span>
          </div>

          <div 
            onClick={() => { setSelectedStatus('SUBMITTED'); setPage(0); }}
            className={`bg-white rounded-2xl p-4 border transition-all cursor-pointer shadow-sm hover:-translate-y-0.5 ${
              selectedStatus === 'SUBMITTED' ? 'border-sky-500 ring-2 ring-sky-500/20' : 'border-slate-200'
            }`}
          >
            <span className="text-[11px] font-bold uppercase tracking-wider text-sky-600">Submitted</span>
            <div className="text-2xl font-extrabold text-sky-700 mt-1">{facultySubmittedCount}</div>
            <span className="text-[10px] text-sky-500 font-medium">Awaiting Review</span>
          </div>

          <div 
            onClick={() => { setSelectedStatus('UNDER_REVIEW'); setPage(0); }}
            className={`bg-white rounded-2xl p-4 border transition-all cursor-pointer shadow-sm hover:-translate-y-0.5 ${
              selectedStatus === 'UNDER_REVIEW' ? 'border-indigo-500 ring-2 ring-indigo-500/20' : 'border-slate-200'
            }`}
          >
            <span className="text-[11px] font-bold uppercase tracking-wider text-indigo-600">Under Review</span>
            <div className="text-2xl font-extrabold text-indigo-700 mt-1">{facultyUnderReviewCount}</div>
            <span className="text-[10px] text-indigo-500 font-medium">In Evaluation</span>
          </div>

          <div 
            onClick={() => { setSelectedStatus('APPROVED'); setPage(0); }}
            className={`bg-white rounded-2xl p-4 border transition-all cursor-pointer shadow-sm hover:-translate-y-0.5 ${
              selectedStatus === 'APPROVED' ? 'border-emerald-500 ring-2 ring-emerald-500/20' : 'border-slate-200'
            }`}
          >
            <span className="text-[11px] font-bold uppercase tracking-wider text-emerald-600">Approved</span>
            <div className="text-2xl font-extrabold text-emerald-700 mt-1">{facultyApprovedCount}</div>
            <span className="text-[10px] text-emerald-500 font-medium">Published</span>
          </div>

          <div 
            onClick={() => { setSelectedStatus('REJECTED'); setPage(0); }}
            className={`bg-white rounded-2xl p-4 border transition-all cursor-pointer shadow-sm hover:-translate-y-0.5 ${
              selectedStatus === 'REJECTED' ? 'border-rose-500 ring-2 ring-rose-500/20' : 'border-slate-200'
            }`}
          >
            <span className="text-[11px] font-bold uppercase tracking-wider text-rose-600">Rejected</span>
            <div className="text-2xl font-extrabold text-rose-700 mt-1">{facultyRejectedCount}</div>
            <span className="text-[10px] text-rose-500 font-medium">With Feedback</span>
          </div>
        </div>
      )}

      {/* Main Navigation Tabs (Only for Staff / Admin) */}
      {!isStudent && (
        <div className="border-b border-slate-200 flex items-center justify-between">
          <div className="flex space-x-2">
            {isFaculty && (
              <button
                onClick={() => setActiveTab('faculty-hub')}
                className={`flex items-center space-x-2 py-3 px-4 text-sm font-bold border-b-2 transition-all ${
                  activeTab === 'faculty-hub'
                    ? 'border-indigo-600 text-indigo-600'
                    : 'border-transparent text-slate-500 hover:text-slate-800'
                }`}
              >
                <ShieldCheck className="w-4 h-4" />
                <span>Student Submissions & Evaluation Hub ({facultyGuidedProjects.length})</span>
              </button>
            )}

            {isAdmin && (
              <>
                <button
                  onClick={() => setActiveTab('catalog')}
                  className={`flex items-center space-x-2 py-3 px-4 text-sm font-bold border-b-2 transition-all ${
                    activeTab === 'catalog'
                      ? 'border-indigo-600 text-indigo-600'
                      : 'border-transparent text-slate-500 hover:text-slate-800'
                  }`}
                >
                  <FolderGit2 className="w-4 h-4" />
                  <span>All Repository Catalog</span>
                </button>

                <button
                  onClick={() => setActiveTab('review')}
                  className={`flex items-center space-x-2 py-3 px-4 text-sm font-bold border-b-2 transition-all ${
                    activeTab === 'review'
                      ? 'border-indigo-600 text-indigo-600'
                      : 'border-transparent text-slate-500 hover:text-slate-800'
                  }`}
                >
                  <ShieldCheck className="w-4 h-4" />
                  <span>Projects Under Review ({pendingReviewProjects.length})</span>
                </button>
              </>
            )}
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* 1. STUDENT VIEW: MY PROJECTS & USAGE ONLY                                */}
      {/* ========================================================================= */}
      {isStudent && (
        <div className="space-y-6">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <h2 className="text-xl font-bold text-slate-900">Your Project Submissions</h2>
              <p className="text-xs text-slate-500">Track and manage your capstone drafts and evaluation status.</p>
            </div>

            <button
              onClick={() => setIsCreateOpen(true)}
              className="inline-flex items-center space-x-2 px-4 py-2 rounded-xl bg-indigo-600 text-white font-semibold text-xs hover:bg-indigo-700 transition-colors shadow-sm"
            >
              <Plus className="w-3.5 h-3.5" />
              <span>Create Project Draft</span>
            </button>
          </div>

          {/* Search & Status Filters for Student */}
          <div className="bg-white p-4 rounded-2xl shadow-sm border border-slate-200 space-y-3">
            <div className="relative">
              <Search className="w-4 h-4 absolute left-3.5 top-3 text-slate-400" />
              <input
                type="text"
                placeholder="Search your projects by title or keywords..."
                className="w-full pl-10 pr-4 py-2 rounded-xl border border-slate-200 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>

            <div className="flex items-center space-x-1.5 overflow-x-auto pb-1 pt-1 border-t border-slate-100">
              {[
                { label: 'All Projects', value: '' },
                { label: 'Approved', value: 'APPROVED' },
                { label: 'Drafts', value: 'DRAFT' },
                { label: 'Submitted', value: 'SUBMITTED' },
                { label: 'Under Review', value: 'UNDER_REVIEW' },
                { label: 'Rejected', value: 'REJECTED' },
              ].map((tab) => (
                <button
                  key={tab.value}
                  onClick={() => {
                    setSelectedStatus(tab.value);
                    setPage(0);
                  }}
                  className={`px-3 py-1.5 rounded-lg text-xs font-semibold whitespace-nowrap transition-colors ${
                    selectedStatus === tab.value
                      ? 'bg-indigo-600 text-white shadow-sm'
                      : 'text-slate-600 hover:bg-slate-100'
                  }`}
                >
                  {tab.label}
                </button>
              ))}
            </div>
          </div>

          {/* Projects Grid */}
          {isLoading ? (
            <div className="py-12 text-center text-slate-400 font-medium">Loading your projects...</div>
          ) : filteredStudentProjects.length === 0 ? (
            <div className="py-12 text-center bg-white rounded-2xl border border-slate-200 p-8 space-y-4">
              <FolderGit2 className="w-12 h-12 text-indigo-200 mx-auto" />
              <div className="space-y-1">
                <h3 className="text-lg font-bold text-slate-800">No Projects Found</h3>
                <p className="text-sm text-slate-500 max-w-md mx-auto">
                  {selectedStatus
                    ? `No projects found with status '${selectedStatus.replace('_', ' ')}'.`
                    : 'You have not created any academic project drafts. Click below to submit your capstone.'}
                </p>
              </div>
              <button
                onClick={() => setIsCreateOpen(true)}
                className="inline-flex items-center space-x-2 px-5 py-2.5 rounded-xl bg-indigo-600 text-white font-bold text-sm hover:bg-indigo-700 transition-colors shadow-md"
              >
                <Plus className="w-4 h-4" />
                <span>Create Your First Project</span>
              </button>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {filteredStudentProjects.map((project) => (
                <div
                  key={project.id}
                  onClick={() => setSelectedProjectId(project.id)}
                  className="bg-white rounded-2xl border border-slate-200 p-6 hover:shadow-lg transition-all duration-200 flex flex-col justify-between cursor-pointer group"
                >
                  <div className="space-y-3">
                    <div className="flex items-center justify-between gap-2">
                      <span className="text-xs font-semibold text-indigo-600 bg-indigo-50 px-2.5 py-0.5 rounded-md">
                        {project.departmentName || 'MCA'}
                      </span>
                      {getStatusBadge(project.status)}
                    </div>

                    <h3 className="text-lg font-bold text-slate-900 group-hover:text-indigo-600 transition-colors line-clamp-2">
                      {project.title}
                    </h3>

                    <p className="text-sm text-slate-600 line-clamp-3 leading-relaxed">
                      {project.abstractText}
                    </p>
                  </div>

                  <div className="pt-4 mt-4 border-t border-slate-100 flex items-center justify-between text-xs">
                    <div className="flex items-center space-x-1.5 text-slate-500 font-medium">
                      <Calendar className="w-3.5 h-3.5 text-slate-400" />
                      <span>AY {project.academicYear}</span>
                    </div>

                    <div className="flex items-center space-x-2">
                      {project.status === 'DRAFT' && (
                        <button
                          onClick={(e) => handleQuickSubmitDraft(e, project)}
                          className="flex items-center space-x-1 px-2.5 py-1 rounded-lg bg-indigo-600 text-white text-xs font-semibold hover:bg-indigo-700 transition-colors"
                        >
                          <Send className="w-3 h-3" />
                          <span>Submit</span>
                        </button>
                      )}
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          setSelectedProjectId(project.id);
                        }}
                        className="flex items-center space-x-1 px-2.5 py-1 rounded-lg bg-slate-100 text-slate-700 text-xs font-semibold hover:bg-slate-200 transition-colors"
                      >
                        <Eye className="w-3 h-3" />
                        <span>View</span>
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* ========================================================================= */}
      {/* 2. FACULTY VIEW: STUDENT SUBMISSIONS & EVALUATION HUB                    */}
      {/* ========================================================================= */}
      {isFaculty && (
        <div className="space-y-6">
          {/* Search and Status Filters */}
          <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200 space-y-4">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
              <div className="relative flex-1">
                <Search className="w-4 h-4 absolute left-3.5 top-3 text-slate-400" />
                <input
                  type="text"
                  placeholder="Search by student name, roll number, project title, or abstract..."
                  className="w-full pl-10 pr-4 py-2 rounded-xl border border-slate-300 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                />
              </div>
            </div>

            {/* Status Tabs with Live Badges */}
            <div className="flex items-center space-x-1.5 overflow-x-auto pb-1 border-t border-slate-100 pt-3">
              {[
                { label: 'All Submissions', value: '', count: facultyTotalCount },
                { label: 'Submitted (Awaiting Review)', value: 'SUBMITTED', count: facultySubmittedCount },
                { label: 'Under Review', value: 'UNDER_REVIEW', count: facultyUnderReviewCount },
                { label: 'Approved', value: 'APPROVED', count: facultyApprovedCount },
                { label: 'Rejected', value: 'REJECTED', count: facultyRejectedCount },
              ].map((tab) => (
                <button
                  key={tab.value}
                  onClick={() => {
                    setSelectedStatus(tab.value);
                    setPage(0);
                  }}
                  className={`inline-flex items-center space-x-2 px-3.5 py-2 rounded-xl text-xs font-bold whitespace-nowrap transition-all ${
                    selectedStatus === tab.value
                      ? 'bg-indigo-600 text-white shadow-sm'
                      : 'text-slate-600 hover:bg-slate-100 bg-slate-50 border border-slate-200/60'
                  }`}
                >
                  <span>{tab.label}</span>
                  <span className={`px-1.5 py-0.2 rounded-full text-[10px] font-extrabold ${
                    selectedStatus === tab.value
                      ? 'bg-white/20 text-white'
                      : 'bg-slate-200 text-slate-700'
                  }`}>
                    {tab.count}
                  </span>
                </button>
              ))}
            </div>
          </div>

          {/* Faculty Guided Projects Grid */}
          {isLoading ? (
            <div className="py-12 text-center text-slate-400 font-medium">Loading guided student submissions...</div>
          ) : filteredFacultyProjects.length === 0 ? (
            <div className="py-12 text-center bg-white rounded-2xl border border-slate-200 p-8 space-y-2">
              <FolderGit2 className="w-12 h-12 text-slate-300 mx-auto" />
              <h3 className="text-lg font-bold text-slate-800">No Student Submissions Found</h3>
              <p className="text-sm text-slate-500 max-w-md mx-auto">
                {selectedStatus
                  ? `No submissions found for your guided teams with status '${selectedStatus.replace('_', ' ')}'.`
                  : 'There are currently no student projects assigned to you for faculty guidance.'}
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {filteredFacultyProjects.map((project) => (
                <div
                  key={project.id}
                  onClick={() => setSelectedProjectId(project.id)}
                  className="bg-white rounded-2xl border border-slate-200 p-6 hover:shadow-xl transition-all duration-200 flex flex-col justify-between cursor-pointer space-y-4 group hover:border-indigo-300"
                >
                  <div className="space-y-3">
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-semibold text-indigo-600 bg-indigo-50 px-2.5 py-0.5 rounded-md">
                        {project.departmentName || 'MCA'}
                      </span>
                      {getStatusBadge(project.status)}
                    </div>

                    <h3 className="text-lg font-bold text-slate-900 group-hover:text-indigo-600 transition-colors">
                      {project.title}
                    </h3>

                    <p className="text-sm text-slate-600 line-clamp-3 leading-relaxed">
                      {project.abstractText}
                    </p>
                  </div>

                  <div className="pt-4 border-t border-slate-100 flex flex-wrap items-center justify-between gap-2 text-xs">
                    <div className="space-y-1">
                      <div className="font-semibold text-slate-700 flex items-center gap-1.5">
                        <UserIcon className="w-3.5 h-3.5 text-slate-400" />
                        <span>Author: {project.createdByUserName || 'Student'}</span>
                        {project.createdByRollNo && (
                          <span className="text-[11px] font-mono px-1.5 py-0.2 bg-slate-100 text-slate-600 border border-slate-200 rounded">
                            {project.createdByRollNo}
                          </span>
                        )}
                        <span className="text-[10px] font-bold px-1.5 py-0.2 bg-blue-50 text-blue-700 border border-blue-200 rounded">
                          Student
                        </span>
                      </div>

                      <div className="flex items-center space-x-1.5 text-slate-500 font-medium">
                        <Calendar className="w-3.5 h-3.5 text-slate-400" />
                        <span>AY {project.academicYear} (Semester {project.semester})</span>
                      </div>
                    </div>

                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        setSelectedProjectId(project.id);
                      }}
                      className="px-4 py-2 rounded-xl bg-indigo-600 text-white font-bold text-xs hover:bg-indigo-700 transition-colors shadow-sm"
                    >
                      {project.status === 'SUBMITTED' || project.status === 'UNDER_REVIEW'
                        ? 'Evaluate Submission'
                        : 'View Details'}
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* ========================================================================= */}
      {/* 3. ADMIN VIEW: GLOBAL REPOSITORY CATALOG & SYSTEM REVIEWS                 */}
      {/* ========================================================================= */}
      {isAdmin && activeTab === 'catalog' && (
        <div className="space-y-6">
          {/* Search and Filters */}
          <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200 space-y-4">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
              <div className="relative flex-1">
                <Search className="w-4 h-4 absolute left-3.5 top-3 text-slate-400" />
                <input
                  type="text"
                  placeholder="Search projects across all university departments..."
                  className="w-full pl-10 pr-4 py-2 rounded-xl border border-slate-300 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                />
              </div>

              <div className="flex items-center space-x-2">
                <Filter className="w-4 h-4 text-slate-400 shrink-0" />
                <select
                  className="px-3 py-2 rounded-xl border border-slate-300 text-sm text-slate-900 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  value={selectedDept}
                  onChange={(e) => {
                    setSelectedDept(e.target.value);
                    setPage(0);
                  }}
                >
                  <option value="">All Departments</option>
                  {departments.map((d) => (
                    <option key={d.id} value={d.id}>
                      {d.name} ({d.code})
                    </option>
                  ))}
                </select>
              </div>
            </div>

            {/* Status Filter Buttons */}
            <div className="flex items-center space-x-1.5 overflow-x-auto pb-1 border-t border-slate-100 pt-3">
              {[
                { label: 'All Projects', value: '' },
                { label: 'Approved', value: 'APPROVED' },
                { label: 'Drafts', value: 'DRAFT' },
                { label: 'Submitted', value: 'SUBMITTED' },
                { label: 'Under Review', value: 'UNDER_REVIEW' },
                { label: 'Rejected', value: 'REJECTED' },
              ].map((tab) => (
                <button
                  key={tab.value}
                  onClick={() => {
                    setSelectedStatus(tab.value);
                    setPage(0);
                  }}
                  className={`px-3.5 py-1.5 rounded-lg text-xs font-semibold whitespace-nowrap transition-colors ${
                    selectedStatus === tab.value
                      ? 'bg-indigo-600 text-white shadow-sm'
                      : 'text-slate-600 hover:bg-slate-100'
                  }`}
                >
                  {tab.label}
                </button>
              ))}
            </div>
          </div>

          {/* Catalog Grid */}
          {isLoading ? (
            <div className="py-12 text-center text-slate-400 font-medium">Loading catalog...</div>
          ) : filteredCatalogProjects.length === 0 ? (
            <div className="py-12 text-center bg-white rounded-2xl border border-slate-200 p-8 space-y-2">
              <FolderGit2 className="w-12 h-12 text-slate-300 mx-auto" />
              <h3 className="text-lg font-bold text-slate-800">No Projects Found</h3>
              <p className="text-sm text-slate-500">No projects match the current filter selection.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {filteredCatalogProjects.map((project) => (
                <div
                  key={project.id}
                  onClick={() => setSelectedProjectId(project.id)}
                  className="bg-white rounded-2xl border border-slate-200 p-6 hover:shadow-lg transition-all duration-200 flex flex-col justify-between cursor-pointer group"
                >
                  <div className="space-y-3">
                    <div className="flex items-center justify-between gap-2">
                      <span className="text-xs font-semibold text-indigo-600 bg-indigo-50 px-2.5 py-0.5 rounded-md">
                        {project.departmentName}
                      </span>
                      {getStatusBadge(project.status)}
                    </div>

                    <h3 className="text-lg font-bold text-slate-900 group-hover:text-indigo-600 transition-colors line-clamp-2">
                      {project.title}
                    </h3>

                    <p className="text-sm text-slate-600 line-clamp-3 leading-relaxed">
                      {project.abstractText}
                    </p>
                  </div>

                  <div className="pt-4 mt-4 border-t border-slate-100 flex flex-wrap items-center justify-between gap-2 text-xs text-slate-500 font-medium">
                    <div className="flex items-center space-x-1.5">
                      <UserIcon className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                      <span className="font-semibold text-slate-700">{project.createdByUserName || 'Contributor'}</span>
                      {project.createdByRollNo && (
                        <span className="text-[11px] font-mono px-1.5 py-0.5 rounded bg-slate-100 text-slate-600 border border-slate-200">
                          {project.createdByRollNo}
                        </span>
                      )}
                    </div>
                    <div className="flex items-center space-x-1.5">
                      <Calendar className="w-3.5 h-3.5 text-slate-400" />
                      <span>AY {project.academicYear}</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex items-center justify-between bg-white px-4 py-3 rounded-xl border border-slate-200 text-sm">
              <span className="text-slate-500 text-xs font-medium">
                Page {page + 1} of {totalPages} ({totalElements} total entries)
              </span>
              <div className="flex items-center space-x-2">
                <button
                  onClick={() => setPage((p) => Math.max(0, p - 1))}
                  disabled={page === 0}
                  className="p-1.5 rounded-lg border border-slate-200 text-slate-600 hover:bg-slate-100 disabled:opacity-40"
                >
                  <ChevronLeft className="w-4 h-4" />
                </button>
                <button
                  onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
                  disabled={page >= totalPages - 1}
                  className="p-1.5 rounded-lg border border-slate-200 text-slate-600 hover:bg-slate-100 disabled:opacity-40"
                >
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>
            </div>
          )}
        </div>
      )}

      {/* 4. ADMIN REVIEW PANEL */}
      {isAdmin && activeTab === 'review' && (
        <div className="space-y-6">
          <div className="bg-indigo-50 border border-indigo-100 rounded-2xl p-5 flex items-start space-x-3">
            <ShieldCheck className="w-5 h-5 text-indigo-600 shrink-0 mt-0.5" />
            <div className="space-y-1">
              <h3 className="text-sm font-bold text-indigo-900">Administrator Evaluation & Review Center</h3>
              <p className="text-xs text-indigo-700 leading-relaxed">
                Review and evaluate pending project submissions across all academic departments.
              </p>
            </div>
          </div>

          {filteredReviewProjects.length === 0 ? (
            <div className="py-12 text-center bg-white rounded-2xl border border-slate-200 p-8 space-y-2">
              <CheckCircle2 className="w-12 h-12 text-emerald-400 mx-auto" />
              <h3 className="text-lg font-bold text-slate-800">All Clear! No Pending Reviews</h3>
              <p className="text-sm text-slate-500">There are currently no projects awaiting evaluation.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {filteredReviewProjects.map((project) => (
                <div
                  key={project.id}
                  onClick={() => setSelectedProjectId(project.id)}
                  className="bg-white rounded-2xl border border-slate-200 p-6 hover:shadow-lg transition-all flex flex-col justify-between cursor-pointer space-y-4"
                >
                  <div className="space-y-2">
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-semibold text-indigo-600 bg-indigo-50 px-2.5 py-0.5 rounded-md">
                        {project.departmentName}
                      </span>
                      {getStatusBadge(project.status)}
                    </div>
                    <h3 className="text-lg font-bold text-slate-900">{project.title}</h3>
                    <p className="text-sm text-slate-600 line-clamp-3 leading-relaxed">{project.abstractText}</p>
                  </div>

                  <div className="pt-3 border-t border-slate-100 flex flex-wrap items-center justify-between gap-2 text-xs">
                    <div className="space-y-1">
                      <div className="font-semibold text-slate-700 flex items-center gap-1.5">
                        <span>Author: {project.createdByUserName}</span>
                        {project.createdByRollNo && (
                          <span className="text-[11px] font-mono px-1.5 py-0.2 bg-slate-100 text-slate-600 border border-slate-200 rounded">
                            {project.createdByRollNo}
                          </span>
                        )}
                      </div>
                      <div className="text-emerald-700 font-bold flex items-center gap-1.5">
                        <span>Guide: {formatFacultyName(project.guideFacultyName)}</span>
                      </div>
                    </div>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        setSelectedProjectId(project.id);
                      }}
                      className="px-3 py-1.5 rounded-lg bg-indigo-600 text-white font-semibold hover:bg-indigo-700 transition-colors"
                    >
                      Evaluate Submission
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* Modals */}
      <CreateProjectModal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        onSuccess={() => fetchProjects()}
      />

      <ProjectDetailModal
        projectId={selectedProjectId}
        isOpen={!!selectedProjectId}
        onClose={() => setSelectedProjectId(null)}
        onUpdate={() => fetchProjects()}
      />
    </div>
  );
};
