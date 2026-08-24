import React, { useState, useEffect } from 'react';
import { Department, CreateProjectRequest, ApiResponse, PageResponse } from '../types';
import api, { getErrorMessage } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { X, Sparkles, AlertCircle } from 'lucide-react';

interface CreateProjectModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
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
    guideFacultyId: 2, // Default to Geetha
  });

  const [teamCount, setTeamCount] = useState<number>(1);
  const [teamMembers, setTeamMembers] = useState<{ email: string; name: string }[]>([
    { email: user?.email || '', name: `${user?.firstName || ''} ${user?.lastName || ''}`.trim() }
  ]);

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (isOpen) {
      fetchDepartments();
      if (user) {
        setTeamMembers((prev) => {
          const first = { email: user.email, name: `${user.firstName} ${user.lastName}`.trim() };
          const result = [first];
          for (let i = 1; i < teamCount; i++) {
            result.push(prev[i] || { email: '', name: '' });
          }
          return result;
        });
      }
    }
  }, [isOpen, user, teamCount]);

  const fetchDepartments = async () => {
    setIsLoadingDepartments(true);
    try {
      const res = await api.get<ApiResponse<PageResponse<Department>>>('/departments?size=100');
      if (res.data && res.data.data && res.data.data.content) {
        setDepartments(res.data.data.content);
        if (res.data.data.content.length > 0) {
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
    if (!formData.departmentId) {
      setError('Please select an academic department');
      return;
    }
    if (!formData.guideFacultyId) {
      setError('Please select a designated Faculty Guide for the project');
      return;
    }

    setIsSubmitting(true);
    setError(null);

    const payload = {
      ...formData,
      members: teamMembers.slice(0, teamCount).map((m, idx) => ({
        userEmail: m.email,
        memberRole: idx === 0 ? 'Project Lead / Author' : `Team Member #${idx + 1}`
      }))
    };

    try {
      await api.post('/projects', payload);
      onSuccess();
      onClose();
    } catch (err: any) {
      setError(getErrorMessage(err, 'Failed to create project draft'));
    } finally {
      setIsSubmitting(false);
    }
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
            <h2 className="text-lg font-bold text-slate-900">Create Academic Project Draft</h2>
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
                value={formData.departmentId}
                onChange={(e) => setFormData({ ...formData, departmentId: Number(e.target.value) })}
              >
                {isLoadingDepartments ? (
                  <option value={0}>Loading departments...</option>
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
                <option value={2}>Prof. Geetha (Faculty Guide)</option>
                <option value={3}>Prof. Gayathri (Faculty Guide)</option>
                <option value={4}>Prof. Manavalan (Faculty Guide)</option>
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
              <p className="text-xs text-slate-500 mt-1">
                Note: At least one document attachment or repository link is mandatory before submitting your project for faculty review.
              </p>
            </div>
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
              className="px-5 py-2 rounded-xl text-sm font-medium bg-indigo-600 hover:bg-indigo-700 text-white shadow-md transition-colors disabled:opacity-50"
            >
              {isSubmitting ? 'Saving Draft...' : 'Create Draft Project'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
