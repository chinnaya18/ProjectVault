import React, { useState, useEffect, useMemo } from 'react';
import { Navigate } from 'react-router-dom';
import * as XLSX from 'xlsx';
import { 
  User, 
  Role, 
  UserStatus, 
  ApiResponse, 
  PageResponse, 
  StudentRosterItem, 
  StudentRosterStats, 
  Department 
} from '../types';
import api, { getErrorMessage } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { RosterUploadModal } from '../components/RosterUploadModal';
import { 
  Users as UsersIcon, 
  Search, 
  X, 
  GraduationCap, 
  Briefcase, 
  ShieldCheck, 
  Filter,
  PlusCircle,
  FileSpreadsheet,
  Upload,
  Download,
  Trash2,
  CheckCircle,
  RefreshCw,
  Clock,
  Ban,
  ChevronLeft,
  ChevronRight
} from 'lucide-react';
import { formatUserNameByRole } from '../utils/userFormat';

export const UsersPage: React.FC = () => {
  const { user: currentUser, isLoading: isAuthLoading } = useAuth();

  // Primary Tab: 'USERS' (User Directory) vs 'ROSTER' (Nominal Roll Whitelist)
  const [mainTab, setMainTab] = useState<'USERS' | 'ROSTER'>('USERS');

  // --- TAB 1: USERS DIRECTORY STATE ---
  const [users, setUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Search and Segmentation Filters for Users
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [activeSegment, setActiveSegment] = useState<'ALL' | 'FACULTY' | 'STUDENT' | 'ADMIN'>('ALL');
  const [selectedStatus, setSelectedStatus] = useState<string>('');

  // Onboard Faculty Modal State
  const [isOnboardModalOpen, setIsOnboardModalOpen] = useState(false);
  const [facultyForm, setFacultyForm] = useState({
    name: '',
    email: '',
    designation: 'Assistant Professor (Sl. Gr.)',
    password: 'Password@123',
    departmentId: 1 // Default to MCA
  });
  const [isOnboarding, setIsOnboarding] = useState(false);
  const [onboardError, setOnboardError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  // --- TAB 2: STUDENT NOMINAL ROLL WHITELIST STATE ---
  const [rosterList, setRosterList] = useState<StudentRosterItem[]>([]);
  const [rosterStats, setRosterStats] = useState<StudentRosterStats | null>(null);
  const [isRosterLoading, setIsRosterLoading] = useState(false);
  const [rosterError, setRosterError] = useState<string | null>(null);
  const [rosterSuccess, setRosterSuccess] = useState<string | null>(null);

  const [rosterSearch, setRosterSearch] = useState<string>('');
  const [rosterBatch, setRosterBatch] = useState<string>('');
  const [rosterEligibilityFilter, setRosterEligibilityFilter] = useState<'ALL' | 'ELIGIBLE' | 'DISCONTINUED'>('ALL');
  const [rosterPage, setRosterPage] = useState<number>(0);
  const [rosterTotalPages, setRosterTotalPages] = useState<number>(1);
  const [rosterTotalElements, setRosterTotalElements] = useState<number>(0);

  const [departments, setDepartments] = useState<Department[]>([]);
  const [isUploadModalOpen, setIsUploadModalOpen] = useState(false);

  useEffect(() => {
    if (!isAuthLoading && currentUser && currentUser.role === 'ADMIN') {
      fetchUsers();
      fetchDepartments();
      fetchRosterStats();
      fetchRoster(0);
    }
  }, [isAuthLoading, currentUser]);

  const fetchDepartments = async () => {
    try {
      const res = await api.get<ApiResponse<PageResponse<Department>>>('/departments?size=100');
      if (res.data?.data?.content) {
        setDepartments(res.data.data.content);
      }
    } catch (err) {
      console.error('Failed to load departments:', err);
    }
  };

  // --- USER DIRECTORY FUNCTIONS ---
  const fetchUsers = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const res = await api.get<ApiResponse<PageResponse<User>>>('/users?size=150');
      if (res.data && res.data.data && res.data.data.content) {
        setUsers(res.data.data.content);
      }
    } catch (err: any) {
      setError(getErrorMessage(err, 'Failed to fetch user directory'));
    } finally {
      setIsLoading(false);
    }
  };

  const handleOnboardFaculty = async (e: React.FormEvent) => {
    e.preventDefault();
    setOnboardError(null);
    setIsOnboarding(true);

    if (!facultyForm.email.toLowerCase().endsWith('@psgtech.ac.in')) {
      setOnboardError('Faculty email must belong to the @psgtech.ac.in institutional domain.');
      setIsOnboarding(false);
      return;
    }

    try {
      await api.post('/users/faculty', facultyForm);
      setSuccessMsg(`Faculty member ${facultyForm.name} (${facultyForm.email}) onboarded successfully!`);
      setIsOnboardModalOpen(false);
      setFacultyForm({
        name: '',
        email: '',
        designation: 'Assistant Professor (Sl. Gr.)',
        password: 'Password@123',
        departmentId: 1
      });
      fetchUsers();
    } catch (err: any) {
      setOnboardError(getErrorMessage(err, 'Failed to onboard faculty member'));
    } finally {
      setIsOnboarding(false);
    }
  };

  const handleUpdateRole = async (userId: number, newRole: Role) => {
    if (currentUser && userId === currentUser.id) {
      alert("Security Protection: You cannot demote your own active Admin session role.");
      return;
    }
    setError(null);
    setSuccessMsg(null);
    try {
      await api.put(`/users/${userId}/role`, { role: newRole });
      setSuccessMsg(`Successfully updated user #${userId} role to ${newRole}`);
      fetchUsers();
    } catch (err: any) {
      setError(getErrorMessage(err, 'Failed to update user role'));
    }
  };

  const handleUpdateStatus = async (userId: number, newStatus: UserStatus) => {
    setError(null);
    setSuccessMsg(null);
    try {
      await api.put(`/users/${userId}/status`, { userStatus: newStatus });
      setSuccessMsg(`Successfully updated user #${userId} status to ${newStatus}`);
      fetchUsers();
    } catch (err: any) {
      setError(getErrorMessage(err, 'Failed to update user status'));
    }
  };

  // --- ROSTER MANAGEMENT FUNCTIONS ---
  const fetchRoster = async (page: number = 0) => {
    setIsRosterLoading(true);
    setRosterError(null);
    try {
      const params = new URLSearchParams();
      params.append('page', String(page));
      params.append('size', '25');
      if (rosterSearch.trim()) params.append('search', rosterSearch.trim());
      if (rosterBatch.trim()) params.append('batch', rosterBatch.trim());
      if (rosterEligibilityFilter === 'ELIGIBLE') params.append('isEligible', 'true');
      if (rosterEligibilityFilter === 'DISCONTINUED') params.append('isEligible', 'false');

      const res = await api.get<ApiResponse<PageResponse<StudentRosterItem>>>(`/roster?${params.toString()}`);
      if (res.data?.data) {
        setRosterList(res.data.data.content);
        setRosterTotalPages(res.data.data.totalPages || 1);
        setRosterTotalElements(res.data.data.totalElements || 0);
        setRosterPage(page);
      }
    } catch (err: any) {
      setRosterError(getErrorMessage(err, 'Failed to fetch student nominal roll'));
    } finally {
      setIsRosterLoading(false);
    }
  };

  const fetchRosterStats = async () => {
    try {
      const res = await api.get<ApiResponse<StudentRosterStats>>('/roster/stats');
      if (res.data?.data) {
        setRosterStats(res.data.data);
      }
    } catch (err) {
      console.error('Failed to load roster stats:', err);
    }
  };

  const handleToggleEligibility = async (id: number) => {
    setRosterError(null);
    setRosterSuccess(null);
    try {
      const res = await api.put<ApiResponse<StudentRosterItem>>(`/roster/${id}/toggle-eligibility`);
      const updated = res.data?.data;
      if (updated) {
        setRosterSuccess(`Updated eligibility for ${updated.rollNo}: ${updated.isEligible ? 'ACTIVE/ELIGIBLE' : 'DISCONTINUED (Blocked)'}`);
      }
      fetchRoster(rosterPage);
      fetchRosterStats();
    } catch (err: any) {
      setRosterError(getErrorMessage(err, 'Failed to toggle student eligibility'));
    }
  };

  const handleDeleteRosterItem = async (id: number, rollNo: string) => {
    if (!window.confirm(`Are you sure you want to remove roll number ${rollNo} from the nominal roll whitelist?`)) {
      return;
    }
    setRosterError(null);
    setRosterSuccess(null);
    try {
      await api.delete(`/roster/${id}`);
      setRosterSuccess(`Removed ${rollNo} from nominal roll whitelist.`);
      fetchRoster(rosterPage);
      fetchRosterStats();
    } catch (err: any) {
      setRosterError(getErrorMessage(err, 'Failed to remove student from roster'));
    }
  };

  const handleDownloadSampleTemplate = () => {
    const templateData = [
      ['S.No', 'Roll Number', 'Name', 'Email'],
      [1, '25MX101', 'BALAJI K', '25mx101@psgtech.ac.in'],
      [2, '25MX102', 'BALASUBRAMANIAM S', '25mx102@psgtech.ac.in'],
      [3, '25MX103', 'BARATHVIKRAMAN S K', '25mx103@psgtech.ac.in']
    ];

    const ws = XLSX.utils.aoa_to_sheet(templateData);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Roster_Template');
    XLSX.writeFile(wb, 'psgtech_student_roster_template.xlsx');
  };

  // Filtered users for User Directory tab
  const filteredUsers = useMemo(() => {
    return users.filter((u) => {
      const matchesSearch =
        u.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        u.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (u.rollNo && u.rollNo.toLowerCase().includes(searchQuery.toLowerCase()));

      const matchesSegment = activeSegment === 'ALL' || u.role === activeSegment;
      const matchesStatus = !selectedStatus || u.userStatus === selectedStatus;

      return matchesSearch && matchesSegment && matchesStatus;
    });
  }, [users, searchQuery, activeSegment, selectedStatus]);

  // Counts for metric cards
  const totalCount = users.length;
  const facultyCount = users.filter((u) => u.role === 'FACULTY').length;
  const studentCount = users.filter((u) => u.role === 'STUDENT').length;
  const adminCount = users.filter((u) => u.role === 'ADMIN').length;

  if (isAuthLoading) {
    return (
      <div className="min-h-[70vh] flex items-center justify-center">
        <div className="w-8 h-8 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (!currentUser || currentUser.role !== 'ADMIN') {
    return <Navigate to="/" replace />;
  }

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-6">
      {/* Top Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 pb-2">
        <div>
          <h1 className="text-3xl font-extrabold text-slate-900 tracking-tight flex items-center space-x-3">
            <span>Identity Governance & Nominal Roll</span>
          </h1>
          <p className="text-sm text-slate-500 mt-1">
            Department nominal roll ingestion, whitelist enforcement, dynamic institutional email management & role security
          </p>
        </div>

        {/* Primary Action Buttons */}
        <div className="flex items-center space-x-3">
          {mainTab === 'ROSTER' ? (
            <>
              <button
                onClick={handleDownloadSampleTemplate}
                className="px-3.5 py-2.5 bg-white hover:bg-slate-50 text-slate-700 text-sm font-semibold rounded-xl border border-slate-300 shadow-sm flex items-center space-x-2 transition-all"
              >
                <Download className="w-4 h-4 text-slate-500" />
                <span>Template</span>
              </button>
              <button
                onClick={() => setIsUploadModalOpen(true)}
                className="px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold rounded-xl shadow-sm hover:shadow flex items-center space-x-2 transition-all"
              >
                <Upload className="w-4 h-4" />
                <span>Ingest Excel Roster</span>
              </button>
            </>
          ) : (
            <button
              onClick={() => setIsOnboardModalOpen(true)}
              className="px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold rounded-xl shadow-sm hover:shadow flex items-center space-x-2 transition-all"
            >
              <PlusCircle className="w-4 h-4" />
              <span>Onboard Faculty Staff</span>
            </button>
          )}
        </div>
      </div>

      {/* Main Navigation Tabs */}
      <div className="flex border-b border-slate-200 space-x-8">
        <button
          onClick={() => setMainTab('USERS')}
          className={`pb-3 text-sm font-bold flex items-center space-x-2 border-b-2 transition-colors ${
            mainTab === 'USERS'
              ? 'border-indigo-600 text-indigo-600'
              : 'border-transparent text-slate-500 hover:text-slate-800'
          }`}
        >
          <UsersIcon className="w-4 h-4" />
          <span>Active User Accounts ({totalCount})</span>
        </button>

        <button
          onClick={() => {
            setMainTab('ROSTER');
            fetchRoster(rosterPage);
            fetchRosterStats();
          }}
          className={`pb-3 text-sm font-bold flex items-center space-x-2 border-b-2 transition-colors ${
            mainTab === 'ROSTER'
              ? 'border-indigo-600 text-indigo-600'
              : 'border-transparent text-slate-500 hover:text-slate-800'
          }`}
        >
          <FileSpreadsheet className="w-4 h-4" />
          <span>Student Nominal Roll Whitelist</span>
          {rosterStats && (
            <span className="px-2 py-0.5 rounded-full text-xs bg-indigo-100 text-indigo-700 font-extrabold">
              {rosterStats.totalStudents}
            </span>
          )}
        </button>
      </div>

      {/* ========================================================================= */}
      {/* TAB 1: USERS DIRECTORY VIEW */}
      {/* ========================================================================= */}
      {mainTab === 'USERS' && (
        <div className="space-y-6">
          {/* Metric Stat Cards */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <button
              onClick={() => setActiveSegment('ALL')}
              className={`p-5 rounded-2xl border text-left transition-all ${
                activeSegment === 'ALL'
                  ? 'bg-slate-900 text-white border-slate-900 shadow-md ring-2 ring-indigo-500/30'
                  : 'bg-white text-slate-800 border-slate-200 hover:border-slate-300 hover:bg-slate-50/50'
              }`}
            >
              <div className="flex items-center justify-between">
                <span className={`text-xs font-bold uppercase tracking-wider ${activeSegment === 'ALL' ? 'text-slate-400' : 'text-slate-500'}`}>
                  Total Users
                </span>
                <UsersIcon className={`w-5 h-5 ${activeSegment === 'ALL' ? 'text-indigo-400' : 'text-slate-400'}`} />
              </div>
              <div className="mt-2 text-3xl font-extrabold">{totalCount}</div>
              <p className={`text-xs mt-1 ${activeSegment === 'ALL' ? 'text-slate-400' : 'text-slate-500'}`}>
                All registered accounts
              </p>
            </button>

            <button
              onClick={() => setActiveSegment('FACULTY')}
              className={`p-5 rounded-2xl border text-left transition-all ${
                activeSegment === 'FACULTY'
                  ? 'bg-indigo-600 text-white border-indigo-600 shadow-md ring-2 ring-indigo-500/30'
                  : 'bg-white text-slate-800 border-slate-200 hover:border-indigo-200 hover:bg-indigo-50/20'
              }`}
            >
              <div className="flex items-center justify-between">
                <span className={`text-xs font-bold uppercase tracking-wider ${activeSegment === 'FACULTY' ? 'text-indigo-200' : 'text-indigo-600'}`}>
                  Faculty Members
                </span>
                <Briefcase className={`w-5 h-5 ${activeSegment === 'FACULTY' ? 'text-indigo-200' : 'text-indigo-500'}`} />
              </div>
              <div className="mt-2 text-3xl font-extrabold">{facultyCount}</div>
              <p className={`text-xs mt-1 ${activeSegment === 'FACULTY' ? 'text-indigo-100' : 'text-slate-500'}`}>
                Designated project guides
              </p>
            </button>

            <button
              onClick={() => setActiveSegment('STUDENT')}
              className={`p-5 rounded-2xl border text-left transition-all ${
                activeSegment === 'STUDENT'
                  ? 'bg-emerald-600 text-white border-emerald-600 shadow-md ring-2 ring-emerald-500/30'
                  : 'bg-white text-slate-800 border-slate-200 hover:border-emerald-200 hover:bg-emerald-50/20'
              }`}
            >
              <div className="flex items-center justify-between">
                <span className={`text-xs font-bold uppercase tracking-wider ${activeSegment === 'STUDENT' ? 'text-emerald-200' : 'text-emerald-600'}`}>
                  Students
                </span>
                <GraduationCap className={`w-5 h-5 ${activeSegment === 'STUDENT' ? 'text-emerald-200' : 'text-emerald-500'}`} />
              </div>
              <div className="mt-2 text-3xl font-extrabold">{studentCount}</div>
              <p className={`text-xs mt-1 ${activeSegment === 'STUDENT' ? 'text-emerald-100' : 'text-slate-500'}`}>
                Enrolled MCA scholars
              </p>
            </button>

            <button
              onClick={() => setActiveSegment('ADMIN')}
              className={`p-5 rounded-2xl border text-left transition-all ${
                activeSegment === 'ADMIN'
                  ? 'bg-purple-600 text-white border-purple-600 shadow-md ring-2 ring-purple-500/30'
                  : 'bg-white text-slate-800 border-slate-200 hover:border-purple-200 hover:bg-purple-50/20'
              }`}
            >
              <div className="flex items-center justify-between">
                <span className={`text-xs font-bold uppercase tracking-wider ${activeSegment === 'ADMIN' ? 'text-purple-200' : 'text-purple-600'}`}>
                  Administrators
                </span>
                <ShieldCheck className={`w-5 h-5 ${activeSegment === 'ADMIN' ? 'text-purple-200' : 'text-purple-500'}`} />
              </div>
              <div className="mt-2 text-3xl font-extrabold">{adminCount}</div>
              <p className={`text-xs mt-1 ${activeSegment === 'ADMIN' ? 'text-purple-100' : 'text-slate-500'}`}>
                HOD & System Governance
              </p>
            </button>
          </div>

          {/* Notifications */}
          {successMsg && (
            <div className="p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-sm font-semibold flex items-center justify-between animate-fadeIn">
              <span>{successMsg}</span>
              <button onClick={() => setSuccessMsg(null)} className="text-emerald-600 hover:text-emerald-900">
                <X className="w-4 h-4" />
              </button>
            </div>
          )}

          {error && (
            <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-sm font-semibold flex items-center justify-between">
              <span>{error}</span>
              <button onClick={() => setError(null)} className="text-rose-600 hover:text-rose-900">
                <X className="w-4 h-4" />
              </button>
            </div>
          )}

          {/* Filter Bar */}
          <div className="bg-white p-4 rounded-2xl shadow-sm border border-slate-200 flex flex-col md:flex-row gap-4 items-center justify-between">
            <div className="relative w-full md:w-96">
              <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                <Search className="w-4 h-4" />
              </div>
              <input
                type="text"
                placeholder="Search by name, roll no, or email..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:bg-white"
              />
            </div>

            <div className="flex items-center space-x-3 w-full md:w-auto">
              <select
                value={selectedStatus}
                onChange={(e) => setSelectedStatus(e.target.value)}
                className="px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm font-medium text-slate-700 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
                <option value="">All Account Statuses</option>
                <option value="ACTIVE">ACTIVE</option>
                <option value="INACTIVE">INACTIVE</option>
                <option value="ALUMNI">ALUMNI</option>
              </select>
            </div>
          </div>

          {/* Users Table */}
          <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
            {isLoading ? (
              <div className="py-16 flex flex-col items-center justify-center space-y-2">
                <div className="w-8 h-8 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin" />
                <span className="text-xs font-semibold text-slate-500">Loading user directory...</span>
              </div>
            ) : (
              <div className="overflow-x-auto">
              <table className="w-full text-left text-sm text-slate-700">
                <thead className="bg-slate-50 border-b border-slate-200 text-xs uppercase font-bold text-slate-500 tracking-wider">
                  <tr>
                    <th className="px-6 py-4">User</th>
                    <th className="px-6 py-4">Department</th>
                    <th className="px-6 py-4">Role</th>
                    <th className="px-6 py-4">Account Status</th>
                    <th className="px-6 py-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {filteredUsers.length === 0 ? (
                    <tr>
                      <td colSpan={5} className="px-6 py-12 text-center text-slate-400">
                        No users match the selected search or criteria.
                      </td>
                    </tr>
                  ) : (
                    filteredUsers.map((u) => (
                      <tr key={u.id} className="hover:bg-slate-50/80 transition-colors">
                        <td className="px-6 py-4">
                          <div className="font-semibold text-slate-900">
                            {formatUserNameByRole(u.name, u.role)}
                          </div>
                          <div className="text-xs text-slate-500 font-mono mt-0.5">{u.email}</div>
                          {u.rollNo && (
                            <span className="inline-block mt-1 px-2 py-0.5 text-[10px] font-mono font-bold bg-indigo-50 text-indigo-700 rounded border border-indigo-100">
                              {u.rollNo}
                            </span>
                          )}
                        </td>
                        <td className="px-6 py-4 text-xs font-medium text-slate-600">
                          {u.departmentName || 'Master of Computer Applications'}
                        </td>
                        <td className="px-6 py-4">
                          <span
                            className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold ${
                              u.role === 'ADMIN'
                                ? 'bg-purple-100 text-purple-700'
                                : u.role === 'FACULTY'
                                ? 'bg-indigo-100 text-indigo-700'
                                : 'bg-emerald-100 text-emerald-700'
                            }`}
                          >
                            {u.role}
                          </span>
                        </td>
                        <td className="px-6 py-4">
                          <span
                            className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold ${
                              u.userStatus === 'ACTIVE'
                                ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                                : u.userStatus === 'ALUMNI'
                                ? 'bg-blue-50 text-blue-700 border border-blue-200'
                                : 'bg-slate-100 text-slate-700 border border-slate-200'
                            }`}
                          >
                            {u.userStatus}
                          </span>
                        </td>
                        <td className="px-6 py-4 text-right space-x-2">
                          {/* Role Transition Button */}
                          {u.role === 'STUDENT' && (
                            <button
                              onClick={() => handleUpdateRole(u.id, 'FACULTY')}
                              className="px-2.5 py-1 text-xs font-semibold rounded-lg bg-indigo-50 hover:bg-indigo-100 text-indigo-700 border border-indigo-200 transition-colors"
                            >
                              Promote to Faculty
                            </button>
                          )}
                          {u.role === 'FACULTY' && (
                            <button
                              onClick={() => handleUpdateRole(u.id, 'STUDENT')}
                              className="px-2.5 py-1 text-xs font-semibold rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-700 transition-colors"
                            >
                              Revert to Student
                            </button>
                          )}

                          {/* Status Toggle Button */}
                          {u.userStatus === 'ACTIVE' ? (
                            <button
                              onClick={() => handleUpdateStatus(u.id, 'INACTIVE')}
                              className="px-2.5 py-1 text-xs font-semibold rounded-lg bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 transition-colors"
                            >
                              Deactivate
                            </button>
                          ) : (
                            <button
                              onClick={() => handleUpdateStatus(u.id, 'ACTIVE')}
                              className="px-2.5 py-1 text-xs font-semibold rounded-lg bg-emerald-50 hover:bg-emerald-100 text-emerald-700 border border-emerald-200 transition-colors"
                            >
                              Activate
                            </button>
                          )}
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          )}
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* TAB 2: STUDENT NOMINAL ROLL WHITELIST VIEW */}
      {/* ========================================================================= */}
      {mainTab === 'ROSTER' && (
        <div className="space-y-6">
          {/* Stat Cards for Roster Whitelist */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="p-5 rounded-2xl border bg-slate-900 text-white border-slate-900 shadow-md">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold uppercase tracking-wider text-slate-400">
                  Total Nominal Roll
                </span>
                <UsersIcon className="w-5 h-5 text-indigo-400" />
              </div>
              <div className="mt-2 text-3xl font-extrabold">{rosterStats?.totalStudents ?? rosterTotalElements}</div>
              <p className="text-xs mt-1 text-slate-400">Official department whitelist</p>
            </div>

            <div className="p-5 rounded-2xl border bg-emerald-600 text-white border-emerald-600 shadow-md">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold uppercase tracking-wider text-emerald-200">
                  Registered Accounts
                </span>
                <CheckCircle className="w-5 h-5 text-emerald-200" />
              </div>
              <div className="mt-2 text-3xl font-extrabold">{rosterStats?.registeredStudents ?? 0}</div>
              <p className="text-xs mt-1 text-emerald-100">Activated login profiles</p>
            </div>

            <div className="p-5 rounded-2xl border bg-amber-500 text-white border-amber-500 shadow-md">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold uppercase tracking-wider text-amber-100">
                  Pending Registration
                </span>
                <Clock className="w-5 h-5 text-amber-100" />
              </div>
              <div className="mt-2 text-3xl font-extrabold">
                {(rosterStats?.totalStudents ?? rosterTotalElements) - (rosterStats?.registeredStudents ?? 0)}
              </div>
              <p className="text-xs mt-1 text-amber-100">Eligible but not yet signed up</p>
            </div>

            <div className="p-5 rounded-2xl border bg-rose-600 text-white border-rose-600 shadow-md">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold uppercase tracking-wider text-rose-200">
                  Discontinued / Blocked
                </span>
                <Ban className="w-5 h-5 text-rose-200" />
              </div>
              <div className="mt-2 text-3xl font-extrabold">{rosterStats?.discontinuedStudents ?? 0}</div>
              <p className="text-xs mt-1 text-rose-100">Access barred from registering</p>
            </div>
          </div>

          {/* Feedback Alerts */}
          {rosterSuccess && (
            <div className="p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-sm font-semibold flex items-center justify-between animate-fadeIn">
              <span>{rosterSuccess}</span>
              <button onClick={() => setRosterSuccess(null)} className="text-emerald-600 hover:text-emerald-900">
                <X className="w-4 h-4" />
              </button>
            </div>
          )}

          {rosterError && (
            <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-sm font-semibold flex items-center justify-between">
              <span>{rosterError}</span>
              <button onClick={() => setRosterError(null)} className="text-rose-600 hover:text-rose-900">
                <X className="w-4 h-4" />
              </button>
            </div>
          )}

          {/* Roster Search and Filter Controls */}
          <div className="bg-white p-4 rounded-2xl shadow-sm border border-slate-200 flex flex-col md:flex-row gap-4 items-center justify-between">
            <div className="relative w-full md:w-96">
              <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                <Search className="w-4 h-4" />
              </div>
              <input
                type="text"
                placeholder="Search roster by roll no, name, or email..."
                value={rosterSearch}
                onChange={(e) => setRosterSearch(e.target.value)}
                onKeyDown={(e) => { if (e.key === 'Enter') fetchRoster(0); }}
                className="w-full pl-10 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:bg-white"
              />
            </div>

            <div className="flex flex-wrap items-center gap-3 w-full md:w-auto">
              {/* Batch Filter */}
              <input
                type="text"
                placeholder="Batch (e.g. 2025-2027)"
                value={rosterBatch}
                onChange={(e) => setRosterBatch(e.target.value)}
                className="w-36 px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />

              {/* Eligibility Filter */}
              <select
                value={rosterEligibilityFilter}
                onChange={(e) => setRosterEligibilityFilter(e.target.value as any)}
                className="px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm font-medium text-slate-700 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
                <option value="ALL">All Statuses</option>
                <option value="ELIGIBLE">Active / Eligible Only</option>
                <option value="DISCONTINUED">Discontinued Only</option>
              </select>

              <button
                onClick={() => fetchRoster(0)}
                className="px-4 py-2 bg-slate-800 hover:bg-slate-900 text-white text-sm font-semibold rounded-xl flex items-center space-x-1.5 transition-colors"
              >
                <Filter className="w-4 h-4" />
                <span>Apply</span>
              </button>

              <button
                onClick={() => {
                  setRosterSearch('');
                  setRosterBatch('');
                  setRosterEligibilityFilter('ALL');
                  setTimeout(() => fetchRoster(0), 10);
                }}
                className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-xl transition-colors"
                title="Reset Filters"
              >
                <RefreshCw className="w-4 h-4" />
              </button>
            </div>
          </div>

          {/* Roster Data Table */}
          <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
            {isRosterLoading ? (
              <div className="py-16 flex flex-col items-center justify-center space-y-2">
                <div className="w-8 h-8 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin" />
                <span className="text-xs font-semibold text-slate-500">Loading student nominal roll...</span>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm text-slate-700">
                  <thead className="bg-slate-50 border-b border-slate-200 text-xs uppercase font-bold text-slate-500 tracking-wider">
                    <tr>
                      <th className="px-6 py-4">#</th>
                      <th className="px-6 py-4">Roll Number</th>
                      <th className="px-6 py-4">Student Name</th>
                      <th className="px-6 py-4">Official Institutional Email</th>
                      <th className="px-6 py-4">Batch</th>
                      <th className="px-6 py-4">Department</th>
                      <th className="px-6 py-4">Eligibility</th>
                      <th className="px-6 py-4">Registration</th>
                      <th className="px-6 py-4 text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {rosterList.length === 0 ? (
                      <tr>
                        <td colSpan={9} className="px-6 py-12 text-center text-slate-400">
                          No student nominal roll records found. Click &quot;Ingest Excel Roster&quot; to upload student records.
                        </td>
                      </tr>
                    ) : (
                      rosterList.map((item, index) => {
                        const isEligible = item.isEligible ?? item.eligible ?? true;
                        const isRegistered = item.isRegistered ?? item.registered ?? false;

                        return (
                          <tr key={item.id} className="hover:bg-slate-50/80 transition-colors">
                            <td className="px-6 py-4 text-xs font-mono text-slate-400">
                              {rosterPage * 25 + index + 1}
                            </td>
                            <td className="px-6 py-4">
                              <span className="inline-block px-2.5 py-1 text-xs font-mono font-extrabold bg-indigo-50 text-indigo-700 rounded-lg border border-indigo-200">
                                {item.rollNo}
                              </span>
                            </td>
                            <td className="px-6 py-4 font-semibold text-slate-900">
                              {item.name}
                            </td>
                            <td className="px-6 py-4 text-xs font-mono text-indigo-600">
                              {item.email}
                            </td>
                            <td className="px-6 py-4 text-xs font-medium text-slate-600">
                              {item.batch}
                            </td>
                            <td className="px-6 py-4 text-xs text-slate-500">
                              {item.departmentName || 'MCA'}
                            </td>
                            <td className="px-6 py-4">
                              <span
                                className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold ${
                                  isEligible
                                    ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                                    : 'bg-rose-50 text-rose-700 border border-rose-200'
                                }`}
                              >
                                {isEligible ? 'Active / Eligible' : 'Discontinued'}
                              </span>
                            </td>
                            <td className="px-6 py-4">
                              <span
                                className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold ${
                                  isRegistered
                                    ? 'bg-emerald-100 text-emerald-800'
                                    : 'bg-amber-100 text-amber-800'
                                }`}
                              >
                                {isRegistered ? 'Registered' : 'Pending Account'}
                              </span>
                            </td>
                            <td className="px-6 py-4 text-right space-x-2">
                              {/* Toggle Discontinuation */}
                              <button
                                onClick={() => handleToggleEligibility(item.id)}
                                className={`px-2.5 py-1 text-xs font-semibold rounded-lg border transition-colors ${
                                  isEligible
                                    ? 'bg-rose-50 hover:bg-rose-100 text-rose-700 border-rose-200'
                                    : 'bg-emerald-50 hover:bg-emerald-100 text-emerald-700 border-emerald-200'
                                }`}
                                title={isEligible ? 'Mark as Discontinued' : 'Reinstate Eligibility'}
                              >
                                {isEligible ? 'Discontinue' : 'Reinstate'}
                              </button>

                              {/* Delete Unregistered */}
                              {!isRegistered && (
                                <button
                                  onClick={() => handleDeleteRosterItem(item.id, item.rollNo)}
                                  className="p-1 text-slate-400 hover:text-rose-600 rounded-lg hover:bg-rose-50 transition-colors"
                                  title="Remove from Roster"
                                >
                                  <Trash2 className="w-4 h-4" />
                                </button>
                              )}
                            </td>
                          </tr>
                        );
                      })
                    )}
                  </tbody>
                </table>
              </div>
            )}

            {/* Pagination Controls */}
            {rosterTotalPages > 1 && (
              <div className="px-6 py-4 border-t border-slate-200 bg-slate-50 flex items-center justify-between">
                <span className="text-xs text-slate-500">
                  Showing page {rosterPage + 1} of {rosterTotalPages} ({rosterTotalElements} total students)
                </span>
                <div className="flex items-center space-x-2">
                  <button
                    disabled={rosterPage === 0}
                    onClick={() => fetchRoster(rosterPage - 1)}
                    className="p-1.5 rounded-lg border border-slate-300 bg-white text-slate-600 hover:bg-slate-50 disabled:opacity-40 disabled:pointer-events-none"
                  >
                    <ChevronLeft className="w-4 h-4" />
                  </button>
                  <button
                    disabled={rosterPage + 1 >= rosterTotalPages}
                    onClick={() => fetchRoster(rosterPage + 1)}
                    className="p-1.5 rounded-lg border border-slate-300 bg-white text-slate-600 hover:bg-slate-50 disabled:opacity-40 disabled:pointer-events-none"
                  >
                    <ChevronRight className="w-4 h-4" />
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* MODAL: ONBOARD FACULTY STAFF */}
      {/* ========================================================================= */}
      {isOnboardModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white rounded-2xl shadow-2xl max-w-lg w-full overflow-hidden border border-slate-200">
            <div className="bg-indigo-600 px-6 py-4 flex items-center justify-between text-white">
              <div>
                <h3 className="text-lg font-bold">Onboard Faculty Member</h3>
                <p className="text-xs text-indigo-100">Add authentic PSG Tech MCA department faculty</p>
              </div>
              <button
                onClick={() => setIsOnboardModalOpen(false)}
                className="text-white/80 hover:text-white p-1 rounded-lg hover:bg-indigo-700/50"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleOnboardFaculty} className="p-6 space-y-4">
              {onboardError && (
                <div className="p-3 bg-rose-50 border border-rose-200 text-rose-700 rounded-xl text-xs">
                  {onboardError}
                </div>
              )}

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Full Name with Title / Salutation
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Dr. Ilayaraja N or Mrs. Gayathri K"
                  className="w-full px-3 py-2 border border-slate-300 rounded-xl text-sm focus:ring-2 focus:ring-indigo-500 focus:outline-none"
                  value={facultyForm.name}
                  onChange={(e) => setFacultyForm({ ...facultyForm, name: e.target.value })}
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Institutional Email (@psgtech.ac.in)
                </label>
                <input
                  type="email"
                  required
                  placeholder="e.g. nir.mca@psgtech.ac.in"
                  className="w-full px-3 py-2 border border-slate-300 rounded-xl text-sm focus:ring-2 focus:ring-indigo-500 focus:outline-none"
                  value={facultyForm.email}
                  onChange={(e) => setFacultyForm({ ...facultyForm, email: e.target.value })}
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Academic Designation
                </label>
                <select
                  className="w-full px-3 py-2 border border-slate-300 rounded-xl text-sm bg-white focus:ring-2 focus:ring-indigo-500 focus:outline-none"
                  value={facultyForm.designation}
                  onChange={(e) => setFacultyForm({ ...facultyForm, designation: e.target.value })}
                >
                  <option value="Assistant Professor & Head (i/c)">Assistant Professor & Head (i/c)</option>
                  <option value="Professor">Professor</option>
                  <option value="Associate Professor">Associate Professor</option>
                  <option value="Assistant Professor (Sl. Gr.)">Assistant Professor (Sl. Gr.)</option>
                  <option value="Assistant Professor (Sr. Gr.)">Assistant Professor (Sr. Gr.)</option>
                  <option value="Assistant Professor">Assistant Professor</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Initial Login Password
                </label>
                <input
                  type="text"
                  required
                  className="w-full px-3 py-2 border border-slate-300 rounded-xl text-sm font-mono focus:ring-2 focus:ring-indigo-500 focus:outline-none"
                  value={facultyForm.password}
                  onChange={(e) => setFacultyForm({ ...facultyForm, password: e.target.value })}
                />
              </div>

              <div className="pt-4 flex justify-end space-x-3 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setIsOnboardModalOpen(false)}
                  className="px-4 py-2 text-sm font-semibold text-slate-600 hover:text-slate-800"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isOnboarding}
                  className="px-5 py-2 text-sm font-semibold bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl shadow disabled:opacity-50"
                >
                  {isOnboarding ? 'Onboarding...' : 'Onboard Faculty'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* MODAL: INGEST EXCEL ROSTER */}
      {/* ========================================================================= */}
      <RosterUploadModal
        isOpen={isUploadModalOpen}
        onClose={() => setIsUploadModalOpen(false)}
        departments={departments}
        onSuccess={(count) => {
          setRosterSuccess(`Successfully ingested ${count} students into nominal roll whitelist!`);
          fetchRoster(0);
          fetchRosterStats();
        }}
      />
    </div>
  );
};
