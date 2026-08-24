import React, { useState, useEffect } from 'react';
import { Navigate } from 'react-router-dom';
import { User, Role, UserStatus, ApiResponse, PageResponse } from '../types';
import api, { getErrorMessage } from '../api/client';
import { useAuth } from '../context/AuthContext';
import { Users as UsersIcon, AlertCircle } from 'lucide-react';

export const UsersPage: React.FC = () => {
  const { user: currentUser, isLoading: isAuthLoading } = useAuth();
  const [users, setUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Filters
  const [selectedRole, setSelectedRole] = useState<string>('');
  const [selectedStatus, setSelectedStatus] = useState<string>('');

  useEffect(() => {
    if (!isAuthLoading && currentUser && currentUser.role === 'ADMIN') {
      fetchUsers();
    }
  }, [selectedRole, selectedStatus, isAuthLoading, currentUser]);

  const fetchUsers = async () => {
    setIsLoading(true);
    setError(null);
    try {
      let url = '/users?size=100';
      if (selectedRole) url += `&role=${selectedRole}`;
      if (selectedStatus) url += `&userStatus=${selectedStatus}`;

      const res = await api.get<ApiResponse<PageResponse<User>>>(url);
      if (res.data && res.data.data && res.data.data.content) {
        setUsers(res.data.data.content);
      }
    } catch (err: any) {
      setError(getErrorMessage(err, 'Failed to fetch user directory'));
    } finally {
      setIsLoading(false);
    }
  };

  if (isAuthLoading) {
    return (
      <div className="min-h-[70vh] flex items-center justify-center">
        <div className="text-slate-400 font-semibold animate-pulse text-sm">
          Loading User Directory...
        </div>
      </div>
    );
  }

  if (!currentUser || currentUser.role !== 'ADMIN') {
    return <Navigate to="/" replace />;
  }

  const [successMsg, setSuccessMsg] = useState<string | null>(null);

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

  const isAdmin = currentUser?.role === 'ADMIN';

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-6 rounded-2xl shadow-sm border border-slate-200">
        <div>
          <h1 className="text-2xl font-extrabold text-slate-900 tracking-tight flex items-center space-x-2">
            <UsersIcon className="w-6 h-6 text-indigo-600" />
            <span>User Management Directory</span>
          </h1>
          <p className="text-sm text-slate-500 mt-1">
            Manage system permissions, roles, and student graduation status
          </p>
        </div>

        {/* Filter Bar */}
        <div className="flex items-center space-x-3">
          <select
            className="px-3 py-2 rounded-xl border border-slate-300 text-sm text-slate-900 bg-white"
            value={selectedRole}
            onChange={(e) => setSelectedRole(e.target.value)}
          >
            <option value="">All Roles</option>
            <option value="STUDENT">Students</option>
            <option value="FACULTY">Faculty</option>
            <option value="ADMIN">Admins</option>
          </select>

          <select
            className="px-3 py-2 rounded-xl border border-slate-300 text-sm text-slate-900 bg-white"
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

      {successMsg && (
        <div className="p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-sm font-semibold flex items-center justify-between">
          <span>{successMsg}</span>
          <button onClick={() => setSuccessMsg(null)} className="text-emerald-600 hover:text-emerald-900 text-xs font-bold uppercase">Dismiss</button>
        </div>
      )}

      {error && (
        <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-sm flex items-start space-x-2">
          <AlertCircle className="w-5 h-5 mt-0.5 shrink-0" />
          <span>{error}</span>
        </div>
      )}

      {/* Users Table */}
      {isLoading ? (
        <div className="py-12 text-center text-slate-400 font-medium">Loading user directory...</div>
      ) : (
        <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-slate-700">
              <thead className="bg-slate-50 text-xs font-bold uppercase tracking-wider text-slate-500 border-b border-slate-200">
                <tr>
                  <th className="px-6 py-4">User</th>
                  <th className="px-6 py-4">Department</th>
                  <th className="px-6 py-4">System Role</th>
                  <th className="px-6 py-4">Lifecycle Status</th>
                  {isAdmin && <th className="px-6 py-4 text-right">Actions</th>}
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {users.map((u) => {
                  const isSelf = currentUser && u.id === currentUser.id;
                  return (
                    <tr key={u.id} className="hover:bg-slate-50/50 transition-colors">
                      <td className="px-6 py-4">
                        <div className="flex items-center space-x-3">
                          <div className="w-9 h-9 rounded-full bg-indigo-100 text-indigo-700 flex items-center justify-center font-bold text-xs">
                            {u.firstName.charAt(0)}
                            {u.lastName.charAt(0)}
                          </div>
                          <div>
                            <div className="font-semibold text-slate-900 flex items-center space-x-2">
                              <span>{u.firstName} {u.lastName}</span>
                              {isSelf && (
                                <span className="px-2 py-0.5 text-[10px] font-extrabold bg-indigo-100 text-indigo-700 rounded-full">
                                  You / Active Session
                                </span>
                              )}
                            </div>
                            <div className="text-xs text-slate-500">{u.email}</div>
                          </div>
                        </div>
                      </td>

                      <td className="px-6 py-4 font-medium text-slate-800">
                        {u.departmentName ? `${u.departmentName} (${u.departmentCode})` : <span className="text-slate-400 italic">None</span>}
                      </td>

                      <td className="px-6 py-4">
                        {isAdmin ? (
                          isSelf ? (
                            <span className="px-2.5 py-1 rounded-md text-xs font-bold bg-indigo-50 text-indigo-700 border border-indigo-200">
                              {u.role} (Primary Admin)
                            </span>
                          ) : (
                            <select
                              className="px-2.5 py-1 rounded-lg border border-slate-200 text-xs font-semibold bg-white"
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

                      <td className="px-6 py-4">
                        {isAdmin ? (
                          <select
                            className="px-2.5 py-1 rounded-lg border border-slate-200 text-xs font-semibold bg-white"
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

                      {isAdmin && (
                        <td className="px-6 py-4 text-right">
                          <span className="text-xs text-slate-400 font-mono">ID #{u.id}</span>
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
    </div>
  );
};
