import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { ProjectSummary, ApiResponse, PageResponse, ProjectSearchResult, TopicFeedback } from '../types';
import api from '../api/client';
import { searchProjectsSemantically } from '../api/aiClient';
import { ProjectDetailModal } from './ProjectDetailModal';
import { CreateProjectModal } from './CreateProjectModal';
import { useAuth } from '../context/AuthContext';
import { 
  FolderGit2, 
  Calendar, 
  User as UserIcon, 
  Sparkles, 
  ChevronLeft, 
  ChevronRight,
  Award,
  Zap,
  Tag,
  PlusCircle,
  Layers,
  Compass
} from 'lucide-react';

export const PublicLandingPage: React.FC = () => {
  const { user } = useAuth();
  const [projects, setProjects] = useState<ProjectSummary[]>([]);

  // Search state (Pure AI Semantic Vector Search)
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [aiResults, setAiResults] = useState<ProjectSearchResult[]>([]);
  const [aiExecutionTime, setAiExecutionTime] = useState<number | null>(null);
  const [isAiSearching, setIsAiSearching] = useState<boolean>(false);
  const [topicFeedback, setTopicFeedback] = useState<TopicFeedback | null>(null);

  // Pagination state for standard catalog
  const [page, setPage] = useState<number>(0);
  const [totalPages, setTotalPages] = useState<number>(1);
  const [totalElements, setTotalElements] = useState<number>(0);

  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [selectedProjectId, setSelectedProjectId] = useState<number | null>(null);

  // Start draft modal state
  const [isCreateModalOpen, setIsCreateModalOpen] = useState<boolean>(false);
  const [createInitialTitle, setCreateInitialTitle] = useState<string>('');
  const [createInitialAbstract, setCreateInitialAbstract] = useState<string>('');

  useEffect(() => {
    fetchProjects();
  }, [page]);

  // Debounced pure AI vector search
  useEffect(() => {
    if (searchTerm.trim().length >= 2) {
      const timer = setTimeout(() => {
        performAiSearch(searchTerm);
      }, 350);
      return () => clearTimeout(timer);
    } else if (!searchTerm.trim()) {
      setAiResults([]);
      setAiExecutionTime(null);
      setTopicFeedback(null);
    }
  }, [searchTerm]);

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

  const performAiSearch = async (query: string) => {
    setIsAiSearching(true);
    try {
      const data = await searchProjectsSemantically({ query, limit: 12 });
      setAiResults(data.results || []);
      setAiExecutionTime(data.execution_time_ms);
      setTopicFeedback(data.topic_feedback || null);
    } catch (err) {
      console.error('AI Vector search failed:', err);
    } finally {
      setIsAiSearching(false);
    }
  };

  const getAuthorName = (p: ProjectSummary | ProjectSearchResult) => {
    if ('author_name' in p && p.author_name) return p.author_name;
    const summary = p as ProjectSummary;
    return summary.createdByUserName || summary.createdByFullName || 'Academic Contributor';
  };

  const isStudent = user?.role === 'STUDENT' || user?.role === 'ADMIN';

  return (
    <div className="space-y-8 py-4 pb-12">
      {/* Hero Section */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="bg-gradient-to-br from-indigo-950 via-indigo-900 to-slate-900 rounded-3xl p-6 sm:p-8 md:p-10 text-white shadow-xl relative overflow-hidden">
          {/* Decorative background glow */}
          <div className="absolute -top-24 -right-24 w-96 h-96 bg-indigo-500/20 rounded-full blur-3xl pointer-events-none" />
          <div className="absolute -bottom-24 -left-24 w-96 h-96 bg-purple-500/15 rounded-full blur-3xl pointer-events-none" />

          <div className="relative z-10 max-w-3xl space-y-4">
            <div className="inline-flex items-center space-x-2 px-3 py-1 rounded-full bg-indigo-500/20 border border-indigo-400/30 text-indigo-200 text-xs font-semibold backdrop-blur-md">
              <Sparkles className="w-3.5 h-3.5 text-amber-300" />
              <span>Department of Computer Applications (MCA) — Digital Knowledge Vault</span>
            </div>

            <h1 className="text-3xl sm:text-4xl md:text-5xl font-extrabold tracking-tight text-white leading-tight">
              Master of Computer Applications <br />
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-indigo-200 via-purple-200 to-pink-200">
                AI Semantic Project Repository
              </span>
            </h1>

            <p className="text-sm sm:text-base text-indigo-100/90 leading-relaxed font-normal">
              Official institutional repository powered by SentenceTransformers dense vector embeddings and pgvector. 
              Search capstone research, distributed architectures, and machine learning models by natural concept, or explore novel academic topic viability.
            </p>

            {/* Quick stats banner */}
            <div className="pt-2 flex flex-wrap items-center gap-4 sm:gap-6 text-xs text-indigo-200/80 font-medium">
              <div className="flex items-center space-x-2">
                <FolderGit2 className="w-4 h-4 text-indigo-400" />
                <span>50+ Seeded MCA Capstone Projects</span>
              </div>
              <div className="flex items-center space-x-2">
                <Sparkles className="w-4 h-4 text-purple-400" />
                <span>SentenceTransformers (384-dim)</span>
              </div>
              <div className="flex items-center space-x-2">
                <Award className="w-4 h-4 text-emerald-400" />
                <span>Dual Plagiarism & Duplication Engine</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Main Content Area */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-6">
        {/* Header Title with Counter */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-slate-200 pb-4">
          <div>
            <h2 className="text-xl font-black text-slate-900 tracking-tight flex items-center space-x-2">
              <span>MCA Academic Repository</span>
              <span className="text-xs font-bold px-2.5 py-0.5 rounded-full bg-indigo-50 text-indigo-700 border border-indigo-200">
                {searchTerm.trim() ? `${aiResults.length} Vector Results` : `${totalElements} Approved Projects`}
              </span>
            </h2>
            <p className="text-xs text-slate-500 mt-0.5">
              Verified graduate capstones, research papers, and technical implementations with attached 5-page documentation.
            </p>
          </div>

          {/* Prompt banner to login/register if not logged in */}
          {!user && (
            <div className="bg-gradient-to-r from-indigo-50 to-blue-50 border border-indigo-100 px-4 py-2 rounded-xl flex items-center space-x-2.5 text-xs text-indigo-900">
              <Award className="w-4 h-4 text-indigo-600 shrink-0" />
              <span>
                Student or Faculty?{' '}
                <Link to="/login" className="font-bold underline hover:text-indigo-700">
                  Log in
                </Link>{' '}
                to submit drafts, access repository links, and download full 5-page PDFs.
              </span>
            </div>
          )}
        </div>

        {/* AI Semantic Vector Search Bar */}
        <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-200 space-y-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <div className="w-7 h-7 rounded-lg bg-indigo-600 text-white flex items-center justify-center shadow-xs">
                <Sparkles className="w-4 h-4" />
              </div>
              <div>
                <span className="text-xs font-bold text-slate-900 uppercase tracking-wider block">AI Semantic Vector Search</span>
                <span className="text-[11px] text-slate-400">Dense neural retrieval via SentenceTransformers (all-MiniLM-L6-v2)</span>
              </div>
            </div>

            {searchTerm.trim() && (
              <div className="flex items-center space-x-2 text-xs text-slate-500">
                {isAiSearching ? (
                  <span className="flex items-center space-x-1.5 text-indigo-600 font-medium">
                    <Sparkles className="w-3.5 h-3.5 animate-spin" />
                    <span>Analyzing vector space...</span>
                  </span>
                ) : aiExecutionTime !== null ? (
                  <span className="flex items-center space-x-1 bg-emerald-50 text-emerald-700 border border-emerald-200 px-2 py-0.5 rounded-md font-semibold text-[11px]">
                    <Zap className="w-3 h-3" />
                    <span>{aiResults.length} matches in {aiExecutionTime}ms</span>
                  </span>
                ) : null}
              </div>
            )}
          </div>

          {/* Search Input */}
          <div className="relative w-full">
            <Sparkles className="w-4 h-4 absolute left-3.5 top-3.5 text-indigo-500" />
            <input
              type="text"
              placeholder="Search by concept, problem, or technology in natural language (e.g. 'kubernetes autoscaling', 'pulmonary ct classifier', 'iot smart grid')..."
              className="w-full pl-10 pr-10 py-3 rounded-xl border border-indigo-100 bg-indigo-50/20 focus:bg-white focus:ring-2 focus:ring-indigo-500 text-sm text-slate-900 placeholder:text-slate-400 transition-all outline-none"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
            {searchTerm && (
              <button
                onClick={() => setSearchTerm('')}
                className="absolute right-3.5 top-3.5 text-xs text-slate-400 hover:text-slate-600 font-bold"
              >
                ✕
              </button>
            )}
          </div>

          {/* Suggested Concept Queries if empty */}
          {!searchTerm && (
            <div className="flex flex-wrap items-center gap-1.5 pt-1 text-xs">
              <span className="text-slate-400 font-medium text-[11px]">Try concept queries:</span>
              {[
                'cloud native microservices autoscaling',
                'medical diagnostic ct pulmonary classifier',
                'zero trust identity access management',
                'drone crop stress precision agriculture',
                'smart campus energy peak forecasting',
                'decentralized credit scoring smart contracts'
              ].map((queryText, idx) => (
                <button
                  key={idx}
                  onClick={() => setSearchTerm(queryText)}
                  className="bg-slate-100 hover:bg-indigo-50 hover:text-indigo-600 text-slate-600 px-2.5 py-1 rounded-lg text-[11px] font-medium border border-slate-200 transition-colors"
                >
                  "{queryText}"
                </button>
              ))}
            </div>
          )}
        </div>

        {/* AI Topic Viability Advisory Card (Displayed when query is novel or topicFeedback is available) */}
        {searchTerm.trim() && topicFeedback && (
          <div className="rounded-2xl border-2 border-indigo-300 bg-gradient-to-br from-indigo-50/90 via-purple-50/50 to-white p-6 space-y-4 shadow-md">
            <div className="flex flex-wrap items-center justify-between gap-3 border-b border-indigo-100 pb-3">
              <div className="flex items-center space-x-2.5">
                <div className="w-8 h-8 rounded-xl bg-indigo-600 text-white flex items-center justify-center shadow-sm">
                  <Compass className="w-4 h-4" />
                </div>
                <div>
                  <h3 className="text-base font-black text-slate-900 flex items-center gap-2">
                    <span>AI Project Feasibility & Research Guidance</span>
                    <span className="text-xs px-2.5 py-0.5 rounded-full font-bold bg-emerald-100 text-emerald-800 border border-emerald-300">
                      {topicFeedback.verdict}
                    </span>
                  </h3>
                  <p className="text-xs text-slate-500">
                    Topic: <span className="font-semibold text-indigo-700 font-mono">"{topicFeedback.query}"</span>
                  </p>
                </div>
              </div>

              {isStudent && (
                <button
                  onClick={() => {
                    setCreateInitialTitle(topicFeedback.query.charAt(0).toUpperCase() + topicFeedback.query.slice(1));
                    setCreateInitialAbstract(topicFeedback.academic_value);
                    setIsCreateModalOpen(true);
                  }}
                  className="inline-flex items-center space-x-1.5 px-4 py-2 rounded-xl bg-indigo-600 text-white font-bold text-xs hover:bg-indigo-700 transition-colors shadow-sm"
                >
                  <PlusCircle className="w-3.5 h-3.5" />
                  <span>Start This Project Draft</span>
                </button>
              )}
            </div>

            {/* Academic Value & Domain */}
            <div className="space-y-2">
              <div className="flex items-center space-x-2 text-xs font-semibold text-slate-500">
                <span className="text-[11px] font-bold px-2 py-0.5 rounded-md bg-indigo-100 text-indigo-800">
                  Domain: {topicFeedback.domain}
                </span>
                <span>•</span>
                <span>Research Significance & Thesis Value</span>
              </div>
              <p className="text-sm text-slate-700 leading-relaxed font-normal bg-white/80 p-3.5 rounded-xl border border-indigo-100">
                {topicFeedback.academic_value}
              </p>
            </div>

            {/* Recommended Tech Stack & Challenges Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
              {/* Tech Stack */}
              <div className="bg-white p-4 rounded-xl border border-slate-200 space-y-2">
                <div className="font-bold text-slate-800 flex items-center space-x-1.5">
                  <Layers className="w-4 h-4 text-indigo-600" />
                  <span>Recommended Technology Stack</span>
                </div>
                <div className="flex flex-wrap gap-1.5">
                  {topicFeedback.recommended_tech_stack.map((t, idx) => (
                    <span key={idx} className="px-2 py-0.5 rounded-md bg-indigo-50 text-indigo-700 border border-indigo-200 font-semibold text-[11px]">
                      {t}
                    </span>
                  ))}
                </div>
              </div>

              {/* Faculty Guidance */}
              <div className="bg-white p-4 rounded-xl border border-slate-200 space-y-2">
                <div className="font-bold text-slate-800 flex items-center space-x-1.5">
                  <Award className="w-4 h-4 text-emerald-600" />
                  <span>Faculty Guide Proposal Strategy</span>
                </div>
                <p className="text-slate-600 leading-relaxed">
                  {topicFeedback.faculty_guidance}
                </p>
              </div>
            </div>

            {/* Implementation Roadmap */}
            {topicFeedback.implementation_roadmap && topicFeedback.implementation_roadmap.length > 0 && (
              <div className="space-y-2 pt-1">
                <span className="text-xs font-bold text-slate-700 uppercase tracking-wider block">Recommended 4-Phase Roadmap</span>
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-2">
                  {topicFeedback.implementation_roadmap.map((step, idx) => (
                    <div key={idx} className="p-3 bg-white rounded-xl border border-slate-200 text-xs space-y-1">
                      <span className="text-[10px] font-bold text-indigo-600 font-mono block">PHASE {idx + 1}</span>
                      <p className="text-slate-700 text-[11px] leading-tight font-medium">{step}</p>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}

        {/* Project Results Display */}
        {searchTerm.trim() ? (
          isAiSearching ? (
            <div className="py-16 text-center space-y-2">
              <Sparkles className="w-8 h-8 text-indigo-500 animate-spin mx-auto" />
              <div className="text-slate-600 font-semibold text-sm">Querying neural embedding space in PostgreSQL pgvector...</div>
            </div>
          ) : aiResults.length === 0 ? (
            !topicFeedback && (
              <div className="py-16 text-center bg-white rounded-2xl border border-slate-200 p-8 space-y-3">
                <FolderGit2 className="w-12 h-12 text-slate-300 mx-auto" />
                <h3 className="text-lg font-bold text-slate-800">No Direct Project Matches Found</h3>
                <p className="text-sm text-slate-500 max-w-md mx-auto">
                  No projects in the repository matched "{searchTerm}". Check the AI topic feasibility analysis above.
                </p>
              </div>
            )
          ) : (
            <div className="space-y-4">
              <div className="flex items-center justify-between text-xs text-slate-500 font-medium">
                <span>Top Matching Projects in Vault (Ranked by Cosine Similarity):</span>
                <span>Showing {aiResults.length} matches</span>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {aiResults.map((project) => (
                  <div
                    key={project.id}
                    onClick={() => setSelectedProjectId(project.id)}
                    className="bg-white rounded-2xl border border-indigo-100 hover:border-indigo-300 p-6 hover:shadow-xl hover:-translate-y-0.5 transition-all duration-200 flex flex-col justify-between cursor-pointer group relative overflow-hidden"
                  >
                    <div className="space-y-3">
                      <div className="flex items-center justify-between gap-2">
                        <span className="text-xs font-semibold text-indigo-600 bg-indigo-50 px-2.5 py-0.5 rounded-md">
                          {project.department_name || 'Computer Applications (MCA)'}
                        </span>

                        {/* AI Match Score Badge */}
                        <span className="inline-flex items-center space-x-1 px-2.5 py-0.5 text-xs font-bold rounded-full bg-gradient-to-r from-purple-50 to-indigo-50 text-indigo-700 border border-indigo-200 shadow-xs">
                          <Sparkles className="w-3 h-3 text-amber-500" />
                          <span>{Math.round(project.similarity_score * 100)}% Match</span>
                        </span>
                      </div>

                      <h3 className="text-lg font-bold text-slate-900 group-hover:text-indigo-600 transition-colors line-clamp-2">
                        {project.title}
                      </h3>

                      {project.domain && (
                        <div className="inline-flex items-center space-x-1 px-2 py-0.5 rounded bg-slate-100 text-slate-700 text-[11px] font-medium">
                          <Tag className="w-3 h-3 text-slate-400" />
                          <span>{project.domain}</span>
                        </div>
                      )}

                      <p className="text-sm text-slate-600 line-clamp-3 leading-relaxed">
                        {project.abstract}
                      </p>
                    </div>

                    <div className="pt-4 mt-4 border-t border-slate-100 flex flex-wrap items-center justify-between gap-2 text-xs text-slate-500 font-medium">
                      <div className="flex items-center space-x-1.5">
                        <UserIcon className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                        <span className="font-semibold text-slate-700">{getAuthorName(project)}</span>
                      </div>
                      <div className="flex items-center space-x-1.5">
                        <Calendar className="w-3.5 h-3.5 text-slate-400" />
                        <span>AY {project.academic_year}</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )
        ) : (
          /* Standard Approved Projects Grid */
          isLoading ? (
            <div className="py-16 text-center text-slate-400 font-medium">Loading project catalog...</div>
          ) : projects.length === 0 ? (
            <div className="py-16 text-center bg-white rounded-2xl border border-slate-200 p-8 space-y-3">
              <FolderGit2 className="w-12 h-12 text-slate-300 mx-auto" />
              <h3 className="text-lg font-bold text-slate-800">No Public Projects Found</h3>
              <p className="text-sm text-slate-500 max-w-md mx-auto">
                No approved projects available in the public catalog.
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {projects.map((project) => (
                <div
                  key={project.id}
                  onClick={() => setSelectedProjectId(project.id)}
                  className="bg-white rounded-2xl border border-slate-200 p-6 hover:shadow-xl hover:-translate-y-0.5 transition-all duration-200 flex flex-col justify-between cursor-pointer group"
                >
                  <div className="space-y-3">
                    <div className="flex items-center justify-between gap-2">
                      <span className="text-xs font-semibold text-indigo-600 bg-indigo-50 px-2.5 py-0.5 rounded-md">
                        {project.departmentName || 'Computer Applications (MCA)'}
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

                  <div className="pt-4 mt-4 border-t border-slate-100 flex flex-wrap items-center justify-between gap-2 text-xs text-slate-500 font-medium">
                    <div className="flex items-center space-x-1.5">
                      <UserIcon className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                      <span className="font-semibold text-slate-700">{getAuthorName(project)}</span>
                      {project.createdByRollNo && (
                        <span className="text-[11px] font-mono px-1.5 py-0.5 rounded bg-slate-100 text-slate-600 border border-slate-200">
                          {project.createdByRollNo}
                        </span>
                      )}
                      <span className="text-[10px] font-semibold px-1.5 py-0.2 bg-blue-50 text-blue-700 border border-blue-200 rounded">
                        Student
                      </span>
                    </div>
                    <div className="flex items-center space-x-1.5">
                      <Calendar className="w-3.5 h-3.5 text-slate-400" />
                      <span>AY {project.academicYear}</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )
        )}

        {/* Pagination (visible when showing standard catalog) */}
        {!searchTerm.trim() && totalPages > 1 && (
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

      {/* Create Project Modal for Start Draft */}
      {isCreateModalOpen && (
        <CreateProjectModal
          isOpen={isCreateModalOpen}
          onClose={() => setIsCreateModalOpen(false)}
          onSuccess={() => {
            setIsCreateModalOpen(false);
            fetchProjects();
          }}
          initialTitle={createInitialTitle}
          initialAbstract={createInitialAbstract}
        />
      )}
    </div>
  );
};
