import React, { useState, useEffect } from 'react';
import { ProjectDetail, ProjectStatus, ProjectVisibility, ApiResponse, ProjectFile } from '../types';
import api, { getErrorMessage } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { 
  X, 
  ExternalLink, 
  Calendar, 
  GraduationCap, 
  Building2, 
  Trash2, 
  ArrowRightCircle, 
  CheckCircle2, 
  XCircle, 
  FileClock, 
  Archive,
  Edit3,
  Paperclip,
  Upload,
  Download,
  Lock,
  Clock,
  History
} from 'lucide-react';

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
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  // Edit Mode state
  const [isEditing, setIsEditing] = useState(false);
  const [editTitle, setEditTitle] = useState('');
  const [editAbstract, setEditAbstract] = useState('');
  const [editYear, setEditYear] = useState('');
  const [editSemester, setEditSemester] = useState(1);
  const [editType, setEditType] = useState('Capstone');
  const [editVisibility, setEditVisibility] = useState<ProjectVisibility>('PUBLIC');
  const [editRepoUrl, setEditRepoUrl] = useState('');
  const [isSavingEdit, setIsSavingEdit] = useState(false);

  // File Upload state
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [isUploadingFile, setIsUploadingFile] = useState(false);

  useEffect(() => {
    if (isOpen && projectId) {
      fetchProjectDetail();
    } else {
      setProject(null);
      setIsEditing(false);
      setError(null);
      setSuccessMsg(null);
    }
  }, [isOpen, projectId]);

  const fetchProjectDetail = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const res = await api.get<ApiResponse<ProjectDetail>>(`/projects/${projectId}`);
      if (res.data && res.data.data) {
        const p = res.data.data;
        setProject(p);
        setEditTitle(p.title);
        setEditAbstract(p.abstractText);
        setEditYear(p.academicYear);
        setEditSemester(p.semester);
        setEditType(p.projectType);
        setEditVisibility(p.visibility);
        setEditRepoUrl(p.repositoryUrl || '');
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
    setSuccessMsg(null);
    try {
      await api.patch(`/projects/${projectId}/status`, { status: targetStatus });
      setSuccessMsg(`Project status updated to ${targetStatus.replace('_', ' ')}`);
      await fetchProjectDetail();
      onUpdate();
    } catch (err: any) {
      setError(getErrorMessage(err, `Failed to transition status to ${targetStatus}`));
    } finally {
      setIsTransitioning(false);
    }
  };

  const handleSaveEdit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!projectId) return;
    setIsSavingEdit(true);
    setError(null);
    try {
      await api.put(`/projects/${projectId}`, {
        title: editTitle,
        abstractText: editAbstract,
        academicYear: editYear,
        semester: editSemester,
        projectType: editType,
        visibility: editVisibility,
        repositoryUrl: editRepoUrl,
      });
      setIsEditing(false);
      setSuccessMsg('Project updated successfully!');
      await fetchProjectDetail();
      onUpdate();
    } catch (err: any) {
      setError(getErrorMessage(err, 'Failed to update project details'));
    } finally {
      setIsSavingEdit(false);
    }
  };

  const handleFileUpload = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!projectId || !selectedFile) return;
    setIsUploadingFile(true);
    setError(null);

    const formData = new FormData();
    formData.append('file', selectedFile);

    try {
      await api.post(`/projects/${projectId}/files`, formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      setSelectedFile(null);
      setSuccessMsg('Document attachment uploaded successfully!');
      await fetchProjectDetail();
    } catch (err: any) {
      setError(getErrorMessage(err, 'Failed to upload document attachment'));
    } finally {
      setIsUploadingFile(false);
    }
  };

  const handleFileDownload = (file: ProjectFile) => {
    if (!projectId) return;
    window.open(`${api.defaults.baseURL}/projects/${projectId}/files/${file.id}/download`, '_blank');
  };

  const handleFileDelete = async (fileId: number) => {
    if (!projectId || !window.confirm('Delete this file attachment?')) return;
    try {
      await api.delete(`/projects/${projectId}/files/${fileId}`);
      setSuccessMsg('File attachment removed.');
      await fetchProjectDetail();
    } catch (err: any) {
      setError(getErrorMessage(err, 'Failed to delete file'));
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
  const canEdit = (isCreator || isAdmin) && (project?.status === 'DRAFT' || project?.status === 'REJECTED');
  const isDraftMode = project?.status === 'DRAFT';

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm">
      <div className="bg-white rounded-2xl max-w-4xl w-full shadow-2xl border border-slate-200 overflow-hidden flex flex-col max-h-[90vh]">
        {/* Header */}
        <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-slate-50/50">
          <div className="flex items-center space-x-3">
            <h2 className="text-lg font-bold text-slate-900">
              {isEditing ? 'Edit Project Entry' : 'Project Overview'}
            </h2>
            {project && getStatusBadge(project.status)}
          </div>
          <div className="flex items-center space-x-2">
            {canEdit && !isEditing && (
              <button
                onClick={() => setIsEditing(true)}
                className="flex items-center space-x-1 px-3 py-1.5 rounded-lg bg-indigo-50 text-indigo-700 text-xs font-bold border border-indigo-200 hover:bg-indigo-100 transition-colors"
              >
                <Edit3 className="w-3.5 h-3.5" />
                <span>Edit Entry</span>
              </button>
            )}
            <button
              onClick={onClose}
              className="text-slate-400 hover:text-slate-600 p-1.5 rounded-lg hover:bg-slate-100 transition-colors"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Content Area */}
        <div className="p-6 overflow-y-auto space-y-6 flex-1 text-slate-800">
          {isLoading ? (
            <div className="py-12 text-center text-slate-400 font-medium">Loading project details...</div>
          ) : error ? (
            <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-sm">
              {error}
            </div>
          ) : project ? (
            <>
              {successMsg && (
                <div className="p-3.5 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-700 text-sm font-semibold flex items-center justify-between">
                  <span>{successMsg}</span>
                  <button onClick={() => setSuccessMsg(null)} className="text-emerald-500 hover:text-emerald-700">
                    <X className="w-4 h-4" />
                  </button>
                </div>
              )}

              {/* EDIT FORM MODE */}
              {isEditing ? (
                <form onSubmit={handleSaveEdit} className="space-y-4 bg-slate-50 p-5 rounded-2xl border border-slate-200">
                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1">
                      Project Title *
                    </label>
                    <input
                      type="text"
                      required
                      className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 text-sm text-slate-900 focus:ring-2 focus:ring-indigo-500"
                      value={editTitle}
                      onChange={(e) => setEditTitle(e.target.value)}
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1">
                      Project Abstract *
                    </label>
                    <textarea
                      rows={4}
                      required
                      className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 text-sm text-slate-900 focus:ring-2 focus:ring-indigo-500"
                      value={editAbstract}
                      onChange={(e) => setEditAbstract(e.target.value)}
                    />
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                    <div>
                      <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1">
                        Academic Year *
                      </label>
                      <input
                        type="text"
                        required
                        placeholder="2025-2026"
                        className="w-full px-3.5 py-2 rounded-xl border border-slate-300 text-sm text-slate-900"
                        value={editYear}
                        onChange={(e) => setEditYear(e.target.value)}
                      />
                    </div>

                    <div>
                      <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1">
                        Semester *
                      </label>
                      <select
                        className="w-full px-3.5 py-2 rounded-xl border border-slate-300 text-sm text-slate-900 bg-white"
                        value={editSemester}
                        onChange={(e) => setEditSemester(Number(e.target.value))}
                      >
                        {[1, 2, 3, 4, 5, 6, 7, 8].map((s) => (
                          <option key={s} value={s}>Semester {s}</option>
                        ))}
                      </select>
                    </div>

                    <div>
                      <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1">
                        Project Type *
                      </label>
                      <select
                        className="w-full px-3.5 py-2 rounded-xl border border-slate-300 text-sm text-slate-900 bg-white"
                        value={editType}
                        onChange={(e) => setEditType(e.target.value)}
                      >
                        <option value="Capstone">Capstone Project</option>
                        <option value="Research Paper">Research Paper</option>
                        <option value="Thesis">Master's Thesis</option>
                        <option value="Mini Project">Mini Project</option>
                      </select>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1">
                        Visibility
                      </label>
                      <select
                        className="w-full px-3.5 py-2 rounded-xl border border-slate-300 text-sm text-slate-900 bg-white"
                        value={editVisibility}
                        onChange={(e) => setEditVisibility(e.target.value as ProjectVisibility)}
                      >
                        <option value="PUBLIC">Public (Accessible worldwide)</option>
                        <option value="DEPARTMENT_ONLY">Department Only</option>
                        <option value="PRIVATE">Private (Team only)</option>
                      </select>
                    </div>

                    <div>
                      <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1">
                        Repository URL
                      </label>
                      <input
                        type="url"
                        placeholder="https://github.com/org/repo"
                        className="w-full px-3.5 py-2 rounded-xl border border-slate-300 text-sm text-slate-900"
                        value={editRepoUrl}
                        onChange={(e) => setEditRepoUrl(e.target.value)}
                      />
                    </div>
                  </div>

                  <div className="pt-3 flex justify-end space-x-2 border-t border-slate-200">
                    <button
                      type="button"
                      onClick={() => setIsEditing(false)}
                      className="px-4 py-2 rounded-xl text-sm font-semibold text-slate-600 hover:bg-slate-200"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      disabled={isSavingEdit}
                      className="px-5 py-2 rounded-xl bg-indigo-600 text-white font-bold text-sm hover:bg-indigo-700 disabled:opacity-50"
                    >
                      {isSavingEdit ? 'Saving Changes...' : 'Save Updates'}
                    </button>
                  </div>
                </form>
              ) : (
                /* READ-ONLY DISPLAY MODE */
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

                  {/* Document Attachments Section */}
                  <div className="space-y-3 pt-2">
                    <div className="flex items-center justify-between">
                      <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 flex items-center space-x-1.5">
                        <Paperclip className="w-4 h-4 text-indigo-500" />
                        <span>Document Attachments</span>
                      </h3>
                      {!isDraftMode && (
                        <span className="inline-flex items-center space-x-1 text-xs font-semibold text-slate-500 bg-slate-100 px-2.5 py-1 rounded-md">
                          <Lock className="w-3 h-3 text-slate-400" />
                          <span>Upload Locked (Submitted)</span>
                        </span>
                      )}
                    </div>

                    {/* File list */}
                    {project.files && project.files.length > 0 ? (
                      <div className="space-y-2">
                        {project.files.map((file) => (
                          <div
                            key={file.id}
                            className="flex items-center justify-between p-3 rounded-xl border border-slate-200 bg-white hover:bg-slate-50 transition-colors"
                          >
                            <div className="flex items-center space-x-3 overflow-hidden">
                              <div className="w-9 h-9 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center shrink-0">
                                <Paperclip className="w-4 h-4" />
                              </div>
                              <div className="truncate">
                                <div className="text-sm font-semibold text-slate-900 truncate">{file.fileName}</div>
                                <div className="text-xs text-slate-400">
                                  {(file.fileSize / 1024).toFixed(1)} KB • {new Date(file.uploadedAt).toLocaleDateString()}
                                </div>
                              </div>
                            </div>

                            <div className="flex items-center space-x-2 shrink-0">
                              <button
                                onClick={() => handleFileDownload(file)}
                                className="flex items-center space-x-1 px-3 py-1.5 rounded-lg bg-indigo-50 text-indigo-700 hover:bg-indigo-100 text-xs font-semibold transition-colors"
                              >
                                <Download className="w-3.5 h-3.5" />
                                <span>Download</span>
                              </button>
                              {isDraftMode && (isCreator || isAdmin) && (
                                <button
                                  onClick={() => handleFileDelete(file.id)}
                                  className="p-1.5 rounded-lg text-rose-600 hover:bg-rose-50 transition-colors"
                                  title="Delete attachment"
                                >
                                  <Trash2 className="w-4 h-4" />
                                </button>
                              )}
                            </div>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <div className="text-sm text-slate-400 italic bg-slate-50 p-3.5 rounded-xl border border-slate-200">
                        No document attachments uploaded.
                      </div>
                    )}

                    {/* Upload form for draft mode */}
                    {isDraftMode && (isCreator || isAdmin) && (
                      <form onSubmit={handleFileUpload} className="flex items-center space-x-2 pt-1">
                        <input
                          type="file"
                          required
                          className="text-xs text-slate-600 file:mr-3 file:py-2 file:px-3.5 file:rounded-xl file:border-0 file:text-xs file:font-semibold file:bg-indigo-50 file:text-indigo-700 hover:file:bg-indigo-100 cursor-pointer"
                          onChange={(e) => setSelectedFile(e.target.files ? e.target.files[0] : null)}
                        />
                        <button
                          type="submit"
                          disabled={!selectedFile || isUploadingFile}
                          className="inline-flex items-center space-x-1 px-4 py-2 rounded-xl bg-indigo-600 text-white font-semibold text-xs hover:bg-indigo-700 disabled:opacity-40 transition-colors shrink-0"
                        >
                          <Upload className="w-3.5 h-3.5" />
                          <span>{isUploadingFile ? 'Uploading...' : 'Upload Attachment'}</span>
                        </button>
                      </form>
                    )}
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

                  {/* Database Workflow State History Timeline */}
                  <div className="space-y-3 pt-2">
                    <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 flex items-center space-x-1.5">
                      <History className="w-4 h-4 text-indigo-500" />
                      <span>Database Workflow History</span>
                    </h3>

                    {project.workflowHistory && project.workflowHistory.length > 0 ? (
                      <div className="space-y-2 relative border-l-2 border-indigo-100 ml-3 pl-4">
                        {project.workflowHistory.map((history) => (
                          <div key={history.id} className="relative space-y-1">
                            <div className="absolute -left-[23px] top-1.5 w-3 h-3 rounded-full bg-indigo-600 border-2 border-white" />
                            <div className="flex flex-wrap items-center justify-between gap-2 text-xs">
                              <div className="font-bold text-slate-800 flex items-center space-x-1.5">
                                <span>{history.fromStatus ? history.fromStatus.replace('_', ' ') : 'CREATION'}</span>
                                <span className="text-slate-400">➔</span>
                                <span className="text-indigo-600">{history.toStatus.replace('_', ' ')}</span>
                              </div>
                              <div className="text-slate-400 flex items-center space-x-1">
                                <Clock className="w-3 h-3 text-slate-400" />
                                <span>{new Date(history.createdAt).toLocaleString()}</span>
                              </div>
                            </div>
                            <div className="text-xs text-slate-500 font-medium">
                              Transitioned by: <span className="text-slate-700 font-semibold">{history.changedByFullName}</span>
                            </div>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <div className="text-sm text-slate-400 italic">No workflow transitions recorded.</div>
                    )}
                  </div>
                </>
              )}

              {/* Lifecycle State Controls / Actions */}
              {!isEditing && (
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
              )}
            </>
          ) : null}
        </div>
      </div>
    </div>
  );
};
