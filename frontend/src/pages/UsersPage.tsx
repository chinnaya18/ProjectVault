import React, { useState, useEffect, useMemo } from 'react';
import { Navigate } from 'react-router-dom';
import { User, Role, UserStatus, ApiResponse, PageResponse } from '../types';
import api, { getErrorMessage } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { 
  Users as UsersIcon, 
  AlertCircle, 
  Search, 
  X, 
  GraduationCap, 
  Briefcase, 
  ShieldCheck, 
  Filter,
  PlusCircle,
  Building2,
  Mail
} from 'lucide-react';
import { formatUserNameByRole } from '../utils/userFormat';

export const UsersPage: React.FC = () => {
  const { user: currentUser, isLoading: isAuthLoading } = useAuth();
  const [users, setUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Search and Segmentation Filters
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

  useEffect(() => {
    if (!isAuthLoading && currentUser && currentUser.role === 'ADMIN') {
      fetchUsers();
    }
  }, [isAuthLoading, currentUser]);

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

  // User Counts calculation
  const totalCount = users.length;
  const facultyCount = useMemo(() => users.filter(u => u.role === 'FACULTY').length, [users]);
  const studentCount = useMemo(() => users.filter(u => u.role === 'STUDENT').length, [users]);
  const adminCount = useMemo(() => users.filter(u => u.role === 'ADMIN').length, [users]);

  // Filtered Users computation based on Segment, Search Query, and Status
  const filteredUsers = useMemo(() => {
    return users.filter(u => {
      // 1. Role Segment Filter
      if (activeSegment !== 'ALL' && u.role !== activeSegment) {
        return false;
      }

      // 2. Lifecycle Status Filter
      if (selectedStatus && u.userStatus !== selectedStatus) {
        return false;
      }

      // 3. Universal Search Query Filter (Name, Email, Roll No / Designation, Department)
      if (searchQuery.trim()) {
        const query = searchQuery.toLowerCase().trim();
        const nameMatch = (u.name || '').toLowerCase().includes(query);
        const emailMatch = (u.email || '').toLowerCase().includes(query);
        const rollMatch = (u.rollNo || '').toLowerCase().includes(query);
        const deptMatch = (u.departmentName || '').toLowerCase().includes(query) || (u.departmentCode || '').toLowerCase().includes(query);

        if (!nameMatch && !emailMatch && !rollMatch && !deptMatch) {
          return false;
        }
      }

      return true;
    });
  }, [users, activeSegment, selectedStatus, searchQuery]);

  if (isAuthLoading) {
    return (
      <div className="min-h-[70vh] flex items-center justify-center">
        <div className="text-slate-400 font-semibold animate-pulse text-sm">
          Loading PSG Tech User Directory...
        </div>
      </div>
    );
  }

  if (!currentUser || currentUser.role !== 'ADMIN') {
    return <Navigate to="/" replace />;
  }

  const isAdmin = currentUser?.role === 'ADMIN';

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-6">
      {/* Top Header Card */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-6 rounded-2xl shadow-sm border border-slate-200">
        <div>
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-xl bg-indigo-600 text-white flex items-center justify-center shadow-md shadow-indigo-100">
              <UsersIcon className="w-5 h-5" />
            </div>
            <div>
              <h1 className="text-2xl font-extrabold text-slate-900 tracking-tight">
                User Management Directory
              </h1>
              <p className="text-xs text-slate-500 font-medium">
                PSG College of Technology &bull; MCA Department Directory & Role Governance
              </p>
            </div>
          </div>
        </div>

        {/* Action Controls */}
        <div className="flex items-center space-x-3">
          {isAdmin && (
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

      {/* Metric Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Total Users */}
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

        {/* Faculty Staff */}
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

        {/* Students */}
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

        {/* Administrators */}
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
          <button onClick={() => setSuccessMsg(null)} className="text-emerald-600 hover:text-emerald-900 text-xs font-bold uppercase">Dismiss</button>
        </div>
      )}

      {error && (
        <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-sm flex items-start space-x-2 animate-fadeIn">
          <AlertCircle className="w-5 h-5 mt-0.5 shrink-0" />
          <span>{error}</span>
        </div>
      )}

      {/* Search & Filter Bar */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm space-y-4">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-3">
          
          {/* Universal Search Bar */}
          <div className="relative flex-1">
            <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              placeholder="Search by name, roll number (e.g. 25MX101), email, or faculty designation..."
              className="w-full pl-10 pr-10 py-2.5 rounded-xl border border-slate-300 text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-slate-900 placeholder:text-slate-400 bg-slate-50/50 focus:bg-white transition-all"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
            {searchQuery && (
              <button
                onClick={() => setSearchQuery('')}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
              >
                <X className="w-4 h-4" />
              </button>
            )}
          </div>

          {/* Filters & Status */}
          <div className="flex items-center space-x-3">
            <div className="flex items-center space-x-1.5 text-xs font-semibold text-slate-500">
              <Filter className="w-3.5 h-3.5" />
              <span>Status:</span>
            </div>
            <select
              className="px-3 py-2 rounded-xl border border-slate-300 text-xs font-semibold text-slate-800 bg-white focus:ring-2 focus:ring-indigo-500"
              value={selectedStatus}
              onChange={(e) => setSelectedStatus(e.target.value)}
            >
              <option value="">All Statuses</option>
              <option value="ACTIVE">Active</option>
              <option value="ALUMNI">Alumni</option>
              <option value="INACTIVE">Inactive</option>
            </select>
          </div>
        </div>

        {/* Role Segment Tab Chips */}
        <div className="flex items-center space-x-2 pt-2 border-t border-slate-100 overflow-x-auto pb-1 text-xs">
          <button
            onClick={() => setActiveSegment('ALL')}
            className={`px-3 py-1.5 rounded-lg font-bold transition-all flex items-center space-x-1.5 ${
              activeSegment === 'ALL'
                ? 'bg-slate-900 text-white shadow-sm'
                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
            }`}
          >
            <span>All Users</span>
            <span className={`px-1.5 py-0.2 rounded-full text-[10px] ${activeSegment === 'ALL' ? 'bg-slate-700 text-white' : 'bg-slate-200 text-slate-700'}`}>
              {totalCount}
            </span>
          </button>

          <button
            onClick={() => setActiveSegment('FACULTY')}
            className={`px-3 py-1.5 rounded-lg font-bold transition-all flex items-center space-x-1.5 ${
              activeSegment === 'FACULTY'
                ? 'bg-indigo-600 text-white shadow-sm'
                : 'bg-indigo-50 text-indigo-700 hover:bg-indigo-100'
            }`}
          >
            <Briefcase className="w-3.5 h-3.5" />
            <span>Faculty Staff</span>
            <span className={`px-1.5 py-0.2 rounded-full text-[10px] ${activeSegment === 'FACULTY' ? 'bg-indigo-700 text-white' : 'bg-indigo-100 text-indigo-800'}`}>
              {facultyCount}
            </span>
          </button>

          <button
            onClick={() => setActiveSegment('STUDENT')}
            className={`px-3 py-1.5 rounded-lg font-bold transition-all flex items-center space-x-1.5 ${
              activeSegment === 'STUDENT'
                ? 'bg-emerald-600 text-white shadow-sm'
                : 'bg-emerald-50 text-emerald-700 hover:bg-emerald-100'
            }`}
          >
            <GraduationCap className="w-3.5 h-3.5" />
            <span>Students</span>
            <span className={`px-1.5 py-0.2 rounded-full text-[10px] ${activeSegment === 'STUDENT' ? 'bg-emerald-700 text-white' : 'bg-emerald-100 text-emerald-800'}`}>
              {studentCount}
            </span>
          </button>

          <button
            onClick={() => setActiveSegment('ADMIN')}
            className={`px-3 py-1.5 rounded-lg font-bold transition-all flex items-center space-x-1.5 ${
              activeSegment === 'ADMIN'
                ? 'bg-purple-600 text-white shadow-sm'
                : 'bg-purple-50 text-purple-700 hover:bg-purple-100'
            }`}
          >
            <ShieldCheck className="w-3.5 h-3.5" />
            <span>Admins</span>
            <span className={`px-1.5 py-0.2 rounded-full text-[10px] ${activeSegment === 'ADMIN' ? 'bg-purple-700 text-white' : 'bg-purple-100 text-purple-800'}`}>
              {adminCount}
            </span>
          </button>

          {searchQuery && (
            <span className="text-xs text-slate-400 pl-2">
              Showing {filteredUsers.length} matching result{filteredUsers.length === 1 ? '' : 's'}
            </span>
          )}
        </div>
      </div>

      {/* Users Table */}
      {isLoading ? (
        <div className="py-16 text-center text-slate-400 font-medium bg-white rounded-2xl border border-slate-200">
          <div className="animate-spin w-8 h-8 border-3 border-indigo-600 border-t-transparent rounded-full mx-auto mb-3" />
          Loading user directory...
        </div>
      ) : filteredUsers.length === 0 ? (
        <div className="bg-white rounded-2xl border border-slate-200 p-12 text-center shadow-sm">
          <div className="w-12 h-12 bg-slate-100 text-slate-400 rounded-full flex items-center justify-center mx-auto mb-3">
            <Search className="w-6 h-6" />
          </div>
          <h3 className="text-base font-bold text-slate-800">No users found</h3>
          <p className="text-xs text-slate-500 mt-1 max-w-sm mx-auto">
            {searchQuery 
              ? `No user records matched your search "${searchQuery}" in this category.` 
              : 'There are no users matching the selected filters.'}
          </p>
          {searchQuery && (
            <button
              onClick={() => setSearchQuery('')}
              className="mt-4 px-4 py-1.5 text-xs font-bold text-indigo-600 bg-indigo-50 rounded-lg hover:bg-indigo-100"
            >
              Clear Search Query
            </button>
          )}
        </div>
      ) : (
        <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-slate-700">
              <thead className="bg-slate-50 text-xs font-bold uppercase tracking-wider text-slate-500 border-b border-slate-200">
                <tr>
                  <th className="px-6 py-4">User Details</th>
                  <th className="px-6 py-4">Designation / Roll No</th>
                  <th className="px-6 py-4">Department</th>
                  <th className="px-6 py-4">Role</th>
                  <th className="px-6 py-4">Status</th>
                  {isAdmin && <th className="px-6 py-4 text-right">System ID</th>}
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredUsers.map((u) => {
                  const isSelf = currentUser && u.id === currentUser.id;
                  const isFacultyUser = u.role === 'FACULTY';
                  const isStudentUser = u.role === 'STUDENT';

                  return (
                    <tr key={u.id} className="hover:bg-slate-50/70 transition-colors">
                      {/* Name and Email */}
                      <td className="px-6 py-4">
                        <div className="flex items-center space-x-3">
                          <div className={`w-10 h-10 rounded-full flex items-center justify-center font-bold text-xs shrink-0 ${
                            isFacultyUser 
                              ? 'bg-indigo-100 text-indigo-700 border border-indigo-200' 
                              : isStudentUser 
                              ? 'bg-emerald-100 text-emerald-700 border border-emerald-200'
                              : 'bg-purple-100 text-purple-700 border border-purple-200'
                          }`}>
                            {(u.name || u.email).charAt(0).toUpperCase()}
                          </div>
                          <div>
                            <div className="font-bold text-slate-900 flex items-center space-x-2">
                              <span>{formatUserNameByRole(u.name, u.role)}</span>
                              {isSelf && (
                                <span className="px-2 py-0.5 text-[10px] font-extrabold bg-indigo-100 text-indigo-700 rounded-full">
                                  You / Active Session
                                </span>
                              )}
                            </div>
                            <div className="text-xs text-slate-500 flex items-center space-x-1 mt-0.5">
                              <Mail className="w-3 h-3 text-slate-400" />
                              <span className="font-mono">{u.email}</span>
                            </div>
                          </div>
                        </div>
                      </td>

                      {/* Designation or Roll No */}
                      <td className="px-6 py-4">
                        {isFacultyUser ? (
                          <div className="flex flex-col">
                            <span className="text-xs font-bold text-slate-800">
                              {u.rollNo || 'Faculty Member'}
                            </span>
                            <span className="text-[11px] text-indigo-600 font-semibold">
                              Designated Project Guide
                            </span>
                          </div>
                        ) : isStudentUser ? (
                          <div className="flex items-center space-x-1.5">
                            <span className="px-2.5 py-1 text-xs font-mono font-bold bg-slate-100 text-slate-800 border border-slate-200 rounded-lg">
                              {u.rollNo || 'N/A'}
                            </span>
                          </div>
                        ) : (
                          <span className="text-xs font-bold text-purple-700 bg-purple-50 px-2 py-1 rounded-md border border-purple-200">
                            {u.rollNo || 'System Administration'}
                          </span>
                        )}
                      </td>

                      {/* Department */}
                      <td className="px-6 py-4">
                        <div className="flex items-center space-x-1.5 text-xs font-semibold text-slate-700">
                          <Building2 className="w-3.5 h-3.5 text-slate-400" />
                          <span>{u.departmentName ? `${u.departmentName} (${u.departmentCode})` : 'MCA (Master of Computer Applications)'}</span>
                        </div>
                      </td>

                      {/* Role Selector */}
                      <td className="px-6 py-4">
                        {isAdmin ? (
                          isSelf ? (
                            <span className="px-2.5 py-1 rounded-lg text-xs font-extrabold bg-purple-50 text-purple-700 border border-purple-200">
                              ADMIN
                            </span>
                          ) : (
                            <select
                              className="px-2.5 py-1 rounded-lg border border-slate-200 text-xs font-bold bg-white focus:ring-2 focus:ring-indigo-500"
                              value={u.role}
                              onChange={(e) => handleUpdateRole(u.id, e.target.value as Role)}
                            >
                              <option value="STUDENT">STUDENT</option>
                              <option value="FACULTY">FACULTY</option>
                              <option value="ADMIN">ADMIN</option>
                            </select>
                          )
                        ) : (
                          <span className="px-2.5 py-1 rounded-md text-xs font-bold bg-indigo-50 text-indigo-700 border border-indigo-100">
                            {u.role}
                          </span>
                        )}
                      </td>

                      {/* Status Selector */}
                      <td className="px-6 py-4">
                        {isAdmin ? (
                          <select
                            className="px-2.5 py-1 rounded-lg border border-slate-200 text-xs font-bold bg-white focus:ring-2 focus:ring-indigo-500"
                            value={u.userStatus}
                            onChange={(e) => handleUpdateStatus(u.id, e.target.value as UserStatus)}
                          >
                            <option value="ACTIVE">ACTIVE</option>
                            <option value="ALUMNI">ALUMNI</option>
                            <option value="INACTIVE">INACTIVE</option>
                          </select>
                        ) : (
                          <span
                            className={`px-2.5 py-1 rounded-md text-xs font-bold border ${
                              u.userStatus === 'ACTIVE'
                                ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                                : u.userStatus === 'ALUMNI'
                                ? 'bg-purple-50 text-purple-700 border-purple-200'
                                : 'bg-rose-50 text-rose-700 border-rose-200'
                            }`}
                          >
                            {u.userStatus}
                          </span>
                        )}
                      </td>

                      {/* Action ID */}
                      {isAdmin && (
                        <td className="px-6 py-4 text-right">
                          <span className="text-xs text-slate-400 font-mono">#{u.id}</span>
                        </td>
                      )}
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Onboard Faculty Staff Modal */}
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
    </div>
  );
};
