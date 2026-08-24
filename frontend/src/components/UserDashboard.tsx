import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { ProjectSummary, Department, ProjectStatus, ApiResponse, PageResponse } from '../types';
import api from '../api/client';
import { CreateProjectModal } from './CreateProjectModal';
import { ProjectDetailModal } from './ProjectDetailModal';
import { 
  Plus, 
  Search, 
  FolderGit2, 
  Calendar, 
  User as UserIcon, 
  Sparkles, 
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

  // All projects fetched from server
  const [allProjects, setAllProjects] = useState<ProjectSummary[]>([]);
  const [departments, setDepartments] = useState<Department[]>([]);

  // Active Tab: 'my-projects' | 'catalog' | 'review'
  const [activeTab, setActiveTab] = useState<'my-projects' | 'catalog' | 'review'>(
    user?.role === 'FACULTY' ? 'review' : user?.role === 'ADMIN' ? 'catalog' : 'my-projects'
  );

  // Filter state for catalog tab
  const [selectedDept, setSelectedDept] = useState<string>('');
  const [selectedStatus, setSelectedStatus] = useState<string>('');
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [page, setPage] = useState<number>(0);
  const [totalPages, setTotalPages] = useState<number>(1);
  const [totalElements, setTotalElements] = useState<number>(0);

  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isRefreshing, setIsRefreshing] = useState<boolean>(false);
  const [isCreateOpen, setIsCreateOpen] = useState<boolean>(false);
  const [selectedProjectId, setSelectedProjectId] = useState<number | null>(null);
  const [systemUsers, setSystemUsers] = useState<any[]>([]);

  useEffect(() => {
    fetchDepartments();
    fetchProjects();
    if (user?.role === 'ADMIN') {
      fetchSystemUsers();
    }
    if (user?.role === 'FACULTY') {
      setActiveTab('review');
    } else if (user?.role === 'ADMIN') {
      setActiveTab('catalog');
    } else if (user?.role === 'STUDENT') {
      setActiveTab('my-projects');
    }
  }, [page, selectedDept, selectedStatus, user?.id, user?.role]);

  const fetchSystemUsers = async () => {
    try {
      const res = await api.get<ApiResponse<PageResponse<any>>>('/users?size=100');
      if (res.data && res.data.data && res.data.data.content) {
        setSystemUsers(res.data.data.content);
      }
    } catch (err) {
      console.error('Failed to fetch system users:', err);
    }
  };

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

  const isStudent = user?.role === 'STUDENT';
  const isFaculty = user?.role === 'FACULTY';
  const isStaff = isFaculty || user?.role === 'ADMIN';
  const isAdmin = user?.role === 'ADMIN';

  // Filter projects created by current user
  const myProjects = allProjects.filter(p => user && p.createdByUserId === user.id);

  // Stats calculation for current user
  const myApprovedCount = myProjects.filter(p => p.status === 'APPROVED').length;
  const myPendingCount = myProjects.filter(p => p.status === 'SUBMITTED' || p.status === 'UNDER_REVIEW').length;
  const myDraftCount = myProjects.filter(p => p.status === 'DRAFT').length;

  // Projects pending review for faculty/admin (filtered by designated guide for faculty)
  const pendingReviewProjects = allProjects.filter(p => {
    const isPending = p.status === 'SUBMITTED' || p.status === 'UNDER_REVIEW';
    if (!isPending) return false;
    if (isAdmin) return true;
    if (isFaculty) {
      return !p.guideFacultyId || p.guideFacultyId === user?.id;
    }
    return false;
  });

  // Filtered view for catalog
  const filteredCatalogProjects = allProjects.filter((p) => {
    // Hide non-approved projects of other peers/students in catalog unless owned or guided by faculty
    if (!isAdmin && p.status !== 'APPROVED') {
      const isMine = user && p.createdByUserId === user.id;
      const isMyGuided = isFaculty && user && p.guideFacultyId === user.id;
      if (!isMine && !isMyGuided) return false;
    }
    if (!searchTerm) return true;
    const term = searchTerm.toLowerCase();
    const author = p.createdByUserName || p.createdByFullName || '';
    return (
      p.title.toLowerCase().includes(term) ||
      (p.abstractText || '').toLowerCase().includes(term) ||
      author.toLowerCase().includes(term)
    );
  });

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

  // Role-aware Stats calculation for top cards
  const totalSubmissionsCount = isStaff ? (totalElements || allProjects.length) : myProjects.length;
  const approvedCount = isStaff ? allProjects.filter(p => p.status === 'APPROVED').length : myApprovedCount;
  const pendingReviewCount = isStaff ? allProjects.filter(p => p.status === 'SUBMITTED' || p.status === 'UNDER_REVIEW').length : myPendingCount;
  const draftCount = isStaff ? allProjects.filter(p => p.status === 'DRAFT').length : myDraftCount;

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">
      {/* Personalized Welcome Banner */}
      <div className="bg-gradient-to-r from-indigo-700 via-indigo-800 to-slate-900 rounded-3xl p-6 sm:p-8 text-white shadow-xl relative overflow-hidden">
        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div className="space-y-3 max-w-2xl">
            <div className="flex flex-wrap items-center gap-2">
              <span className="inline-flex items-center space-x-1 bg-indigo-500/30 backdrop-blur-md px-3 py-1 rounded-full text-xs font-bold border border-indigo-400/30 text-indigo-100">
                <Sparkles className="w-3.5 h-3.5 text-amber-300" />
                <span>Personalized Academic Dashboard</span>
              </span>
              {user?.role && (
                <span className="px-2.5 py-0.5 rounded-full text-xs font-extrabold bg-white/20 text-white border border-white/20 uppercase tracking-wider">
                  {user.role}
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
              Welcome back, {user?.firstName} {user?.lastName}!
            </h1>

            <p className="text-indigo-100 text-sm sm:text-base leading-relaxed">
              {isAdmin
                ? 'System Administrator Control Center. Manage students, staff, department data, and oversee all project submissions.'
                : user?.role === 'FACULTY'
                ? `Faculty Evaluator Hub. Review student capstones, evaluate submissions, and guide department research.`
                : user?.departmentName
                ? `Affiliation: ${user.departmentName}`
                : 'Manage your research submissions, project drafts, and department repositories.'}
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

      {/* User Usage & Statistics Cards - ONLY FOR STUDENTS */}
      {isStudent && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {/* Total Submissions */}
          <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-xs font-bold uppercase tracking-wider text-slate-400">Total Submissions</span>
              <div className="text-2xl font-extrabold text-slate-900">{totalSubmissionsCount}</div>
              <span className="text-xs text-slate-500 font-medium">Created by you</span>
            </div>
            <div className="w-12 h-12 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center font-bold">
              <FolderOpen className="w-6 h-6" />
            </div>
          </div>

          {/* Approved Submissions */}
          <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-xs font-bold uppercase tracking-wider text-emerald-600">Approved Projects</span>
              <div className="text-2xl font-extrabold text-emerald-700">{approvedCount}</div>
              <span className="text-xs text-slate-500 font-medium">Publicly published</span>
            </div>
            <div className="w-12 h-12 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center font-bold">
              <CheckCircle2 className="w-6 h-6" />
            </div>
          </div>

          {/* Pending Review */}
          <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-xs font-bold uppercase tracking-wider text-sky-600">Under Review</span>
              <div className="text-2xl font-extrabold text-sky-700">{pendingReviewCount}</div>
              <span className="text-xs text-slate-500 font-medium">Awaiting evaluation</span>
            </div>
            <div className="w-12 h-12 rounded-2xl bg-sky-50 text-sky-600 flex items-center justify-center font-bold">
              <Clock className="w-6 h-6" />
            </div>
          </div>

          {/* Draft Entries */}
          <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-xs font-bold uppercase tracking-wider text-amber-600">Draft Entries</span>
              <div className="text-2xl font-extrabold text-amber-700">{draftCount}</div>
              <span className="text-xs text-slate-500 font-medium">In preparation</span>
            </div>
            <div className="w-12 h-12 rounded-2xl bg-amber-50 text-amber-600 flex items-center justify-center font-bold">
              <FileEdit className="w-6 h-6" />
            </div>
          </div>
        </div>
      )}

      {/* Main Navigation Tabs */}
      <div className="border-b border-slate-200 flex items-center justify-between">
        <div className="flex space-x-2">
          {isStudent && (
            <button
              onClick={() => setActiveTab('my-projects')}
              className={`flex items-center space-x-2 py-3 px-4 text-sm font-bold border-b-2 transition-all ${
                activeTab === 'my-projects'
                  ? 'border-indigo-600 text-indigo-600'
                  : 'border-transparent text-slate-500 hover:text-slate-800'
              }`}
            >
              <UserIcon className="w-4 h-4" />
              <span>My Projects & Usage ({myProjects.length})</span>
            </button>
          )}

          {isStaff && (
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
          )}

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
        </div>
      </div>

      {/* TAB CONTENT 1: MY PROJECTS & PERSONAL USAGE (STUDENT ONLY) */}
      {activeTab === 'my-projects' && isStudent && (
        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <h2 className="text-xl font-bold text-slate-900">
              {isAdmin ? 'System Project Submissions' : 'Your Project Submissions'}
            </h2>
            {!isAdmin && (
              <button
                onClick={() => setIsCreateOpen(true)}
                className="inline-flex items-center space-x-1.5 px-3.5 py-2 rounded-xl bg-indigo-600 text-white font-semibold text-xs hover:bg-indigo-700 transition-colors shadow-sm"
              >
                <Plus className="w-3.5 h-3.5" />
                <span>Create Project Draft</span>
              </button>
            )}
          </div>

          {isLoading ? (
            <div className="py-12 text-center text-slate-400 font-medium">Loading your projects...</div>
          ) : myProjects.length === 0 ? (
            <div className="py-12 text-center bg-white rounded-2xl border border-slate-200 p-8 space-y-4">
              <FolderGit2 className="w-12 h-12 text-indigo-200 mx-auto" />
              <div className="space-y-1">
                <h3 className="text-lg font-bold text-slate-800">
                  {isAdmin ? 'Admin Management Center Active' : 'No Projects Created Yet'}
                </h3>
                <p className="text-sm text-slate-500 max-w-md mx-auto">
                  {isAdmin
                    ? 'You are logged in as System Administrator. Use the tabs above to manage users, evaluate pending project submissions, or view all repository catalog entries.'
                    : 'You have not created any academic project drafts. Click below to submit your capstone or research paper.'}
                </p>
              </div>
              {!isAdmin && (
                <button
                  onClick={() => setIsCreateOpen(true)}
                  className="inline-flex items-center space-x-2 px-5 py-2.5 rounded-xl bg-indigo-600 text-white font-bold text-sm hover:bg-indigo-700 transition-colors shadow-md"
                >
                  <Plus className="w-4 h-4" />
                  <span>Create Your First Project</span>
                </button>
              )}

              {isAdmin && systemUsers.length > 0 && (
                <div className="text-left space-y-4 pt-4 border-t border-slate-100">
                  <div className="flex items-center justify-between">
                    <h4 className="text-xs font-bold uppercase tracking-wider text-slate-700">Official System Accounts Roster ({systemUsers.length} Users)</h4>
                    <Link to="/users" className="text-xs font-bold text-indigo-600 hover:underline">Manage All Accounts &rarr;</Link>
                  </div>
                  <div className="overflow-x-auto rounded-xl border border-slate-200 bg-slate-50/50">
                    <table className="w-full text-xs text-slate-700">
                      <thead className="bg-slate-100/80 text-slate-500 font-bold uppercase tracking-wider">
                        <tr>
                          <th className="p-2.5 text-left">Email Address</th>
                          <th className="p-2.5 text-left">Full Name</th>
                          <th className="p-2.5 text-left">Role</th>
                          <th className="p-2.5 text-left">Status</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-200 font-medium">
                        {systemUsers.map((u) => (
                          <tr key={u.id} className="hover:bg-white transition-colors">
                            <td className="p-2.5 font-bold text-slate-900">{u.email}</td>
                            <td className="p-2.5">{u.firstName} {u.lastName}</td>
                            <td className="p-2.5">
                              <span className={`px-2 py-0.5 rounded-md font-bold text-[10px] ${
                                u.role === 'ADMIN' ? 'bg-purple-100 text-purple-700' :
                                u.role === 'FACULTY' ? 'bg-indigo-100 text-indigo-700' : 'bg-emerald-100 text-emerald-700'
                              }`}>
                                {u.role}
                              </span>
                            </td>
                            <td className="p-2.5">
                              <span className="text-emerald-600 font-semibold">{u.userStatus || 'ACTIVE'}</span>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {myProjects.map((project) => (
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

      {/* TAB CONTENT 2: GLOBAL REPOSITORY CATALOG */}
      {activeTab === 'catalog' && (
        <div className="space-y-6">
          {/* Search and Filters */}
          <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200 space-y-4">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
              {/* Search bar */}
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

              {/* Department Dropdown */}
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
            <div className="flex items-center space-x-1 overflow-x-auto pb-1 border-t border-slate-100 pt-3">
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

                  <div className="pt-4 mt-4 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500 font-medium">
                    <div className="flex items-center space-x-1.5">
                      <UserIcon className="w-3.5 h-3.5 text-slate-400" />
                      <span>{project.createdByUserName || project.createdByFullName || 'Contributor'}</span>
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

      {/* TAB CONTENT 3: FACULTY / ADMIN REVIEW PANEL */}
      {activeTab === 'review' && isStaff && (
        <div className="space-y-6">
          <div className="bg-indigo-50 border border-indigo-100 rounded-2xl p-5 flex items-start space-x-3">
            <ShieldCheck className="w-5 h-5 text-indigo-600 shrink-0 mt-0.5" />
            <div className="space-y-1">
              <h3 className="text-sm font-bold text-indigo-900">Faculty Review Center</h3>
              <p className="text-xs text-indigo-700 leading-relaxed">
                Review pending project submissions across academic departments. Evaluate project abstracts, check repository links, and transition status to Approved or Rejected.
              </p>
            </div>
          </div>

          {pendingReviewProjects.length === 0 ? (
            <div className="py-12 text-center bg-white rounded-2xl border border-slate-200 p-8 space-y-2">
              <CheckCircle2 className="w-12 h-12 text-emerald-400 mx-auto" />
              <h3 className="text-lg font-bold text-slate-800">All Clear! No Pending Reviews</h3>
              <p className="text-sm text-slate-500">There are currently no projects awaiting faculty review or evaluation.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {pendingReviewProjects.map((project) => (
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
                    <div>
                      <div className="font-semibold text-slate-700">Author: {project.createdByUserName || project.createdByFullName}</div>
                      <div className="text-indigo-600 font-bold">Guide: {project.guideFacultyName || 'Prof. Geetha (Faculty Guide)'}</div>
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
