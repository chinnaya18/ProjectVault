import React, { useState, useEffect } from 'react';
import { DashboardAnalytics, ApiResponse } from '../types';
import api, { getErrorMessage } from '../api/client';
import { 
  BarChart3, 
  PieChart, 
  FolderGit2, 
  Users, 
  CheckCircle2, 
  Clock, 
  AlertCircle, 
  Sparkles, 
  Cpu, 
  Layers, 
  Building2, 
  RefreshCw,
  GraduationCap,
  TrendingUp,
  FileCheck,
  Award
} from 'lucide-react';

export const AnalyticsPage: React.FC = () => {
  const [data, setData] = useState<DashboardAnalytics | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isRefreshing, setIsRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchAnalytics();
  }, []);

  const fetchAnalytics = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const res = await api.get<ApiResponse<DashboardAnalytics>>('/analytics/dashboard');
      if (res.data && res.data.data) {
        setData(res.data.data);
      }
    } catch (err: any) {
      setError(getErrorMessage(err, 'Failed to load institutional analytics'));
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

  const handleRefresh = () => {
    setIsRefreshing(true);
    fetchAnalytics();
  };

  if (isLoading && !data) {
    return (
      <div className="min-h-[70vh] flex flex-col items-center justify-center space-y-3">
        <div className="w-10 h-10 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
        <p className="text-slate-500 font-semibold text-sm">Computing Institutional Repository Metrics...</p>
      </div>
    );
  }

  const statusTotal = data ? Math.max(1, data.totalProjects) : 1;
  const approvedPct = data ? Math.round((data.approvedProjects / statusTotal) * 100) : 0;
  const reviewPct = data ? Math.round((data.underReviewProjects / statusTotal) * 100) : 0;
  const submittedPct = data ? Math.round((data.submittedProjects / statusTotal) * 100) : 0;
  const draftPct = data ? Math.round((data.draftProjects / statusTotal) * 100) : 0;
  const rejectedPct = data ? Math.round((data.rejectedProjects / statusTotal) * 100) : 0;

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">
      {/* Top Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-6 rounded-3xl shadow-sm border border-slate-200">
        <div className="space-y-1">
          <div className="flex items-center space-x-2">
            <div className="p-2.5 rounded-2xl bg-indigo-50 border border-indigo-100 text-indigo-600">
              <BarChart3 className="w-6 h-6" />
            </div>
            <div>
              <h1 className="text-2xl font-black text-slate-900 tracking-tight">Institutional Analytics & Metrics</h1>
              <p className="text-xs text-slate-500 font-medium">Real-time repository statistics, AI research trends, and governance KPIs</p>
            </div>
          </div>
        </div>

        <div className="flex items-center space-x-3">
          <span className="text-xs text-slate-400 font-mono hidden sm:inline">
            Updated: {new Date().toLocaleTimeString()}
          </span>
          <button
            onClick={handleRefresh}
            disabled={isRefreshing}
            className="flex items-center space-x-1.5 px-4 py-2.5 rounded-2xl bg-indigo-50 hover:bg-indigo-100 text-indigo-700 text-xs font-bold transition-all border border-indigo-200 shadow-sm"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isRefreshing ? 'animate-spin' : ''}`} />
            <span>Refresh Metrics</span>
          </button>
        </div>
      </div>

      {error && (
        <div className="p-4 rounded-2xl bg-rose-50 border border-rose-200 text-rose-700 text-sm flex items-center space-x-2">
          <AlertCircle className="w-5 h-5 shrink-0" />
          <span>{error}</span>
        </div>
      )}

      {/* KPI Cards Grid */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-2">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-bold uppercase tracking-wider">Total Projects</span>
            <FolderGit2 className="w-4 h-4 text-indigo-500" />
          </div>
          <div className="text-2xl font-black text-slate-900">{data?.totalProjects || 0}</div>
          <div className="text-[11px] text-emerald-600 font-semibold flex items-center space-x-1">
            <TrendingUp className="w-3 h-3" />
            <span>Active Repository</span>
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-2">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-bold uppercase tracking-wider">Approved</span>
            <CheckCircle2 className="w-4 h-4 text-emerald-500" />
          </div>
          <div className="text-2xl font-black text-emerald-700">{data?.approvedProjects || 0}</div>
          <div className="text-[11px] text-slate-500 font-medium">{approvedPct}% of repository</div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-2">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-bold uppercase tracking-wider">Under Review</span>
            <Clock className="w-4 h-4 text-purple-500" />
          </div>
          <div className="text-2xl font-black text-purple-700">{data?.underReviewProjects || 0}</div>
          <div className="text-[11px] text-purple-600 font-medium">Faculty desk queue</div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-2">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-bold uppercase tracking-wider">Submitted</span>
            <FileCheck className="w-4 h-4 text-blue-500" />
          </div>
          <div className="text-2xl font-black text-blue-700">{data?.submittedProjects || 0}</div>
          <div className="text-[11px] text-blue-600 font-medium">Awaiting evaluation</div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-2">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-bold uppercase tracking-wider">Active Students</span>
            <GraduationCap className="w-4 h-4 text-indigo-500" />
          </div>
          <div className="text-2xl font-black text-slate-900">{data?.studentUsers || 0}</div>
          <div className="text-[11px] text-slate-500 font-medium">{data?.alumniUsers || 0} Alumni preserved</div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-2">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-bold uppercase tracking-wider">Faculty Guides</span>
            <Users className="w-4 h-4 text-emerald-500" />
          </div>
          <div className="text-2xl font-black text-slate-900">{data?.facultyUsers || 0}</div>
          <div className="text-[11px] text-slate-500 font-medium">{data?.totalDepartments || 0} Departments</div>
        </div>
      </div>

      {/* Main Analysis Sections */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Status Breakdown & Lifecycle Health */}
        <div className="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm space-y-5">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <PieChart className="w-5 h-5 text-indigo-600" />
              <h2 className="text-base font-bold text-slate-900">Project Lifecycle State Distribution</h2>
            </div>
            <span className="text-xs font-semibold text-slate-400">{data?.totalProjects || 0} total</span>
          </div>

          {/* Multi-segment Progress Bar */}
          <div className="space-y-2">
            <div className="h-4 w-full bg-slate-100 rounded-full overflow-hidden flex shadow-inner">
              <div style={{ width: `${approvedPct}%` }} className="bg-emerald-500 h-full transition-all duration-500" title={`Approved: ${data?.approvedProjects}`} />
              <div style={{ width: `${reviewPct}%` }} className="bg-purple-500 h-full transition-all duration-500" title={`Under Review: ${data?.underReviewProjects}`} />
              <div style={{ width: `${submittedPct}%` }} className="bg-blue-500 h-full transition-all duration-500" title={`Submitted: ${data?.submittedProjects}`} />
              <div style={{ width: `${draftPct}%` }} className="bg-amber-400 h-full transition-all duration-500" title={`Draft: ${data?.draftProjects}`} />
              <div style={{ width: `${rejectedPct}%` }} className="bg-rose-400 h-full transition-all duration-500" title={`Rejected: ${data?.rejectedProjects}`} />
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 pt-3">
              <div className="flex items-center space-x-2 text-xs">
                <span className="w-3 h-3 rounded-full bg-emerald-500 shrink-0"></span>
                <span className="text-slate-600 font-medium">Approved: <strong className="text-slate-900">{data?.approvedProjects}</strong> ({approvedPct}%)</span>
              </div>
              <div className="flex items-center space-x-2 text-xs">
                <span className="w-3 h-3 rounded-full bg-purple-500 shrink-0"></span>
                <span className="text-slate-600 font-medium">Under Review: <strong className="text-slate-900">{data?.underReviewProjects}</strong></span>
              </div>
              <div className="flex items-center space-x-2 text-xs">
                <span className="w-3 h-3 rounded-full bg-blue-500 shrink-0"></span>
                <span className="text-slate-600 font-medium">Submitted: <strong className="text-slate-900">{data?.submittedProjects}</strong></span>
              </div>
              <div className="flex items-center space-x-2 text-xs">
                <span className="w-3 h-3 rounded-full bg-amber-400 shrink-0"></span>
                <span className="text-slate-600 font-medium">Drafts: <strong className="text-slate-900">{data?.draftProjects}</strong></span>
              </div>
              <div className="flex items-center space-x-2 text-xs">
                <span className="w-3 h-3 rounded-full bg-rose-400 shrink-0"></span>
                <span className="text-slate-600 font-medium">Rejected: <strong className="text-slate-900">{data?.rejectedProjects}</strong></span>
              </div>
              <div className="flex items-center space-x-2 text-xs">
                <span className="w-3 h-3 rounded-full bg-slate-400 shrink-0"></span>
                <span className="text-slate-600 font-medium">Archived: <strong className="text-slate-900">{data?.archivedProjects}</strong></span>
              </div>
            </div>
          </div>

          {/* Department Breakdown */}
          <div className="pt-4 border-t border-slate-100 space-y-3">
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 flex items-center space-x-1.5">
              <Building2 className="w-3.5 h-3.5 text-indigo-500" />
              <span>Projects by Academic Department</span>
            </h3>
            <div className="space-y-2">
              {data?.departmentProjectCounts && Object.entries(data.departmentProjectCounts).length > 0 ? (
                Object.entries(data.departmentProjectCounts).map(([deptName, count]) => {
                  const deptPct = data?.totalProjects ? Math.round((count / data.totalProjects) * 100) : 0;
                  return (
                    <div key={deptName} className="space-y-1">
                      <div className="flex justify-between text-xs font-semibold">
                        <span className="text-slate-800">{deptName}</span>
                        <span className="text-indigo-600">{count} projects ({deptPct}%)</span>
                      </div>
                      <div className="h-2 w-full bg-slate-100 rounded-full overflow-hidden">
                        <div style={{ width: `${deptPct}%` }} className="bg-indigo-600 h-full rounded-full transition-all duration-500" />
                      </div>
                    </div>
                  );
                })
              ) : (
                <div className="text-xs text-slate-400 italic">No department distribution recorded yet.</div>
              )}
            </div>
          </div>
        </div>

        {/* AI Ingestion & Research Trends */}
        <div className="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm space-y-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <Sparkles className="w-5 h-5 text-indigo-600" />
              <h2 className="text-base font-bold text-slate-900">AI Domain & Tech Intelligence</h2>
            </div>
            <span className="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-indigo-50 text-indigo-700 border border-indigo-200">
              Gemini + SentenceTransformers
            </span>
          </div>

          {/* Academic Domains */}
          <div className="space-y-3">
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 flex items-center space-x-1.5">
              <Layers className="w-3.5 h-3.5 text-indigo-500" />
              <span>Extracted Academic Domains</span>
            </h3>
            <div className="flex flex-wrap gap-2">
              {data?.domainDistribution && Object.entries(data.domainDistribution).length > 0 ? (
                Object.entries(data.domainDistribution).map(([domain, cnt]) => (
                  <div
                    key={domain}
                    className="flex items-center space-x-2 px-3.5 py-1.5 rounded-xl bg-slate-50 border border-slate-200 text-xs font-semibold text-slate-800 shadow-2xs hover:border-indigo-300 transition-colors"
                  >
                    <span>{domain}</span>
                    <span className="px-1.5 py-0.2 rounded-md bg-indigo-100 text-indigo-800 text-[10px] font-bold font-mono">
                      {cnt}
                    </span>
                  </div>
                ))
              ) : (
                <div className="text-xs text-slate-400 italic">No domains extracted yet.</div>
              )}
            </div>
          </div>

          {/* Top Technologies */}
          <div className="space-y-3 pt-3 border-t border-slate-100">
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 flex items-center space-x-1.5">
              <Cpu className="w-3.5 h-3.5 text-emerald-500" />
              <span>Dominant Technology Stacks</span>
            </h3>
            <div className="flex flex-wrap gap-2">
              {data?.topTechStacks && Object.entries(data.topTechStacks).length > 0 ? (
                Object.entries(data.topTechStacks).map(([tech, cnt]) => (
                  <div
                    key={tech}
                    className="flex items-center space-x-1.5 px-3 py-1 rounded-lg bg-emerald-50 border border-emerald-200 text-xs font-semibold text-emerald-900 shadow-2xs"
                  >
                    <span>{tech}</span>
                    <span className="w-4 h-4 rounded-full bg-emerald-600 text-white text-[10px] font-bold flex items-center justify-center">
                      {cnt}
                    </span>
                  </div>
                ))
              ) : (
                <div className="text-xs text-slate-400 italic">No technology tags indexed yet.</div>
              )}
            </div>
          </div>

          {/* Institutional Knowledge Preserved Callout */}
          <div className="p-4 rounded-2xl bg-linear-to-r from-indigo-50 to-blue-50 border border-indigo-100 flex items-start space-x-3">
            <Award className="w-5 h-5 text-indigo-600 shrink-0 mt-0.5" />
            <div className="space-y-1">
              <h4 className="text-xs font-bold text-indigo-950">Institutional Knowledge Continuity</h4>
              <p className="text-xs text-indigo-700 leading-relaxed">
                ProjectVault preserves historical academic intellectual property across graduating batches. Graduated students retain their original identity as <strong>Alumni</strong>, preventing accidental duplicate projects and promoting continuous capstone enhancement.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
