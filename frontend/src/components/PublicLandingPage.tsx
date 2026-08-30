import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { ProjectSummary, ApiResponse, PageResponse } from '../types';
import api from '../api/client';
import { ProjectDetailModal } from './ProjectDetailModal';
import { 
  Search, 
  FolderGit2, 
  Calendar, 
  User as UserIcon, 
  Sparkles, 
  ChevronLeft, 
  ChevronRight,
  ArrowRight,
  LogIn,
  UserPlus,
  Award
} from 'lucide-react';

export const PublicLandingPage: React.FC = () => {
  const [projects, setProjects] = useState<ProjectSummary[]>([]);

  // Filter & Pagination state
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [page, setPage] = useState<number>(0);
  const [totalPages, setTotalPages] = useState<number>(1);
  const [totalElements, setTotalElements] = useState<number>(0);

  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [selectedProjectId, setSelectedProjectId] = useState<number | null>(null);

  useEffect(() => {
    fetchProjects();
  }, [page]);

  const fetchProjects = async () => {
    setIsLoading(true);
    try {
      const url = `/projects?page=${page}&size=9`;
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
    <div className="space-y-8 py-4 pb-12">
      {/* Hero Section */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="bg-gradient-to-br from-indigo-900 via-indigo-800 to-slate-900 rounded-3xl p-6 sm:p-8 md:p-10 text-white shadow-xl relative overflow-hidden">
          {/* Decorative background glow */}
          <div className="absolute top-0 right-0 -mr-16 -mt-16 w-80 h-80 bg-indigo-500/20 rounded-full blur-3xl pointer-events-none" />
          <div className="absolute bottom-0 left-0 -ml-16 -mb-16 w-72 h-72 bg-blue-500/20 rounded-full blur-3xl pointer-events-none" />

          {/* Top Header inside Hero: Tag + Projects Count Badge */}
          <div className="relative z-10 flex flex-wrap items-center justify-between gap-3 mb-5">
            <div className="inline-flex items-center space-x-2 bg-indigo-500/30 backdrop-blur-md px-3.5 py-1.5 rounded-full text-xs font-bold border border-indigo-400/30 text-indigo-200">
              <Sparkles className="w-4 h-4 text-amber-300" />
              <span>Academic Project Repository</span>
            </div>

            <div className="inline-flex items-center space-x-2 bg-white/10 backdrop-blur-md px-3.5 py-1.5 rounded-full text-xs border border-white/20 text-white shadow-inner">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
              <span className="font-extrabold text-white text-sm">{totalElements}</span>
              <span className="text-indigo-200 font-medium">{totalElements === 1 ? 'Project' : 'Projects'}</span>
            </div>
          </div>

          <div className="relative z-10 max-w-3xl space-y-4">
            <h1 className="text-3xl sm:text-4xl font-black tracking-tight leading-tight">
              Discover, Share & Preserve University Innovation
            </h1>

            <p className="text-indigo-100/90 text-sm sm:text-base leading-relaxed max-w-2xl">
              ProjectVault is the official digital archive for capstone projects, scientific research, and software repositories.
            </p>

            <div className="pt-2 flex flex-wrap gap-3 items-center">
              <Link
                to="/signup"
                className="inline-flex items-center space-x-2 px-5 py-2.5 rounded-xl bg-indigo-500 text-white font-bold text-sm hover:bg-indigo-600 transition-all shadow-md hover:shadow-indigo-500/30"
              >
                <UserPlus className="w-4 h-4" />
                <span>Create Student Account</span>
                <ArrowRight className="w-4 h-4 ml-0.5" />
              </Link>
              <Link
                to="/login"
                className="inline-flex items-center space-x-2 px-5 py-2.5 rounded-xl bg-white/10 backdrop-blur-md text-white font-semibold text-sm hover:bg-white/20 transition-all border border-white/20"
              >
                <LogIn className="w-4 h-4" />
                <span>Sign In to Vault</span>
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Public Repository Explorer */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-5">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="space-y-1">
            <div className="inline-flex items-center space-x-2 text-xs font-bold uppercase tracking-wider text-indigo-600 bg-indigo-50 px-3 py-1 rounded-md">
              <FolderGit2 className="w-3.5 h-3.5" />
              <span>Public Repository Catalog</span>
            </div>
            <h2 className="text-2xl font-extrabold text-slate-900 tracking-tight">
              Explore Approved Capstone Projects
            </h2>
          </div>

          {/* Prompt banner to login/register */}
          <div className="bg-gradient-to-r from-indigo-50 to-blue-50 border border-indigo-100 px-4 py-2.5 rounded-xl flex items-center space-x-3 text-xs text-indigo-900">
            <Award className="w-4 h-4 text-indigo-600 shrink-0" />
            <span>
              Student or faculty member?{' '}
              <Link to="/login" className="font-bold underline hover:text-indigo-700">
                Log in
              </Link>{' '}
              to submit projects and access your dashboard.
            </span>
          </div>
        </div>

        {/* Filter / Search Bar */}
        <div className="bg-white p-4 rounded-2xl shadow-sm border border-slate-200">
          <div className="relative w-full">
            <Search className="w-4 h-4 absolute left-3.5 top-3.5 text-slate-400" />
            <input
              type="text"
              placeholder="Search projects by title, abstract, or author name..."
              className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-200 text-sm text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent bg-slate-50/50 focus:bg-white transition-colors"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
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
              There are currently no approved public projects matching your search criteria.
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
                      {project.departmentName || 'MCA'}
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
