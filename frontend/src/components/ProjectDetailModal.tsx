import React, { useState, useEffect } from 'react';
import { ProjectDetail, ProjectStatus, ApiResponse } from '../types';
import api, { getErrorMessage } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { X, ExternalLink, Calendar, GraduationCap, Building2, Trash2, ArrowRightCircle, CheckCircle2, XCircle, FileClock, Archive } from 'lucide-react';

interface ProjectDetailModalProps {
  projectId: number | null;
  isOpen: boolean;
  onClose: () => void;
  onUpdate: () => void;
}

export const ProjectDetailModal: React.FC<ProjectDetailModalProps> = ({ projectId, isOpen, onClose, onUpdate }) => {
  const { user } = useAuth();
  const [project, setProject] = useState<ProjectDetail | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [isTransitioning, setIsTransitioning] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (isOpen && projectId) {
      fetchProjectDetail();
    } else {
      setProject(null);
    }
  }, [isOpen, projectId]);

  const fetchProjectDetail = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const res = await api.get<ApiResponse<ProjectDetail>>(`/projects/${projectId}`);
      if (res.data && res.data.data) {
        setProject(res.data.data);
      }
    } catch (err: any) {
      setError(getErrorMessage(err, 'Failed to fetch project details'));
    } finally {
      setIsLoading(false);
    }
  };

  const handleStatusTransition = async (targetStatus: ProjectStatus) => {
    if (!projectId) return;
    setIsTransitioning(true);
    setError(null);
    try {
      await api.patch(`/projects/${projectId}/status`, { status: targetStatus });
      await fetchProjectDetail();
      onUpdate();
    } catch (err: any) {
      setError(getErrorMessage(err, `Failed to transition status to ${targetStatus}`));
    } finally {
      setIsTransitioning(false);
    }
  };

  const handleDelete = async () => {
    if (!projectId || !window.confirm('Are you sure you want to delete this project draft?')) return;
    try {
      await api.delete(`/projects/${projectId}`);
      onUpdate();
      onClose();
    } catch (err: any) {
      setError(getErrorMessage(err, 'Failed to delete project'));
    }
  };

  if (!isOpen) return null;

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
      <span className={`px-3 py-1 text-xs font-bold rounded-full border ${styles[status]}`}>
        {status.replace('_', ' ')}
      </span>
    );
  };

  const isCreator = user && project && user.id === project.createdByUserId;
  const isAdmin = user?.role === 'ADMIN';
  const isFaculty = user?.role === 'FACULTY';

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm">
      <div className="bg-white rounded-2xl max-w-3xl w-full shadow-2xl border border-slate-200 overflow-hidden flex flex-col max-h-[90vh]">
        {/* Header */}
        <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-slate-50/50">
          <div className="flex items-center space-x-3">
            <h2 className="text-lg font-bold text-slate-900">Project Overview</h2>
            {project && getStatusBadge(project.status)}
          </div>
          <button
            onClick={onClose}
            className="text-slate-400 hover:text-slate-600 p-1.5 rounded-lg hover:bg-slate-100 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 overflow-y-auto space-y-6 flex-1 text-slate-800">
          {isLoading ? (
            <div className="py-12 text-center text-slate-400 font-medium">Loading project details...</div>
          ) : error ? (
            <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-sm">
              {error}
            </div>
          ) : project ? (
            <>
              <div>
                <h1 className="text-2xl font-extrabold text-slate-900 leading-tight mb-2">{project.title}</h1>
                <div className="flex flex-wrap items-center gap-3 text-xs font-medium text-slate-500">
                  <div className="flex items-center space-x-1">
                    <Building2 className="w-4 h-4 text-slate-400" />
                    <span>{project.departmentName}</span>
                  </div>
                  <span>•</span>
                  <div className="flex items-center space-x-1">
                    <Calendar className="w-4 h-4 text-slate-400" />
                    <span>AY {project.academicYear} (Sem {project.semester})</span>
                  </div>
                  <span>•</span>
                  <div className="flex items-center space-x-1">
                    <GraduationCap className="w-4 h-4 text-slate-400" />
                    <span>{project.projectType}</span>
                  </div>
                </div>
              </div>

              {/* Abstract */}
              <div className="bg-slate-50 p-4 rounded-xl border border-slate-200">
                <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-2">Abstract</h3>
                <p className="text-sm text-slate-700 leading-relaxed whitespace-pre-line">{project.abstractText}</p>
              </div>

              {/* Meta details & repo */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-sm">
                <div className="p-3.5 rounded-xl border border-slate-200 bg-white">
                  <span className="text-xs font-semibold text-slate-400 block mb-1">Created By</span>
                  <span className="font-semibold text-slate-800">{project.createdByFullName}</span>
                </div>
                <div className="p-3.5 rounded-xl border border-slate-200 bg-white">
                  <span className="text-xs font-semibold text-slate-400 block mb-1">Repository</span>
                  {project.repositoryUrl ? (
                    <a
                      href={project.repositoryUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-indigo-600 font-semibold hover:underline flex items-center space-x-1 text-sm truncate"
                    >
                      <span>{project.repositoryUrl}</span>
                      <ExternalLink className="w-3.5 h-3.5 shrink-0" />
                    </a>
                  ) : (
                    <span className="text-slate-400 italic">No repository linked</span>
                  )}
                </div>
              </div>

              {/* Team Members */}
              <div>
                <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3">Project Team Members</h3>
                <div className="space-y-2">
                  {project.members && project.members.length > 0 ? (
                    project.members.map((member) => (
                      <div
                        key={member.id}
                        className="flex items-center justify-between p-3 rounded-xl border border-slate-200 bg-white"
                      >
                        <div className="flex items-center space-x-3">
                          <div className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center font-bold text-slate-600 text-xs">
                            {member.userFullName.charAt(0)}
                          </div>
                          <div>
                            <div className="text-sm font-semibold text-slate-900">{member.userFullName}</div>
                            <div className="text-xs text-slate-500">{member.userEmail}</div>
                          </div>
                        </div>
                        <span className="text-xs font-medium px-2.5 py-1 rounded-md bg-slate-100 text-slate-700">
                          {member.memberRole}
                        </span>
                      </div>
                    ))
                  ) : (
                    <div className="text-sm text-slate-400 italic">No additional team members listed.</div>
                  )}
                </div>
              </div>

              {/* Lifecycle Controls / Actions */}
              <div className="pt-4 border-t border-slate-100 space-y-3">
                <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500">Lifecycle State Actions</h3>
                <div className="flex flex-wrap gap-2">
                  {/* DRAFT -> SUBMITTED */}
                  {project.status === 'DRAFT' && (isCreator || isAdmin) && (
                    <button
                      onClick={() => handleStatusTransition('SUBMITTED')}
                      disabled={isTransitioning}
                      className="flex items-center space-x-1.5 px-4 py-2 rounded-xl bg-indigo-600 text-white text-sm font-semibold hover:bg-indigo-700 transition-colors shadow-sm"
                    >
                      <ArrowRightCircle className="w-4 h-4" />
                      <span>Submit for Review</span>
                    </button>
                  )}

                  {/* SUBMITTED -> UNDER_REVIEW */}
                  {project.status === 'SUBMITTED' && (isFaculty || isAdmin) && (
                    <button
                      onClick={() => handleStatusTransition('UNDER_REVIEW')}
                      disabled={isTransitioning}
                      className="flex items-center space-x-1.5 px-4 py-2 rounded-xl bg-purple-600 text-white text-sm font-semibold hover:bg-purple-700 transition-colors shadow-sm"
                    >
                      <FileClock className="w-4 h-4" />
                      <span>Move Under Review</span>
                    </button>
                  )}

                  {/* UNDER_REVIEW -> APPROVED / REJECTED */}
                  {project.status === 'UNDER_REVIEW' && (isFaculty || isAdmin) && (
                    <>
                      <button
                        onClick={() => handleStatusTransition('APPROVED')}
                        disabled={isTransitioning}
                        className="flex items-center space-x-1.5 px-4 py-2 rounded-xl bg-emerald-600 text-white text-sm font-semibold hover:bg-emerald-700 transition-colors shadow-sm"
                      >
                        <CheckCircle2 className="w-4 h-4" />
                        <span>Approve Project</span>
                      </button>
                      <button
                        onClick={() => handleStatusTransition('REJECTED')}
                        disabled={isTransitioning}
                        className="flex items-center space-x-1.5 px-4 py-2 rounded-xl bg-rose-600 text-white text-sm font-semibold hover:bg-rose-700 transition-colors shadow-sm"
                      >
                        <XCircle className="w-4 h-4" />
                        <span>Reject Project</span>
                      </button>
                    </>
                  )}

                  {/* REJECTED -> DRAFT */}
                  {project.status === 'REJECTED' && (isCreator || isAdmin) && (
                    <button
                      onClick={() => handleStatusTransition('DRAFT')}
                      disabled={isTransitioning}
                      className="flex items-center space-x-1.5 px-4 py-2 rounded-xl bg-amber-600 text-white text-sm font-semibold hover:bg-amber-700 transition-colors shadow-sm"
                    >
                      <ArrowRightCircle className="w-4 h-4" />
                      <span>Re-open as Draft</span>
                    </button>
                  )}

                  {/* APPROVED -> ARCHIVED */}
                  {project.status === 'APPROVED' && (isFaculty || isAdmin) && (
                    <button
                      onClick={() => handleStatusTransition('ARCHIVED')}
                      disabled={isTransitioning}
                      className="flex items-center space-x-1.5 px-4 py-2 rounded-xl bg-slate-700 text-white text-sm font-semibold hover:bg-slate-800 transition-colors shadow-sm"
                    >
                      <Archive className="w-4 h-4" />
                      <span>Archive Entry</span>
                    </button>
                  )}

                  {/* Delete Draft Option */}
                  {(isAdmin || (isCreator && project.status === 'DRAFT')) && (
                    <button
                      onClick={handleDelete}
                      className="flex items-center space-x-1.5 px-4 py-2 rounded-xl bg-rose-50 text-rose-700 hover:bg-rose-100 border border-rose-200 text-sm font-semibold transition-colors ml-auto"
                    >
                      <Trash2 className="w-4 h-4" />
                      <span>Delete Entry</span>
                    </button>
                  )}
                </div>
              </div>
            </>
          ) : null}
        </div>
      </div>
    </div>
  );
};
