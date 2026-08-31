import React, { useState, useEffect } from 'react';
import { Department, CreateProjectRequest, ApiResponse, PageResponse, User } from '../types';
import api, { getErrorMessage } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { X, Sparkles, AlertCircle, Paperclip, FileText, Trash2, CheckCircle2 } from 'lucide-react';
import { formatFacultyName } from '../utils/userFormat';

interface CreateProjectModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

interface TeamMemberItem {
  userId?: number;
  email: string;
  name: string;
}

export const CreateProjectModal: React.FC<CreateProjectModalProps> = ({ isOpen, onClose, onSuccess }) => {
  const { user } = useAuth();
  const [departments, setDepartments] = useState<Department[]>([]);
  const [isLoadingDepartments, setIsLoadingDepartments] = useState(false);

  const [formData, setFormData] = useState<CreateProjectRequest>({
    title: '',
    abstractText: '',
    academicYear: '2025-2026',
    semester: 6,
    projectType: 'CAPSTONE',
    visibility: 'PUBLIC',
    departmentId: 0,
    repositoryUrl: '',
    guideFacultyId: 0,
  });

  const [teamCount, setTeamCount] = useState<number>(1);
  const [teamMembers, setTeamMembers] = useState<TeamMemberItem[]>([
    { userId: user?.id, email: user?.email || '', name: user?.name || '' }
  ]);

  const [attachmentFile, setAttachmentFile] = useState<File | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [facultyList, setFacultyList] = useState<{ id: number; name: string }[]>([]);
  const [isLoadingFaculty, setIsLoadingFaculty] = useState(false);
  const [registeredStudents, setRegisteredStudents] = useState<User[]>([]);

  useEffect(() => {
    if (isOpen) {
      fetchDepartments();
      fetchFaculty();
      fetchStudents();
      if (user) {
        setTeamMembers((prev) => {
          const first: TeamMemberItem = { userId: user.id, email: user.email, name: user.name || '' };
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
    setIsLoadingFaculty(true);
    try {
      // First try dedicated /faculty endpoint
      let faculties: { id: number; name: string }[] = [];
      try {
        const res = await api.get<ApiResponse<any>>('/users/faculty');
        const data = res.data?.data;
        const list = Array.isArray(data) ? data : (data?.content || []);
        faculties = list.map((u: any) => ({
          id: u.id,
          name: `${formatFacultyName(u.name || (u.firstName ? `${u.firstName} ${u.lastName}` : 'Faculty'))} (${u.email})`
        }));
      } catch {
        // Fallback to /users?role=FACULTY
        const res = await api.get<ApiResponse<PageResponse<any>>>('/users?role=FACULTY&size=100');
        if (res.data?.data?.content) {
          faculties = res.data.data.content.map((u: any) => ({
            id: u.id,
            name: `${formatFacultyName(u.name || (u.firstName ? `${u.firstName} ${u.lastName}` : 'Faculty'))} (${u.email})`
          }));
        }
      }

      if (faculties.length > 0) {
        setFacultyList(faculties);
        // Default select first faculty if not selected
        if (!formData.guideFacultyId || formData.guideFacultyId <= 0) {
          setFormData((prev) => ({ ...prev, guideFacultyId: faculties[0].id }));
        }
      }
    } catch (err) {
      console.error('Failed to load faculty guides:', err);
    } finally {
      setIsLoadingFaculty(false);
    }
  };

  const fetchStudents = async () => {
    try {
      let students: User[] = [];
      try {
        const res = await api.get<ApiResponse<any>>('/users/students');
        const data = res.data?.data;
        students = Array.isArray(data) ? data : (data?.content || []);
      } catch {
        const res = await api.get<ApiResponse<PageResponse<User>>>('/users?role=STUDENT&size=100');
        if (res.data?.data?.content) {
          students = res.data.data.content;
        }
      }
      setRegisteredStudents(students.filter(s => s.id !== user?.id));
    } catch (err) {
      console.error('Failed to load student directory:', err);
    }
  };

  const fetchDepartments = async () => {
    setIsLoadingDepartments(true);
    try {
      const res = await api.get<ApiResponse<PageResponse<Department>>>('/departments?size=100');
      if (res.data && res.data.data && res.data.data.content) {
        setDepartments(res.data.data.content);
        if (res.data.data.content.length > 0 && (!formData.departmentId || formData.departmentId <= 0)) {
          setFormData((prev) => ({ ...prev, departmentId: res.data.data.content[0].id }));
        }
      }
    } catch (err) {
      console.error('Failed to load departments:', err);
    } finally {
      setIsLoadingDepartments(false);
    }
  };

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.departmentId || formData.departmentId <= 0) {
      setError('Please select an Academic Department');
      return;
    }
    if (!formData.guideFacultyId || formData.guideFacultyId <= 0) {
      setError('Please select a designated Faculty Guide for the project');
      return;
    }

    setIsSubmitting(true);
    setError(null);

    const payload = {
      ...formData,
      members: teamMembers.slice(0, teamCount).map((m, idx) => ({
        userId: m.userId || (idx === 0 ? user?.id : undefined),
        email: m.email?.trim() || undefined,
        memberRole: idx === 0 ? 'Project Lead / Author' : `Team Member #${idx + 1}`
      }))
    };

    try {
      const res = await api.post<ApiResponse<any>>('/projects', payload);
      const createdProject = res.data?.data;

      // Upload file attachment immediately if selected
      if (attachmentFile && createdProject?.id) {
        try {
          const fileData = new FormData();
          fileData.append('file', attachmentFile);
          await api.post(`/projects/${createdProject.id}/files`, fileData, {
            headers: { 'Content-Type': 'multipart/form-data' },
          });
        } catch (uploadErr) {
          console.warn('Draft created but file attachment failed:', uploadErr);
        }
      }

      onSuccess();
      onClose();
    } catch (err: any) {
      setError(getErrorMessage(err, 'Failed to create project draft'));
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleStudentSelect = (index: number, studentIdStr: string) => {
    const studentId = Number(studentIdStr);
    const selected = registeredStudents.find(s => s.id === studentId);
    const updated = [...teamMembers];
    if (selected) {
      updated[index] = {
        userId: selected.id,
        email: selected.email,
        name: selected.name || selected.email
      };
    } else {
      updated[index] = { email: '', name: '' };
    }
    setTeamMembers(updated);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm">
      <div className="bg-white rounded-2xl max-w-2xl w-full shadow-2xl border border-slate-200 overflow-hidden flex flex-col max-h-[90vh]">
        {/* Header */}
        <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-slate-50/50">
          <div className="flex items-center space-x-2">
            <div className="w-8 h-8 rounded-lg bg-indigo-100 text-indigo-700 flex items-center justify-center font-bold">
              <Sparkles className="w-4 h-4" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-slate-900">Create Academic Project Draft</h2>
              <p className="text-xs text-slate-500">Save as draft now, submit for faculty review when ready.</p>
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
        <form onSubmit={handleSubmit} className="p-6 overflow-y-auto space-y-4 flex-1">
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
              placeholder="e.g. AI-Powered Smart Grid Energy Optimization"
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
                Department *
              </label>
              <select
                required
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-sm text-slate-900 bg-white"
                value={formData.departmentId || ''}
                onChange={(e) => setFormData({ ...formData, departmentId: Number(e.target.value) })}
              >
                <option value="">Select Academic Department *</option>
                {isLoadingDepartments ? (
                  <option value="" disabled>Loading departments...</option>
                ) : (
                  departments.map((dept) => (
                    <option key={dept.id} value={dept.id}>
                      {dept.name} ({dept.code})
                    </option>
                  ))
                )}
              </select>
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
                <option value="CAPSTONE">Capstone Project</option>
                <option value="MINI_PROJECT">Mini Project</option>
                <option value="THESIS">Master Thesis</option>
                <option value="RESEARCH">Research Work</option>
              </select>
            </div>

            <div className="sm:col-span-2">
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                Faculty Guide *
              </label>
              <select
                required
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-sm text-slate-900 bg-white"
                value={formData.guideFacultyId || ''}
                onChange={(e) => setFormData({ ...formData, guideFacultyId: Number(e.target.value) })}
              >
                <option value="">Select Designated Faculty Guide *</option>
                {isLoadingFaculty ? (
                  <option value="" disabled>Loading faculty guides...</option>
                ) : facultyList.length > 0 ? (
                  facultyList.map((f) => (
                    <option key={f.id} value={f.id}>
                      {f.name}
                    </option>
                  ))
                ) : (
                  <option value="" disabled>No faculty guides found. Please check backend.</option>
                )}
              </select>
            </div>

            <div className="sm:col-span-2">
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                Repository Link (GitHub / GitLab / Bitbucket)
              </label>
              <input
                type="url"
                placeholder="https://github.com/org/repo"
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-sm text-slate-900"
                value={formData.repositoryUrl || ''}
                onChange={(e) => setFormData({ ...formData, repositoryUrl: e.target.value })}
              />
            </div>
          </div>

          {/* Document Attachment Upload Section */}
          <div className="pt-4 border-t border-slate-200 space-y-2">
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-700">
              Project Document Attachment (PDF, DOCX, ZIP - Optional on Draft)
            </label>
            <p className="text-xs text-slate-500">
              Attach your project report, synopsis, or archive. (At least one document attachment or repository link is mandatory before submitting for review).
            </p>

            {attachmentFile ? (
              <div className="flex items-center justify-between p-3 rounded-xl border border-indigo-200 bg-indigo-50/50">
                <div className="flex items-center space-x-3 truncate">
                  <div className="w-8 h-8 rounded-lg bg-indigo-100 text-indigo-700 flex items-center justify-center shrink-0 font-bold">
                    <FileText className="w-4 h-4" />
                  </div>
                  <div className="truncate">
                    <div className="text-xs font-bold text-slate-900 truncate">{attachmentFile.name}</div>
                    <div className="text-[10px] text-slate-500">{(attachmentFile.size / 1024).toFixed(1)} KB</div>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => setAttachmentFile(null)}
                  className="p-1.5 rounded-lg text-rose-600 hover:bg-rose-100 transition-colors shrink-0"
                  title="Remove file"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            ) : (
              <div className="relative border-2 border-dashed border-slate-300 hover:border-indigo-400 rounded-xl p-4 text-center transition-colors bg-slate-50/50">
                <input
                  type="file"
                  accept=".pdf,.doc,.docx,.zip,.rar,.tar.gz,.txt,.ppt,.pptx"
                  className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                  onChange={(e) => {
                    if (e.target.files && e.target.files[0]) {
                      setAttachmentFile(e.target.files[0]);
                    }
                  }}
                />
                <div className="flex flex-col items-center justify-center space-y-1">
                  <Paperclip className="w-6 h-6 text-indigo-500" />
                  <span className="text-xs font-semibold text-slate-700">
                    Click to select or drag & drop project report/document
                  </span>
                  <span className="text-[11px] text-slate-400">PDF, DOCX, ZIP, PPTX up to 50MB</span>
                </div>
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
                <div key={index} className="bg-slate-50 p-3.5 rounded-xl border border-slate-200 space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-bold text-slate-700">
                      {index === 0 ? 'Member #1 (Project Lead / Author)' : `Member #${index + 1}`}
                    </span>
                    {index === 0 && (
                      <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-indigo-100 text-indigo-700">
                        Current User (Lead)
                      </span>
                    )}
                  </div>

                  {index === 0 ? (
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                      <div className="p-2 bg-white rounded-lg border border-slate-200 text-slate-700 font-medium">
                        {user?.email || 'Your Email'}
                      </div>
                      <div className="p-2 bg-white rounded-lg border border-slate-200 text-slate-700 font-medium">
                        {user?.name || 'Your Name'}
                      </div>
                    </div>
                  ) : (
                    <div className="space-y-2">
                      {registeredStudents.length > 0 && (
                        <div>
                          <label className="block text-[10px] font-bold uppercase text-slate-500 mb-1">
                            Quick Select Registered Student:
                          </label>
                          <select
                            className="w-full px-3 py-1.5 rounded-lg border border-slate-300 text-xs text-slate-900 bg-white"
                            value={teamMembers[index]?.userId || ''}
                            onChange={(e) => handleStudentSelect(index, e.target.value)}
                          >
                            <option value="">-- Select Teammate from Directory or Type below --</option>
                            {registeredStudents.map((s) => (
                              <option key={s.id} value={s.id}>
                                {s.name || s.email} ({s.email}) {s.rollNo ? `[${s.rollNo}]` : ''}
                              </option>
                            ))}
                          </select>
                        </div>
                      )}

                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <div>
                          <label className="block text-[10px] font-bold uppercase text-slate-500 mb-1">
                            Teammate Email *
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
                            Teammate Full Name
                          </label>
                          <input
                            type="text"
                            placeholder={`Team Member ${index + 1} Name`}
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
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>

          <div className="pt-4 border-t border-slate-100 flex items-center justify-end space-x-3">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 rounded-xl text-sm font-medium text-slate-600 hover:bg-slate-100 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="px-5 py-2 rounded-xl text-sm font-medium bg-indigo-600 hover:bg-indigo-700 text-white shadow-md transition-colors disabled:opacity-50 flex items-center space-x-2"
            >
              {isSubmitting ? (
                <span>Creating Draft...</span>
              ) : (
                <>
                  <CheckCircle2 className="w-4 h-4" />
                  <span>Create Draft Project</span>
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
