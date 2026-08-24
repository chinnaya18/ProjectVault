import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { ProjectSummary, Department, ApiResponse, PageResponse } from '../types';
import api from '../api/client';
import { ProjectDetailModal } from './ProjectDetailModal';
import { 
  Search, 
  FolderGit2, 
  Calendar, 
  User as UserIcon, 
  Sparkles, 
  Filter, 
  ChevronLeft, 
  ChevronRight,
  ShieldCheck,
  GraduationCap,
  ArrowRight,
  LogIn,
  UserPlus,
  Layers,
  Award
} from 'lucide-react';

export const PublicLandingPage: React.FC = () => {
  const [projects, setProjects] = useState<ProjectSummary[]>([]);
  const [departments, setDepartments] = useState<Department[]>([]);

  // Filter & Pagination state
  const [selectedDept, setSelectedDept] = useState<string>('');
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [page, setPage] = useState<number>(0);
  const [totalPages, setTotalPages] = useState<number>(1);
  const [totalElements, setTotalElements] = useState<number>(0);

  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [selectedProjectId, setSelectedProjectId] = useState<number | null>(null);

  useEffect(() => {
    fetchDepartments();
  }, []);

  useEffect(() => {
    fetchProjects();
  }, [selectedDept, page]);

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
      let url = `/projects?page=${page}&size=9`;
      if (selectedDept) url += `&departmentId=${selectedDept}`;

      const res = await api.get<ApiResponse<PageResponse<ProjectSummary>>>(url);
      if (res.data && res.data.data) {
        setProjects(res.data.data.content || []);
        setTotalPages(res.data.data.totalPages || 1);
        setTotalElements(res.data.data.totalElements || 0);
      }
    } catch (err) {
      console.error('Error fetching public projects:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const filteredProjects = projects.filter((p) => {
    if (!searchTerm) return true;
    const term = searchTerm.toLowerCase();
    const author = p.createdByUserName || p.createdByFullName || '';
    return (
      p.title.toLowerCase().includes(term) ||
      p.abstractText.toLowerCase().includes(term) ||
      author.toLowerCase().includes(term)
    );
  });

  const getAuthorName = (p: ProjectSummary) => {
    return p.createdByUserName || p.createdByFullName || 'Academic Contributor';
  };

  return (
    <div className="space-y-16 py-8 pb-16">
      {/* Hero Section */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="bg-gradient-to-br from-indigo-900 via-indigo-800 to-slate-900 rounded-3xl p-8 sm:p-12 text-white shadow-2xl relative overflow-hidden">
          {/* Decorative background glow */}
          <div className="absolute top-0 right-0 -mr-16 -mt-16 w-96 h-96 bg-indigo-500/20 rounded-full blur-3xl pointer-events-none" />
          <div className="absolute bottom-0 left-0 -ml-16 -mb-16 w-80 h-80 bg-blue-500/20 rounded-full blur-3xl pointer-events-none" />

          <div className="relative z-10 max-w-3xl space-y-6">
            <div className="inline-flex items-center space-x-2 bg-indigo-500/30 backdrop-blur-md px-3.5 py-1.5 rounded-full text-xs font-bold border border-indigo-400/30 text-indigo-200">
              <Sparkles className="w-4 h-4 text-amber-300" />
              <span>University Academic Project Repository</span>
            </div>

            <h1 className="text-4xl sm:text-5xl font-black tracking-tight leading-tight">
              Discover, Share & Preserve University Innovation
            </h1>

            <p className="text-indigo-100 text-base sm:text-lg leading-relaxed">
              ProjectVault is the official digital archive for capstone projects, scientific research, and software repositories across university departments.
            </p>

            <div className="pt-4 flex flex-wrap gap-4 items-center">
              <Link
                to="/signup"
                className="inline-flex items-center space-x-2 px-6 py-3.5 rounded-2xl bg-indigo-500 text-white font-bold text-sm hover:bg-indigo-600 transition-all shadow-lg hover:shadow-indigo-500/30"
              >
                <UserPlus className="w-4 h-4" />
                <span>Create Student Account</span>
                <ArrowRight className="w-4 h-4 ml-1" />
              </Link>
              <Link
                to="/login"
                className="inline-flex items-center space-x-2 px-6 py-3.5 rounded-2xl bg-white/10 backdrop-blur-md text-white font-semibold text-sm hover:bg-white/20 transition-all border border-white/20"
              >
                <LogIn className="w-4 h-4" />
                <span>Sign In to Vault</span>
              </Link>
            </div>
          </div>

          {/* Quick Metrics Bar */}
          <div className="mt-12 pt-8 border-t border-indigo-700/50 grid grid-cols-2 md:grid-cols-4 gap-6 text-center">
            <div className="space-y-1">
              <div className="text-2xl sm:text-3xl font-extrabold text-white">{totalElements}</div>
              <div className="text-xs text-indigo-200 uppercase tracking-wider font-semibold">Published Projects</div>
            </div>
            <div className="space-y-1">
              <div className="text-2xl sm:text-3xl font-extrabold text-white">{departments.length > 0 ? departments.length : '1'}</div>
              <div className="text-xs text-indigo-200 uppercase tracking-wider font-semibold">Academic Departments</div>
            </div>
            <div className="space-y-1">
              <div className="text-2xl sm:text-3xl font-extrabold text-white">100%</div>
              <div className="text-xs text-indigo-200 uppercase tracking-wider font-semibold">Peer Reviewed</div>
            </div>
            <div className="space-y-1">
              <div className="text-2xl sm:text-3xl font-extrabold text-white">Open</div>
              <div className="text-xs text-indigo-200 uppercase tracking-wider font-semibold">Repository Access</div>
            </div>
          </div>
        </div>
      </section>

      {/* Feature Highlights Grid */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center space-y-3 mb-10">
          <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
            Designed for Academic Rigor & Collaboration
          </h2>
          <p className="text-slate-500 text-sm max-w-2xl mx-auto">
            Everything students, faculty advisers, and department chairs need to manage capstone projects and research repositories.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm space-y-4 hover:shadow-md transition-shadow">
            <div className="w-12 h-12 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center">
              <Layers className="w-6 h-6" />
            </div>
            <h3 className="text-lg font-bold text-slate-900">Project State Machine</h3>
            <p className="text-sm text-slate-600 leading-relaxed">
              Track project progression seamlessly through formal lifecycle stages: Draft, Submitted, Under Review, Approved, and Archived.
            </p>
          </div>

          <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm space-y-4 hover:shadow-md transition-shadow">
            <div className="w-12 h-12 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <ShieldCheck className="w-6 h-6" />
            </div>
            <h3 className="text-lg font-bold text-slate-900">Faculty Review & Verification</h3>
            <p className="text-sm text-slate-600 leading-relaxed">
              Faculty members evaluate submissions, request revisions, and verify intellectual rigor before projects enter the public catalog.
            </p>
          </div>

          <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm space-y-4 hover:shadow-md transition-shadow">
            <div className="w-12 h-12 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center">
              <GraduationCap className="w-6 h-6" />
            </div>
            <h3 className="text-lg font-bold text-slate-900">Alumni Portfolio Continuity</h3>
            <p className="text-sm text-slate-600 leading-relaxed">
              Graduating students maintain their academic project history under Alumni status without losing credit or repository access.
            </p>
          </div>
        </div>
      </section>

      {/* Public Repository Explorer */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-6">
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
          <div className="space-y-1">
            <div className="inline-flex items-center space-x-2 text-xs font-bold uppercase tracking-wider text-indigo-600 bg-indigo-50 px-3 py-1 rounded-md">
              <FolderGit2 className="w-3.5 h-3.5" />
              <span>Public Repository Catalog</span>
            </div>
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
              Explore Approved Capstone Projects
            </h2>
          </div>

          {/* Prompt banner to login/register */}
          <div className="bg-gradient-to-r from-indigo-50 to-blue-50 border border-indigo-100 p-3.5 rounded-xl flex items-center space-x-3 text-xs text-indigo-900">
            <Award className="w-5 h-5 text-indigo-600 shrink-0" />
            <span>
              Are you a student or faculty member?{' '}
              <Link to="/login" className="font-bold underline hover:text-indigo-700">
                Log in
              </Link>{' '}
              to access your dashboard and submit drafts.
            </span>
          </div>
        </div>

        {/* Filter Bar */}
        <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200 space-y-4">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            {/* Search */}
            <div className="relative flex-1">
              <Search className="w-4 h-4 absolute left-3.5 top-3 text-slate-400" />
              <input
                type="text"
                placeholder="Search by title, abstract, or author name..."
                className="w-full pl-10 pr-4 py-2 rounded-xl border border-slate-300 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>

            {/* Department dropdown */}
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
        </div>

        {/* Projects Grid */}
        {isLoading ? (
          <div className="py-16 text-center text-slate-400 font-medium">Loading project catalog...</div>
        ) : filteredProjects.length === 0 ? (
          <div className="py-16 text-center bg-white rounded-2xl border border-slate-200 p-8 space-y-3">
            <FolderGit2 className="w-12 h-12 text-slate-300 mx-auto" />
            <h3 className="text-lg font-bold text-slate-800">No Public Projects Found</h3>
            <p className="text-sm text-slate-500 max-w-md mx-auto">
              There are currently no approved public projects matching your filter criteria.
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredProjects.map((project) => (
              <div
                key={project.id}
                onClick={() => setSelectedProjectId(project.id)}
                className="bg-white rounded-2xl border border-slate-200 p-6 hover:shadow-xl hover:-translate-y-0.5 transition-all duration-200 flex flex-col justify-between cursor-pointer group"
              >
                <div className="space-y-3">
                  <div className="flex items-center justify-between gap-2">
                    <span className="text-xs font-semibold text-indigo-600 bg-indigo-50 px-2.5 py-0.5 rounded-md">
                      {project.departmentName}
                    </span>
                    <span className="px-2.5 py-0.5 text-xs font-bold rounded-full border bg-emerald-50 text-emerald-700 border-emerald-200">
                      APPROVED
                    </span>
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
                    <span>{getAuthorName(project)}</span>
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
      </section>

      {/* Project Detail Modal */}
      <ProjectDetailModal
        projectId={selectedProjectId}
        isOpen={!!selectedProjectId}
        onClose={() => setSelectedProjectId(null)}
        onUpdate={() => fetchProjects()}
      />
    </div>
  );
};
