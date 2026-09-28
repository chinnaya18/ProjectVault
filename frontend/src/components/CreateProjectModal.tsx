import React, { useState, useEffect, useRef } from 'react';
import { CreateProjectRequest, ApiResponse, PageResponse } from '../types';
import api, { getErrorMessage } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { 
  X, 
  Sparkles, 
  AlertCircle, 
  Paperclip, 
  UploadCloud, 
  FileText, 
  Trash2, 
  Send,
  FileCheck
} from 'lucide-react';
import { formatFacultyName } from '../utils/userFormat';

interface CreateProjectModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  initialTitle?: string;
  initialAbstract?: string;
}

export const CreateProjectModal: React.FC<CreateProjectModalProps> = ({ 
  isOpen, 
  onClose, 
  onSuccess,
  initialTitle = '',
  initialAbstract = ''
}) => {
  const { user } = useAuth();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [formData, setFormData] = useState<CreateProjectRequest>({
    title: initialTitle,
    abstractText: initialAbstract,
    academicYear: '2025-2026',
    semester: 6,
    projectType: 'CAPSTONE',
    visibility: 'PUBLIC',
    departmentId: 1, // Default to MCA Department
    repositoryUrl: '',
    guideFacultyId: 20, // Default to Geetha (Faculty Guide)
  });

  const [teamCount, setTeamCount] = useState<number>(1);
  const [teamMembers, setTeamMembers] = useState<{ email: string; name: string }[]>([
    { email: user?.email || '', name: user?.name || '' }
  ]);

  // File Attachments State (Synopsis, SRS, Abstract, Documents)
  const [attachedFiles, setAttachedFiles] = useState<File[]>([]);

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitStatus, setSubmitStatus] = useState<string>('');
  const [error, setError] = useState<string | null>(null);

  const [facultyList, setFacultyList] = useState<{ id: number; name: string }[]>([]);

  useEffect(() => {
    if (isOpen) {
      fetchFaculty();
      if (user) {
        setTeamMembers((prev) => {
          const first = { email: user.email, name: user.name || '' };
          const result = [first];
          for (let i = 1; i < teamCount; i++) {
            result.push(prev[i] || { email: '', name: '' });
          }
          return result;
        });
      }
    }
  }, [isOpen, user, teamCount]);

  const fetchFaculty = async () => {
    try {
      const res = await api.get<ApiResponse<PageResponse<any>>>('/users?size=100');
      if (res.data && res.data.data && res.data.data.content) {
        const faculties = res.data.data.content
          .filter((u: any) => u.role === 'FACULTY')
          .map((u: any) => ({
            id: u.id,
            name: `${formatFacultyName(u.name)} (${u.email})`
          }));
        if (faculties.length > 0) {
          setFacultyList(faculties);
        }
      }
    } catch (err) {
      console.log('Using default faculty list:', err);
    }
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      const newFiles = Array.from(e.target.files);
      setAttachedFiles((prev) => [...prev, ...newFiles]);
      // Reset input value so same file can be re-selected if needed
      e.target.value = '';
    }
  };

  const handleRemoveFile = (index: number) => {
    setAttachedFiles((prev) => prev.filter((_, idx) => idx !== index));
  };

  const getDocTypeBadge = (filename: string) => {
    const lower = filename.toLowerCase();
    if (lower.includes('synopsis')) return { label: 'Synopsis Document', color: 'bg-purple-100 text-purple-800 border-purple-200' };
    if (lower.includes('srs') || lower.includes('requirement')) return { label: 'SRS Specification', color: 'bg-blue-100 text-blue-800 border-blue-200' };
    if (lower.includes('abstract') || lower.includes('report')) return { label: 'Project Report / Abstract', color: 'bg-emerald-100 text-emerald-800 border-emerald-200' };
    return { label: 'Document Attachment', color: 'bg-slate-100 text-slate-700 border-slate-200' };
  };

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent, submitDirectly: boolean = false) => {
    e.preventDefault();
    if (!formData.departmentId) {
      setError('Please select an academic department');
      return;
    }
    if (!formData.guideFacultyId) {
      setError('Please select a designated Faculty Guide for the project');
      return;
    }

    setIsSubmitting(true);
    setSubmitStatus('Creating project draft...');
    setError(null);

    const payload = {
      ...formData,
      members: teamMembers.slice(0, teamCount).map((_, idx) => ({
        userId: user?.id || 1,
        memberRole: idx === 0 ? 'Project Lead / Author' : `Team Member #${idx + 1}`
      }))
    };

    try {
      // 1. Create Project Entry
      const res = await api.post<ApiResponse<any>>('/projects', payload);
      const createdProject = res.data.data;
      const createdId = createdProject.id;

      // 2. Upload Attached Files (Synopsis, SRS, Reports)
      if (attachedFiles.length > 0) {
        for (let i = 0; i < attachedFiles.length; i++) {
          setSubmitStatus(`Uploading attachment ${i + 1} of ${attachedFiles.length}: ${attachedFiles[i].name}...`);
          const fileFormData = new FormData();
          fileFormData.append('file', attachedFiles[i]);
          await api.post(`/projects/${createdId}/files`, fileFormData, {
            headers: { 'Content-Type': 'multipart/form-data' },
          });
        }
      }

      // 3. If "Submit for Review" is chosen, transition status to SUBMITTED
      if (submitDirectly) {
        setSubmitStatus('Submitting for Faculty Guide review & AI scan...');
        await api.patch(`/projects/${createdId}/status`, {
          status: 'SUBMITTED',
          feedback: 'Submitted via Project Creation Wizard'
        });
      }

      onSuccess();
      onClose();
    } catch (err: any) {
      setError(getErrorMessage(err, 'Failed to create project submission'));
    } finally {
      setIsSubmitting(false);
      setSubmitStatus('');
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs">
      <div className="bg-white rounded-2xl max-w-2xl w-full shadow-2xl border border-slate-200 overflow-hidden flex flex-col max-h-[90vh]">
        {/* Header */}
        <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-slate-50/50">
          <div className="flex items-center space-x-2">
            <div className="w-8 h-8 rounded-lg bg-indigo-100 text-indigo-700 flex items-center justify-center font-bold">
              <Sparkles className="w-4 h-4" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-slate-900">New Project Submission</h2>
              <p className="text-xs text-slate-500">Provide project details, repository link, and upload Synopsis / SRS documents</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="text-slate-400 hover:text-slate-600 p-1.5 rounded-lg hover:bg-slate-100 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Form Body */}
        <form onSubmit={(e) => handleSubmit(e, false)} className="p-6 overflow-y-auto space-y-5 flex-1">
          {error && (
            <div className="p-3.5 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-sm flex items-start space-x-2.5">
              <AlertCircle className="w-5 h-5 shrink-0 mt-0.5" />
              <span>{error}</span>
            </div>
          )}

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
              Project Title *
            </label>
            <input
              type="text"
              required
              placeholder="e.g. IoT Automated Smart Irrigation and Soil Moisture Analytics System"
              className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-sm text-slate-900"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
            />
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
              Abstract Summary *
            </label>
            <textarea
              required
              rows={4}
              placeholder="Provide a comprehensive abstract of your project objectives, methodology, and expected results..."
              className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-sm text-slate-900 resize-y"
              value={formData.abstractText}
              onChange={(e) => setFormData({ ...formData, abstractText: e.target.value })}
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                Department
              </label>
              <div className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 bg-slate-50 text-sm font-semibold text-indigo-900 flex items-center justify-between">
                <span>Computer Applications (MCA)</span>
                <span className="text-[10px] font-bold bg-indigo-100 text-indigo-700 px-2 py-0.5 rounded">Dept #1</span>
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                Academic Year *
              </label>
              <input
                type="text"
                required
                placeholder="2025-2026"
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-sm text-slate-900"
                value={formData.academicYear}
                onChange={(e) => setFormData({ ...formData, academicYear: e.target.value })}
              />
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                Semester *
              </label>
              <select
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-sm text-slate-900 bg-white"
                value={formData.semester}
                onChange={(e) => setFormData({ ...formData, semester: Number(e.target.value) })}
              >
                {[1, 2, 3, 4, 5, 6, 7, 8].map((s) => (
                  <option key={s} value={s}>
                    Semester {s}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                Project Type *
              </label>
              <select
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-sm text-slate-900 bg-white"
                value={formData.projectType}
                onChange={(e) => setFormData({ ...formData, projectType: e.target.value })}
              >
                <option value="MINI_PROJECT">Mini Project</option>
                <option value="CAPSTONE">Capstone Project</option>
                <option value="THESIS">Master Thesis</option>
                <option value="RESEARCH">Research Work</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                Faculty Guide *
              </label>
              <select
                required
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-sm text-slate-900 bg-white"
                value={formData.guideFacultyId || ''}
                onChange={(e) => setFormData({ ...formData, guideFacultyId: Number(e.target.value) })}
              >
                <option value="">Select Designated Faculty Guide</option>
                {facultyList.length > 0 ? (
                  facultyList.map((f) => (
                    <option key={f.id} value={f.id}>
                      {f.name}
                    </option>
                  ))
                ) : (
                  <>
                    <option value={20}>Ms. Geetha (Faculty Guide)</option>
                    <option value={21}>Ms. Gayathri (Faculty Guide)</option>
                    <option value={22}>Mr. Manavalan (Faculty Guide)</option>
                  </>
                )}
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                Visibility Scope
              </label>
              <select
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-sm text-slate-900 bg-white"
                value={formData.visibility}
                onChange={(e) => setFormData({ ...formData, visibility: e.target.value as any })}
              >
                <option value="PUBLIC">Public (All Department Students & Faculty)</option>
                <option value="DEPARTMENT_ONLY">Department Only</option>
                <option value="PRIVATE">Private Draft</option>
              </select>
            </div>

            <div className="sm:col-span-2">
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                GitHub / Git Repository URL
              </label>
              <input
                type="url"
                placeholder="https://github.com/projectvault/smart-irrigation-iot.git"
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-sm text-slate-900"
                value={formData.repositoryUrl || ''}
                onChange={(e) => setFormData({ ...formData, repositoryUrl: e.target.value })}
              />
              <p className="text-xs text-slate-500 mt-1">
                Note: At least one document attachment (Synopsis/SRS) or repository link is required before submission.
              </p>
            </div>
          </div>

          {/* ============================================================ */}
          {/* Document Attachments Section (Synopsis, SRS, PDF, DOCX)     */}
          {/* ============================================================ */}
          <div className="pt-4 border-t border-slate-200 space-y-3">
            <div className="flex items-center justify-between">
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-800 flex items-center gap-1.5">
                  <Paperclip className="w-4 h-4 text-indigo-600" />
                  <span>Project Document Attachments (Synopsis, SRS, Reports)</span>
                </label>
                <p className="text-xs text-slate-500">
                  Attach your project Synopsis, SRS, and specification files (.pdf, .docx, .doc, .txt)
                </p>
              </div>
              <span className="text-xs font-semibold text-indigo-700 bg-indigo-50 px-2.5 py-1 rounded-full border border-indigo-200">
                {attachedFiles.length} file{attachedFiles.length === 1 ? '' : 's'} selected
              </span>
            </div>

            {/* Hidden File Input */}
            <input
              type="file"
              ref={fileInputRef}
              multiple
              accept=".pdf,.doc,.docx,.txt"
              onChange={handleFileSelect}
              className="hidden"
            />

            {/* Upload Click Area */}
            <div
              onClick={() => fileInputRef.current?.click()}
              className="border-2 border-dashed border-indigo-200 hover:border-indigo-400 bg-indigo-50/30 hover:bg-indigo-50/60 rounded-xl p-4 text-center cursor-pointer transition-colors space-y-1.5"
            >
              <div className="w-10 h-10 mx-auto rounded-full bg-indigo-100 text-indigo-600 flex items-center justify-center">
                <UploadCloud className="w-5 h-5" />
              </div>
              <div className="text-xs font-bold text-indigo-950">
                Click to attach Synopsis, SRS, or Abstract documents
              </div>
              <div className="text-[11px] text-slate-500">
                Supports PDF, DOCX, DOC, TXT (Up to 25MB per file)
              </div>
            </div>

            {/* Attached Files List */}
            {attachedFiles.length > 0 && (
              <div className="space-y-2 pt-1">
                {attachedFiles.map((file, index) => {
                  const badge = getDocTypeBadge(file.name);
                  return (
                    <div
                      key={index}
                      className="flex items-center justify-between p-2.5 rounded-xl border border-slate-200 bg-slate-50/80 hover:bg-slate-100/80 transition-colors"
                    >
                      <div className="flex items-center space-x-2.5 min-w-0">
                        <div className="w-8 h-8 rounded-lg bg-white border border-slate-200 text-indigo-600 flex items-center justify-center shrink-0">
                          <FileText className="w-4 h-4" />
                        </div>
                        <div className="truncate">
                          <div className="text-xs font-semibold text-slate-900 truncate">{file.name}</div>
                          <div className="flex items-center gap-2 mt-0.5">
                            <span className="text-[10px] text-slate-400">
                              {(file.size / 1024).toFixed(1)} KB
                            </span>
                            <span className={`text-[10px] font-bold px-1.5 py-0.2 rounded border ${badge.color}`}>
                              {badge.label}
                            </span>
                          </div>
                        </div>
                      </div>

                      <button
                        type="button"
                        onClick={() => handleRemoveFile(index)}
                        className="p-1.5 text-slate-400 hover:text-rose-600 rounded-lg hover:bg-rose-50 transition-colors shrink-0 ml-2"
                        title="Remove file attachment"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          {/* Team Members Section */}
          <div className="pt-4 border-t border-slate-200 space-y-3">
            <div className="flex items-center justify-between">
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-700">
                Project Team Size & Members
              </label>
              <select
                className="px-3 py-1 rounded-lg border border-slate-300 text-xs font-semibold bg-white"
                value={teamCount}
                onChange={(e) => setTeamCount(Number(e.target.value))}
              >
                <option value={1}>1 Member (Individual Project)</option>
                <option value={2}>2 Members Team</option>
                <option value={3}>3 Members Team</option>
                <option value={4}>4 Members Team</option>
              </select>
            </div>

            <div className="space-y-2">
              {Array.from({ length: teamCount }).map((_, index) => (
                <div key={index} className="grid grid-cols-1 sm:grid-cols-2 gap-3 bg-slate-50 p-3 rounded-xl border border-slate-200">
                  <div>
                    <label className="block text-[10px] font-bold uppercase text-slate-500 mb-1">
                      Member #{index + 1} Official College Email *
                    </label>
                    <input
                      type="email"
                      required
                      placeholder={`25mx10${index + 1}@university.edu`}
                      className="w-full px-3 py-1.5 rounded-lg border border-slate-300 text-xs text-slate-900 bg-white"
                      value={teamMembers[index]?.email || ''}
                      onChange={(e) => {
                        const updated = [...teamMembers];
                        updated[index] = { ...updated[index], email: e.target.value };
                        setTeamMembers(updated);
                      }}
                    />
                  </div>
                  <div>
                    <label className="block text-[10px] font-bold uppercase text-slate-500 mb-1">
                      Member #{index + 1} Full Name *
                    </label>
                    <input
                      type="text"
                      required
                      placeholder={index === 0 ? 'Your Full Name' : `Team Member ${index + 1} Name`}
                      className="w-full px-3 py-1.5 rounded-lg border border-slate-300 text-xs text-slate-900 bg-white"
                      value={teamMembers[index]?.name || ''}
                      onChange={(e) => {
                        const updated = [...teamMembers];
                        updated[index] = { ...updated[index], name: e.target.value };
                        setTeamMembers(updated);
                      }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Progress / Submission Status Banner */}
          {submitStatus && (
            <div className="p-3 rounded-xl bg-indigo-50 border border-indigo-200 text-indigo-900 text-xs font-semibold flex items-center space-x-2 animate-pulse">
              <FileCheck className="w-4 h-4 text-indigo-600" />
              <span>{submitStatus}</span>
            </div>
          )}

          {/* Modal Actions */}
          <div className="pt-4 border-t border-slate-100 flex flex-wrap items-center justify-end gap-2.5">
            <button
              type="button"
              onClick={onClose}
              disabled={isSubmitting}
              className="px-4 py-2 rounded-xl text-sm font-medium text-slate-600 hover:bg-slate-100 transition-colors disabled:opacity-50"
            >
              Cancel
            </button>
            
            <button
              type="button"
              disabled={isSubmitting}
              onClick={(e) => handleSubmit(e, false)}
              className="px-4 py-2 rounded-xl text-sm font-medium bg-slate-100 hover:bg-slate-200 text-slate-800 border border-slate-300 shadow-xs transition-colors disabled:opacity-50"
            >
              {isSubmitting ? 'Processing...' : 'Save as Draft'}
            </button>

            <button
              type="button"
              disabled={isSubmitting}
              onClick={(e) => handleSubmit(e, true)}
              className="flex items-center space-x-1.5 px-5 py-2 rounded-xl text-sm font-semibold bg-indigo-600 hover:bg-indigo-700 text-white shadow-md shadow-indigo-200 transition-colors disabled:opacity-50"
            >
              <Send className="w-4 h-4" />
              <span>{isSubmitting ? 'Submitting...' : 'Submit for Faculty Review'}</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
