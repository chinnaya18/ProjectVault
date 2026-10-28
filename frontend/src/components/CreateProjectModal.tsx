import React, { useState, useEffect, useRef } from 'react';
import { CreateProjectRequest, ApiResponse, PageResponse } from '../types';
import api, { getErrorMessage } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { formatFacultyName } from '../utils/userFormat';
import { 
  X, 
  Sparkles, 
  AlertCircle, 
  Paperclip, 
  UploadCloud, 
  FileText, 
  Trash2, 
  Send,
  FileCheck,
  Lock
} from 'lucide-react';

interface CreateProjectModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: () => void;
  initialTitle?: string;
  initialAbstract?: string;
}

const getMcaAcademicYear = (): string => {
  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth(); // 0 is January, 5 is June
  return month >= 5 ? `${year}-${year + 1}` : `${year - 1}-${year}`;
};

export const DEFAULT_FACULTY_LIST = [
  { id: 34, name: 'Dr. Ilayaraja N (nir.mca@psgtech.ac.in) - Assistant Professor & Head (i/c)' },
  { id: 35, name: 'Dr. Manavalan R (vrm.mca@psgtech.ac.in) - Associate Professor' },
  { id: 36, name: 'Mrs. Kalyani A (akk.mca@psgtech.ac.in) - Assistant Professor (Sl. Gr.)' },
  { id: 37, name: 'Dr. Chitra A (ac.mca@psgtech.ac.in) - Professor' },
  { id: 38, name: 'Dr. Sankar A (dras.mca@psgtech.ac.in) - Professor' },
  { id: 39, name: 'Dr. Geetha N (sng.mca@psgtech.ac.in) - Assistant Professor (Sl. Gr.)' },
  { id: 40, name: 'Dr. Bhama S (sba.mca@psgtech.ac.in) - Assistant Professor (Sl. Gr.)' },
  { id: 41, name: 'Dr. Subathra M (msa.mca@psgtech.ac.in) - Assistant Professor (Sl. Gr.)' },
  { id: 42, name: 'Mr. Sundar C (csr.mca@psgtech.ac.in) - Assistant Professor (Sl. Gr.)' },
  { id: 43, name: 'Dr. Umarani V (vur.mca@psgtech.ac.in) - Assistant Professor (Sl. Gr.)' },
  { id: 44, name: 'Mrs. Gowri Thangam J (jgt.mca@psgtech.ac.in) - Assistant Professor (Sr. Gr.)' },
  { id: 45, name: 'Mrs. Gayathri K (kgi.mca@psgtech.ac.in) - Assistant Professor (Sr. Gr.)' },
  { id: 46, name: 'Ms. Aruna R (ran.mca@psgtech.ac.in) - Assistant Professor' },
  { id: 47, name: 'Dr. Venkatesan V (vvn.mca@psgtech.ac.in) - Assistant Professor (Sl. Gr.)' },
  { id: 48, name: 'Mrs. Manoranjitham A (amr.mca@psgtech.ac.in) - Assistant Professor (Sl. Gr.)' },
  { id: 49, name: 'Mrs. Rajeswari N (nrj.mca@psgtech.ac.in) - Assistant Professor (Sr. Gr.)' },
  { id: 50, name: 'Mrs. Aarthi Mai A S (asa.mca@psgtech.ac.in) - Assistant Professor' },
  { id: 51, name: 'Dr. Bhuvaneswari A (abh.mca@psgtech.ac.in) - Assistant Professor' },
];

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
    academicYear: getMcaAcademicYear(),
    semester: 4,
    projectType: 'CAPSTONE',
    visibility: 'PUBLIC',
    departmentId: 1, // Default to MCA Department
    repositoryUrl: '',
    githubToken: '',
    guideFacultyId: 34, // Default to Dr. Ilayaraja N (HOD i/c)
  });

  const [isPrivateRepo, setIsPrivateRepo] = useState<boolean>(false);
  const [teamCount, setTeamCount] = useState<number>(1);
  const [teamMembers, setTeamMembers] = useState<{ email: string; name: string }[]>([
    { email: user?.email || '', name: user?.name || '' }
  ]);

  // File Attachments State (Synopsis, SRS, Abstract, Documents)
  const [attachedFiles, setAttachedFiles] = useState<File[]>([]);

  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitStatus, setSubmitStatus] = useState<string>('');
  const [error, setError] = useState<string | null>(null);

  const [facultyList, setFacultyList] = useState<{ id: number; name: string }[]>(DEFAULT_FACULTY_LIST);

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
      const res = await api.get<ApiResponse<PageResponse<any>>>('/users?role=FACULTY&size=100');
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
    if (lower.endsWith('.zip') || lower.includes('source') || lower.includes('code')) return { label: 'Source Code Archive (.zip)', color: 'bg-emerald-100 text-emerald-800 border-emerald-200' };
    if (lower.includes('synopsis')) return { label: 'Synopsis Document', color: 'bg-purple-100 text-purple-800 border-purple-200' };
    if (lower.includes('srs') || lower.includes('requirement')) return { label: 'SRS Specification', color: 'bg-blue-100 text-blue-800 border-blue-200' };
    if (lower.includes('abstract') || lower.includes('report')) return { label: 'Project Report / Abstract', color: 'bg-indigo-100 text-indigo-800 border-indigo-200' };
    return { label: 'Document Attachment', color: 'bg-slate-100 text-slate-700 border-slate-200' };
  };

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent, submitDirectly: boolean = false) => {
    e?.preventDefault();
    if (!formData.title?.trim()) {
      setError('Project Title is required');
      return;
    }
    if (!formData.abstractText?.trim()) {
      setError('Project Abstract summary is required');
      return;
    }
    if (!formData.academicYear?.trim()) {
      setError('Academic Year is required (e.g. 2025-2026)');
      return;
    }
    if (!formData.semester) {
      setError('Semester selection is required (Semesters 1-4)');
      return;
    }
    if (!formData.projectType?.trim()) {
      setError('Project Type is required');
      return;
    }
    if (!formData.departmentId) {
      setError('Please select an academic department');
      return;
    }
    if (!formData.guideFacultyId) {
      setError('Please select a designated Faculty Guide for the project');
      return;
    }
    const hasFiles = attachedFiles.length > 0;
    if (!formData.repositoryUrl?.trim() && !hasFiles) {
      setError('Please provide a Git Repository URL or attach your project documents / source code (.zip) below.');
      return;
    }

    setIsSubmitting(true);
    setSubmitStatus('Creating project draft...');
    setError(null);

    const payload = {
      ...formData,
      visibility: 'PUBLIC' as const,
      members: teamMembers.slice(0, teamCount).map((m, idx) => ({
        userId: idx === 0 ? (user?.id || 1) : undefined,
        email: m.email?.trim() || undefined,
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
                Semester (2-Year MCA) *
              </label>
              <select
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-sm text-slate-900 bg-white"
                value={formData.semester}
                onChange={(e) => setFormData({ ...formData, semester: Number(e.target.value) })}
              >
                {[1, 2, 3, 4].map((s) => (
                  <option key={s} value={s}>
                    Semester {s} {s <= 2 ? '(First Year MCA)' : '(Second Year MCA - Project)'}
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
                {facultyList.map((f) => (
                  <option key={f.id} value={f.id}>
                    {f.name}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                Visibility Scope
              </label>
              <div className="w-full px-3.5 py-2.5 rounded-xl border border-emerald-200 bg-emerald-50/60 text-xs font-semibold text-emerald-800 flex items-center justify-between">
                <span>Auto-Public upon Faculty Approval</span>
                <span className="text-[10px] font-bold bg-emerald-100 text-emerald-700 px-2 py-0.5 rounded uppercase">PUBLIC</span>
              </div>
            </div>

            <div className="sm:col-span-2 space-y-2">
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1 flex items-center justify-between">
                <span>GitHub / Git Repository URL</span>
                <span className="text-slate-400 font-normal lowercase text-[11px]">(public or private — or attach .zip below)</span>
              </label>
              <input
                type="url"
                placeholder="https://github.com/projectvault/smart-irrigation-iot.git (optional if .zip is attached)"
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent text-sm text-slate-900"
                value={formData.repositoryUrl || ''}
                onChange={(e) => setFormData({ ...formData, repositoryUrl: e.target.value })}
              />

              {/* Private Repository Toggle */}
              <div className="flex items-center justify-between pt-1">
                <label className="flex items-center space-x-2 cursor-pointer text-xs font-semibold text-slate-700 select-none">
                  <input
                    type="checkbox"
                    checked={isPrivateRepo || Boolean(formData.githubToken)}
                    onChange={(e) => {
                      setIsPrivateRepo(e.target.checked);
                      if (!e.target.checked) setFormData({ ...formData, githubToken: '' });
                    }}
                    className="rounded border-slate-300 text-indigo-600 focus:ring-indigo-500 w-3.5 h-3.5"
                  />
                  <span className="flex items-center gap-1.5">
                    <Lock className="w-3.5 h-3.5 text-amber-600" />
                    <span>Private Repository (Provide Personal Access Token)</span>
                  </span>
                </label>
                <span className="text-[11px] text-slate-400">Fine-grained token / Read-only</span>
              </div>

              {/* Private Repository PAT Input Box */}
              {(isPrivateRepo || Boolean(formData.githubToken) || (formData.repositoryUrl && isPrivateRepo)) && (
                <div className="p-3.5 bg-amber-50/90 border border-amber-200 rounded-xl space-y-2">
                  <div className="flex items-center justify-between text-xs font-bold text-amber-900">
                    <div className="flex items-center gap-1.5">
                      <Lock className="w-4 h-4 text-amber-600" />
                      <span>Private Repository Security & Code AST Parsing</span>
                    </div>
                    <span className="text-[10px] bg-amber-100 text-amber-800 font-semibold px-2 py-0.5 rounded">PAT Authentication</span>
                  </div>
                  <p className="text-xs text-amber-900 leading-relaxed">
                    Provide a GitHub Personal Access Token (PAT) with read permission. ProjectVault securely downloads the repository zipball directly into memory, strips boilerplate, and computes AST structural code similarity against department records.
                  </p>
                  <div className="space-y-1">
                    <label className="text-[11px] font-bold text-amber-800 uppercase tracking-wide">
                      GitHub Personal Access Token (PAT)
                    </label>
                    <input
                      type="password"
                      placeholder="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
                      className="w-full px-3 py-2 rounded-lg border border-amber-300 bg-white focus:outline-none focus:ring-2 focus:ring-amber-500 text-xs font-mono text-slate-900 placeholder-slate-400"
                      value={formData.githubToken || ''}
                      onChange={(e) => setFormData({ ...formData, githubToken: e.target.value })}
                    />
                  </div>
                  <p className="text-[11px] text-amber-700 italic">
                    Tip: If you prefer not to supply a token, you can leave this blank and attach your source code directly as a <strong>.zip file</strong> under Attachments below.
                  </p>
                </div>
              )}

              <p className="text-xs text-slate-500 mt-1">
                Note: At least one document attachment (Synopsis/SRS/.zip) or repository link is required before submission.
              </p>
            </div>
          </div>

          {/* ============================================================ */}
          {/* Document Attachments Section (Synopsis, SRS, PDF, DOCX, ZIP) */}
          {/* ============================================================ */}
          <div className="pt-4 border-t border-slate-200 space-y-3">
            <div className="flex items-center justify-between">
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-800 flex items-center gap-1.5">
                  <Paperclip className="w-4 h-4 text-indigo-600" />
                  <span>Project Attachments & Source Code (.zip, Synopsis, SRS)</span>
                </label>
                <p className="text-xs text-slate-500">
                  Attach your project Synopsis, SRS, Reports (.pdf, .docx), or Source Code (.zip)
                </p>
              </div>
              <span className="text-xs font-semibold text-indigo-700 bg-indigo-50 px-2.5 py-1 rounded-full border border-indigo-200">
                {attachedFiles.length} file{attachedFiles.length === 1 ? '' : 's'} selected
              </span>
            </div>

            {/* Hidden File Input allowing ZIP */}
            <input
              type="file"
              ref={fileInputRef}
              multiple
              accept=".pdf,.doc,.docx,.txt,.zip"
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
                Click to attach Synopsis, SRS, Report, or Source Code .zip file
              </div>
              <div className="text-[11px] text-slate-500">
                Supports PDF, DOCX, DOC, TXT, and Source Code ZIP archives (.zip) (Up to 50MB)
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
