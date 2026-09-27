import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { ProjectSummary, ProjectStatus, ApiResponse, PageResponse } from '../types';
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
  CheckCircle2, 
  Clock, 
  FileEdit, 
  ShieldCheck, 
  RefreshCw, 
  Send, 
  Eye, 
  FolderOpen, 
  Users,
  Award
} from 'lucide-react';

export const UserDashboard: React.FC = () => {
  const { user, refreshProfile } = useAuth();

  // All projects fetched from server
  const [allProjects, setAllProjects] = useState<ProjectSummary[]>([]);

  // Active Tab state initialized by role
  const isStudent = user?.role === 'STUDENT';
  const isFaculty = user?.role === 'FACULTY';
  const isAdmin = user?.role === 'ADMIN';

  const [activeTab, setActiveTab] = useState<'my-projects' | 'review' | 'approved' | 'guided' | 'catalog'>(
    user?.role === 'FACULTY' ? 'review' : user?.role === 'ADMIN' ? 'catalog' : 'my-projects'
  );

  // Status Filter state
  const [selectedStatus, setSelectedStatus] = useState<string>('');
  const [searchTerm, setSearchTerm] = useState<string>('');

  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isRefreshing, setIsRefreshing] = useState<boolean>(false);
  const [isCreateOpen, setIsCreateOpen] = useState<boolean>(false);
  const [selectedProjectId, setSelectedProjectId] = useState<number | null>(null);

  // Sync default tab when user profile loads initially
  useEffect(() => {
    if (user?.role === 'FACULTY') {
      setActiveTab('review');
    } else if (user?.role === 'ADMIN') {
      setActiveTab('catalog');
    } else if (user?.role === 'STUDENT') {
      setActiveTab('my-projects');
    }
  }, [user?.role]);

  useEffect(() => {
    fetchProjects();
  }, [user?.id, user?.role]);

  const fetchProjects = async () => {
    setIsLoading(true);
    try {
      // Fetch department projects for MCA (dept 1)
      const url = `/projects?page=0&size=100`;
      const res = await api.get<ApiResponse<PageResponse<ProjectSummary>>>(url);
      if (res.data && res.data.data) {
        setAllProjects(res.data.data.content || []);
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

  // 1. Projects created by Student
  const myProjects = allProjects.filter(p => user && p.createdByUserId === user.id);
  const filteredMyProjects = myProjects.filter((p) => {
    if (selectedStatus && p.status !== selectedStatus) return false;
    if (!searchTerm) return true;
    const term = searchTerm.toLowerCase();
    return p.title.toLowerCase().includes(term) || (p.abstractText || '').toLowerCase().includes(term);
  });

  // 2. Faculty: Projects pending review (SUBMITTED / UNDER_REVIEW assigned to them or unassigned)
  const pendingReviewProjects = allProjects.filter(p => {
    const isPending = p.status === 'SUBMITTED' || p.status === 'UNDER_REVIEW';
    if (!isPending) return false;
    if (isAdmin) return true;
    if (isFaculty) {
      return !p.guideFacultyId || p.guideFacultyId === user?.id;
    }
    return false;
  }).filter(p => {
    if (!searchTerm) return true;
    const term = searchTerm.toLowerCase();
    return p.title.toLowerCase().includes(term) || (p.createdByUserName || '').toLowerCase().includes(term);
  });

  // 3. Faculty: Approved Projects under their guidance
  const facultyApprovedProjects = allProjects.filter(p => {
    if (isAdmin) return p.status === 'APPROVED';
    if (isFaculty) {
      return p.status === 'APPROVED' && (!p.guideFacultyId || p.guideFacultyId === user?.id);
    }
    return false;
  }).filter(p => {
    if (!searchTerm) return true;
    const term = searchTerm.toLowerCase();
    return p.title.toLowerCase().includes(term) || (p.createdByUserName || '').toLowerCase().includes(term);
  });

  // 4. Faculty: All projects under their guidance (Drafts, Submitted, Under Review, Approved, Rejected)
  const facultyGuidedProjects = allProjects.filter(p => {
    if (isAdmin) return true;
    if (isFaculty) {
      return !p.guideFacultyId || p.guideFacultyId === user?.id;
    }
    return false;
  }).filter(p => {
    if (selectedStatus && p.status !== selectedStatus) return false;
    if (!searchTerm) return true;
    const term = searchTerm.toLowerCase();
    return p.title.toLowerCase().includes(term) || (p.createdByUserName || '').toLowerCase().includes(term);
  });

  // 5. Admin Catalog Filtered Projects
  const filteredCatalogProjects = allProjects.filter((p) => {
    if (selectedStatus && p.status !== selectedStatus) return false;
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
              <span className="px-2.5 py-0.5 rounded-full text-xs font-extrabold bg-emerald-500/30 text-emerald-200 border border-emerald-400/30 uppercase tracking-wider">
                Department of Computer Applications (MCA)
              </span>
            </div>

            <h1 className="text-2xl sm:text-4xl font-extrabold tracking-tight">
              Welcome back, {formatUserNameByRole(user?.name || user?.email?.split('@')[0], user?.role)}!
            </h1>

            <p className="text-indigo-100 text-sm sm:text-base leading-relaxed">
              {isAdmin
                ? 'System Administrator Hub. Oversee student submissions, faculty reviews, and system accounts.'
                : isFaculty
                ? `Faculty Evaluator Hub. Review student capstones, evaluate submissions, and guide MCA research projects.`
                : 'Student Capstone Portal. Manage your research submissions, track review status, and prepare project deliverables.'}
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
                <span>Manage Users & Roster</span>
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

      {/* STUDENT STATS CARDS */}
      {isStudent && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-xs font-bold uppercase tracking-wider text-slate-400">Total Submissions</span>
              <div className="text-2xl font-extrabold text-slate-900">{myProjects.length}</div>
              <span className="text-xs text-slate-500 font-medium">Your MCA Projects</span>
            </div>
            <div className="w-12 h-12 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center font-bold">
              <FolderOpen className="w-6 h-6" />
            </div>
          </div>

          <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-xs font-bold uppercase tracking-wider text-emerald-600">Approved</span>
              <div className="text-2xl font-extrabold text-emerald-700">
                {myProjects.filter(p => p.status === 'APPROVED').length}
              </div>
              <span className="text-xs text-slate-500 font-medium">Published in archive</span>
            </div>
            <div className="w-12 h-12 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center font-bold">
              <CheckCircle2 className="w-6 h-6" />
            </div>
          </div>

          <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-xs font-bold uppercase tracking-wider text-sky-600">Under Review</span>
              <div className="text-2xl font-extrabold text-sky-700">
                {myProjects.filter(p => p.status === 'SUBMITTED' || p.status === 'UNDER_REVIEW').length}
              </div>
              <span className="text-xs text-slate-500 font-medium">Awaiting evaluation</span>
            </div>
            <div className="w-12 h-12 rounded-2xl bg-sky-50 text-sky-600 flex items-center justify-center font-bold">
              <Clock className="w-6 h-6" />
            </div>
          </div>

          <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-xs font-bold uppercase tracking-wider text-amber-600">Drafts</span>
              <div className="text-2xl font-extrabold text-amber-700">
                {myProjects.filter(p => p.status === 'DRAFT').length}
              </div>
              <span className="text-xs text-slate-500 font-medium">In preparation</span>
            </div>
            <div className="w-12 h-12 rounded-2xl bg-amber-50 text-amber-600 flex items-center justify-center font-bold">
              <FileEdit className="w-6 h-6" />
            </div>
          </div>
        </div>
      )}

      {/* FACULTY STATS CARDS */}
      {isFaculty && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-xs font-bold uppercase tracking-wider text-indigo-600">Pending Evaluation</span>
              <div className="text-2xl font-extrabold text-indigo-700">{pendingReviewProjects.length}</div>
              <span className="text-xs text-slate-500 font-medium">Requires review action</span>
            </div>
            <div className="w-12 h-12 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center font-bold">
              <ShieldCheck className="w-6 h-6" />
            </div>
          </div>

          <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-xs font-bold uppercase tracking-wider text-emerald-600">Approved Projects</span>
              <div className="text-2xl font-extrabold text-emerald-700">{facultyApprovedProjects.length}</div>
              <span className="text-xs text-slate-500 font-medium">Under your guidance</span>
            </div>
            <div className="w-12 h-12 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center font-bold">
              <CheckCircle2 className="w-6 h-6" />
            </div>
          </div>

          <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-xs font-bold uppercase tracking-wider text-slate-600">Total Guided</span>
              <div className="text-2xl font-extrabold text-slate-900">{facultyGuidedProjects.length}</div>
              <span className="text-xs text-slate-500 font-medium">All lifecycle stages</span>
            </div>
            <div className="w-12 h-12 rounded-2xl bg-slate-100 text-slate-700 flex items-center justify-center font-bold">
              <FolderGit2 className="w-6 h-6" />
            </div>
          </div>

          <div className="bg-white rounded-2xl p-5 border border-slate-200 shadow-sm flex items-center justify-between">
            <div className="space-y-1">
              <span className="text-xs font-bold uppercase tracking-wider text-amber-600">Drafts / In Progress</span>
              <div className="text-2xl font-extrabold text-amber-700">
                {facultyGuidedProjects.filter(p => p.status === 'DRAFT').length}
              </div>
              <span className="text-xs text-slate-500 font-medium">Student drafts</span>
            </div>
            <div className="w-12 h-12 rounded-2xl bg-amber-50 text-amber-600 flex items-center justify-center font-bold">
              <Clock className="w-6 h-6" />
            </div>
          </div>
        </div>
      )}

      {/* NAVIGATION TABS BY ROLE */}
      <div className="border-b border-slate-200 flex items-center justify-between">
        <div className="flex space-x-2">
          {/* Student Tabs */}
          {isStudent && (
            <button
              onClick={() => {
                setActiveTab('my-projects');
                setSelectedStatus('');
              }}
              className={`flex items-center space-x-2 py-3 px-4 text-sm font-bold border-b-2 transition-all ${
                activeTab === 'my-projects'
                  ? 'border-indigo-600 text-indigo-600'
                  : 'border-transparent text-slate-500 hover:text-slate-800'
              }`}
            >
              <UserIcon className="w-4 h-4" />
              <span>My Project Submissions ({myProjects.length})</span>
            </button>
          )}

          {/* Faculty Tabs */}
          {isFaculty && (
            <>
              <button
                onClick={() => {
                  setActiveTab('review');
                  setSelectedStatus('');
                }}
                className={`flex items-center space-x-2 py-3 px-4 text-sm font-bold border-b-2 transition-all ${
                  activeTab === 'review'
                    ? 'border-indigo-600 text-indigo-600'
                    : 'border-transparent text-slate-500 hover:text-slate-800'
                }`}
              >
                <ShieldCheck className="w-4 h-4" />
                <span>Pending Review ({pendingReviewProjects.length})</span>
              </button>

              <button
                onClick={() => {
                  setActiveTab('approved');
                  setSelectedStatus('');
                }}
                className={`flex items-center space-x-2 py-3 px-4 text-sm font-bold border-b-2 transition-all ${
                  activeTab === 'approved'
                    ? 'border-indigo-600 text-indigo-600'
                    : 'border-transparent text-slate-500 hover:text-slate-800'
                }`}
              >
                <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                <span>Approved Projects ({facultyApprovedProjects.length})</span>
              </button>

              <button
                onClick={() => {
                  setActiveTab('guided');
                  setSelectedStatus('');
                }}
                className={`flex items-center space-x-2 py-3 px-4 text-sm font-bold border-b-2 transition-all ${
                  activeTab === 'guided'
                    ? 'border-indigo-600 text-indigo-600'
                    : 'border-transparent text-slate-500 hover:text-slate-800'
                }`}
              >
                <FolderGit2 className="w-4 h-4" />
                <span>All Guided Submissions ({facultyGuidedProjects.length})</span>
              </button>
            </>
          )}

          {/* Admin Tabs */}
          {isAdmin && (
            <>
              <button
                onClick={() => {
                  setActiveTab('catalog');
                  setSelectedStatus('');
                }}
                className={`flex items-center space-x-2 py-3 px-4 text-sm font-bold border-b-2 transition-all ${
                  activeTab === 'catalog'
                    ? 'border-indigo-600 text-indigo-600'
                    : 'border-transparent text-slate-500 hover:text-slate-800'
                }`}
              >
                <FolderGit2 className="w-4 h-4" />
                <span>All MCA Projects ({allProjects.length})</span>
              </button>

              <button
                onClick={() => {
                  setActiveTab('review');
                  setSelectedStatus('');
                }}
                className={`flex items-center space-x-2 py-3 px-4 text-sm font-bold border-b-2 transition-all ${
                  activeTab === 'review'
                    ? 'border-indigo-600 text-indigo-600'
                    : 'border-transparent text-slate-500 hover:text-slate-800'
                }`}
              >
                <ShieldCheck className="w-4 h-4" />
                <span>Pending Review Queue ({pendingReviewProjects.length})</span>
              </button>
            </>
          )}
        </div>
      </div>

      {/* ======================================================== */}
      {/* 1. STUDENT VIEW: MY PROJECTS ONLY */}
      {/* ======================================================== */}
      {isStudent && activeTab === 'my-projects' && (
        <div className="space-y-6">
          <div className="bg-white p-4 rounded-2xl shadow-sm border border-slate-200 space-y-3">
            <div className="flex flex-col sm:flex-row items-center justify-between gap-3">
              <div className="relative flex-1 w-full">
                <Search className="w-4 h-4 absolute left-3.5 top-3 text-slate-400" />
                <input
                  type="text"
                  placeholder="Filter your submissions by title..."
                  className="w-full pl-10 pr-4 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                />
              </div>

              {/* Status Filter Buttons */}
              <div className="flex items-center space-x-1 overflow-x-auto w-full sm:w-auto pb-1 sm:pb-0">
                {[
                  { label: 'All', value: '' },
                  { label: 'Approved', value: 'APPROVED' },
                  { label: 'Under Review', value: 'UNDER_REVIEW' },
                  { label: 'Submitted', value: 'SUBMITTED' },
                  { label: 'Drafts', value: 'DRAFT' },
                  { label: 'Rejected', value: 'REJECTED' },
                ].map((tab) => (
                  <button
                    key={tab.value}
                    onClick={() => setSelectedStatus(tab.value)}
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
          </div>

          {isLoading ? (
            <div className="py-12 text-center text-slate-400 font-medium">Loading your projects...</div>
          ) : filteredMyProjects.length === 0 ? (
            <div className="py-12 text-center bg-white rounded-2xl border border-slate-200 p-8 space-y-4">
              <FolderGit2 className="w-12 h-12 text-indigo-200 mx-auto" />
              <h3 className="text-lg font-bold text-slate-800">No Projects Found</h3>
              <p className="text-sm text-slate-500 max-w-md mx-auto">
                {myProjects.length === 0
                  ? "You haven't submitted any projects yet. Click 'Submit New Project' to get started."
                  : "No submissions match your current filter."}
              </p>
              {myProjects.length === 0 && (
                <button
                  onClick={() => setIsCreateOpen(true)}
                  className="inline-flex items-center space-x-2 px-5 py-2.5 rounded-xl bg-indigo-600 text-white font-bold text-sm hover:bg-indigo-700 transition-colors shadow-md"
                >
                  <Plus className="w-4 h-4" />
                  <span>Submit New Project</span>
                </button>
              )}
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {filteredMyProjects.map((project) => (
                <div
                  key={project.id}
                  onClick={() => setSelectedProjectId(project.id)}
                  className="bg-white rounded-2xl border border-slate-200 p-6 hover:shadow-lg transition-all duration-200 flex flex-col justify-between cursor-pointer group"
                >
                  <div className="space-y-3">
                    <div className="flex items-center justify-between gap-2">
                      <span className="text-xs font-semibold text-indigo-600 bg-indigo-50 px-2.5 py-0.5 rounded-md">
                        MCA Department
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

      {/* ======================================================== */}
      {/* 2. FACULTY / ADMIN VIEW: PENDING REVIEW TAB */}
      {/* ======================================================== */}
      {(isFaculty || isAdmin) && activeTab === 'review' && (
        <div className="space-y-6">
          <div className="bg-indigo-50 border border-indigo-100 rounded-2xl p-5 flex items-start space-x-3">
            <ShieldCheck className="w-5 h-5 text-indigo-600 shrink-0 mt-0.5" />
            <div className="space-y-1">
              <h3 className="text-sm font-bold text-indigo-900">Faculty Review & Integrity Assessment</h3>
              <p className="text-xs text-indigo-700 leading-relaxed">
                Review student draft submissions and evaluate originality scores before approving or rejecting projects.
              </p>
            </div>
          </div>

          {/* Search bar */}
          <div className="bg-white p-4 rounded-2xl shadow-sm border border-slate-200">
            <div className="relative">
              <Search className="w-4 h-4 absolute left-3.5 top-3 text-slate-400" />
              <input
                type="text"
                placeholder="Search pending submissions by title or student name..."
                className="w-full pl-10 pr-4 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
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
                        MCA Department
                      </span>
                      {getStatusBadge(project.status)}
                    </div>
                    <h3 className="text-lg font-bold text-slate-900">{project.title}</h3>
                    <p className="text-sm text-slate-600 line-clamp-3 leading-relaxed">{project.abstractText}</p>

                    {/* Plagiarism and duplication scores visible to faculty in review mode */}
                    {(project.plagiarismScore !== undefined && project.plagiarismScore !== null || project.duplicationScore !== undefined && project.duplicationScore !== null) && (
                      <div className="flex flex-wrap gap-1.5 pt-1">
                        {project.plagiarismScore !== undefined && project.plagiarismScore !== null && (
                          <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${
                            project.plagiarismScore < 20 ? 'bg-emerald-50 text-emerald-700 border-emerald-200' :
                            project.plagiarismScore <= 50 ? 'bg-amber-50 text-amber-700 border-amber-200' :
                            'bg-rose-50 text-rose-700 border-rose-200'
                          }`}>
                            Plagiarism: {project.plagiarismScore.toFixed(1)}%
                          </span>
                        )}
                        {project.duplicationScore !== undefined && project.duplicationScore !== null && (
                          <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${
                            project.duplicationScore < 40 ? 'bg-blue-50 text-blue-700 border-blue-200' :
                            project.duplicationScore < 75 ? 'bg-amber-50 text-amber-700 border-amber-200' :
                            'bg-rose-50 text-rose-700 border-rose-200'
                          }`}>
                            Duplication: {project.duplicationScore.toFixed(1)}%
                          </span>
                        )}
                      </div>
                    )}
                  </div>

                  <div className="pt-3 border-t border-slate-100 flex flex-wrap items-center justify-between gap-2 text-xs">
                    <div className="space-y-1">
                      <div className="font-semibold text-slate-700 flex items-center gap-1.5">
                        <span>Student: {project.createdByUserName}</span>
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
                      className="px-3.5 py-2 rounded-xl bg-indigo-600 text-white font-semibold hover:bg-indigo-700 transition-colors shadow-sm"
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

      {/* ======================================================== */}
      {/* 3. FACULTY VIEW: APPROVED PROJECTS UNDER GUIDANCE */}
      {/* ======================================================== */}
      {isFaculty && activeTab === 'approved' && (
        <div className="space-y-6">
          <div className="bg-emerald-50 border border-emerald-100 rounded-2xl p-5 flex items-start space-x-3">
            <Award className="w-5 h-5 text-emerald-600 shrink-0 mt-0.5" />
            <div className="space-y-1">
              <h3 className="text-sm font-bold text-emerald-900">Approved Projects Under Your Guidance</h3>
              <p className="text-xs text-emerald-700 leading-relaxed">
                Completed and approved student capstone projects published in the official university repository.
              </p>
            </div>
          </div>

          <div className="bg-white p-4 rounded-2xl shadow-sm border border-slate-200">
            <div className="relative">
              <Search className="w-4 h-4 absolute left-3.5 top-3 text-slate-400" />
              <input
                type="text"
                placeholder="Search approved projects by title or student name..."
                className="w-full pl-10 pr-4 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>

          {facultyApprovedProjects.length === 0 ? (
            <div className="py-12 text-center bg-white rounded-2xl border border-slate-200 p-8 space-y-2">
              <FolderGit2 className="w-12 h-12 text-slate-300 mx-auto" />
              <h3 className="text-lg font-bold text-slate-800">No Approved Projects Found</h3>
              <p className="text-sm text-slate-500">There are currently no approved projects matching this criteria.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {facultyApprovedProjects.map((project) => (
                <div
                  key={project.id}
                  onClick={() => setSelectedProjectId(project.id)}
                  className="bg-white rounded-2xl border border-slate-200 p-6 hover:shadow-lg transition-all flex flex-col justify-between cursor-pointer group"
                >
                  <div className="space-y-3">
                    <div className="flex items-center justify-between gap-2">
                      <span className="text-xs font-semibold text-indigo-600 bg-indigo-50 px-2.5 py-0.5 rounded-md">
                        MCA Department
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
                      <span className="font-semibold text-slate-700">{project.createdByUserName || 'Student'}</span>
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
        </div>
      )}

      {/* ======================================================== */}
      {/* 4. FACULTY VIEW: ALL GUIDED SUBMISSIONS (WITH STATUS FILTERS) */}
      {/* ======================================================== */}
      {isFaculty && activeTab === 'guided' && (
        <div className="space-y-6">
          <div className="bg-white p-4 rounded-2xl shadow-sm border border-slate-200 space-y-3">
            <div className="flex flex-col sm:flex-row items-center justify-between gap-3">
              <div className="relative flex-1 w-full">
                <Search className="w-4 h-4 absolute left-3.5 top-3 text-slate-400" />
                <input
                  type="text"
                  placeholder="Search guided submissions by title or student..."
                  className="w-full pl-10 pr-4 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                />
              </div>

              {/* Status Filter Buttons */}
              <div className="flex items-center space-x-1 overflow-x-auto w-full sm:w-auto pb-1 sm:pb-0">
                {[
                  { label: 'All Guided', value: '' },
                  { label: 'Approved', value: 'APPROVED' },
                  { label: 'Under Review', value: 'UNDER_REVIEW' },
                  { label: 'Submitted', value: 'SUBMITTED' },
                  { label: 'Drafts', value: 'DRAFT' },
                  { label: 'Rejected', value: 'REJECTED' },
                ].map((tab) => (
                  <button
                    key={tab.value}
                    onClick={() => setSelectedStatus(tab.value)}
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
          </div>

          {facultyGuidedProjects.length === 0 ? (
            <div className="py-12 text-center bg-white rounded-2xl border border-slate-200 p-8 space-y-2">
              <FolderGit2 className="w-12 h-12 text-slate-300 mx-auto" />
              <h3 className="text-lg font-bold text-slate-800">No Projects Found</h3>
              <p className="text-sm text-slate-500">No projects match the selected filter criteria.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {facultyGuidedProjects.map((project) => (
                <div
                  key={project.id}
                  onClick={() => setSelectedProjectId(project.id)}
                  className="bg-white rounded-2xl border border-slate-200 p-6 hover:shadow-lg transition-all flex flex-col justify-between cursor-pointer group"
                >
                  <div className="space-y-3">
                    <div className="flex items-center justify-between gap-2">
                      <span className="text-xs font-semibold text-indigo-600 bg-indigo-50 px-2.5 py-0.5 rounded-md">
                        MCA Department
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
                      <span className="font-semibold text-slate-700">{project.createdByUserName || 'Student'}</span>
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
        </div>
      )}

      {/* ======================================================== */}
      {/* 5. ADMIN VIEW: ALL PROJECTS CATALOG */}
      {/* ======================================================== */}
      {isAdmin && activeTab === 'catalog' && (
        <div className="space-y-6">
          <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200 space-y-4">
            <div className="flex flex-col sm:flex-row items-center justify-between gap-3">
              <div className="relative flex-1 w-full">
                <Search className="w-4 h-4 absolute left-3.5 top-3 text-slate-400" />
                <input
                  type="text"
                  placeholder="Search all department projects by title, author, or keywords..."
                  className="w-full pl-10 pr-4 py-2 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                />
              </div>

              {/* Status Filter Buttons */}
              <div className="flex items-center space-x-1 overflow-x-auto w-full sm:w-auto pb-1 sm:pb-0">
                {[
                  { label: 'All Projects', value: '' },
                  { label: 'Approved', value: 'APPROVED' },
                  { label: 'Under Review', value: 'UNDER_REVIEW' },
                  { label: 'Submitted', value: 'SUBMITTED' },
                  { label: 'Drafts', value: 'DRAFT' },
                  { label: 'Rejected', value: 'REJECTED' },
                ].map((tab) => (
                  <button
                    key={tab.value}
                    onClick={() => setSelectedStatus(tab.value)}
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
          </div>

          {filteredCatalogProjects.length === 0 ? (
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
                        MCA Department
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
