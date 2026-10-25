import React, { useState } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { BookOpen, FolderGit2, Users, LogOut, LogIn, BarChart3, ShieldAlert, KeyRound } from 'lucide-react';
import { formatUserNameByRole } from '../utils/userFormat';
import { UniversalOtpModal } from './UniversalOtpModal';

export const Navbar: React.FC = () => {
  const { user, isAuthenticated, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [isOtpModalOpen, setIsOtpModalOpen] = useState<boolean>(false);

  const handleLogout = () => {
    logout();
    navigate('/');
  };

  const isActive = (path: string) => location.pathname === path;

  return (
    <header className="bg-white border-b border-slate-200 sticky top-0 z-40 shadow-sm">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo & Title */}
          <Link to="/" className="flex items-center space-x-3 group">
            <div className="w-10 h-10 rounded-xl bg-indigo-600 flex items-center justify-center text-white shadow-md group-hover:bg-indigo-700 transition-colors">
              <BookOpen className="w-5 h-5" />
            </div>
            <div>
              <span className="text-xl font-bold tracking-tight text-slate-900 group-hover:text-indigo-600 transition-colors">
                ProjectVault
              </span>
              <span className="hidden sm:inline-block ml-2 text-xs font-semibold px-2 py-0.5 rounded-full bg-indigo-50 text-indigo-700 border border-indigo-100">
                Academic Hub
              </span>
            </div>
          </Link>

          {/* Navigation Links */}
          <nav className="hidden md:flex items-center space-x-1 lg:space-x-2">
            <Link
              to="/"
              className={`flex items-center space-x-2 px-3.5 py-2 rounded-xl text-sm font-semibold transition-all whitespace-nowrap ${
                isActive('/')
                  ? 'bg-indigo-50 text-indigo-700 shadow-xs'
                  : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
              }`}
            >
              <FolderGit2 className="w-4 h-4" />
              <span>Projects</span>
            </Link>

            {user && user.role === 'ADMIN' && (
              <>
                <Link
                  to="/analytics"
                  className={`flex items-center space-x-2 px-3.5 py-2 rounded-xl text-sm font-semibold transition-all whitespace-nowrap ${
                    isActive('/analytics')
                      ? 'bg-indigo-50 text-indigo-700 shadow-xs'
                      : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                  }`}
                >
                  <BarChart3 className="w-4 h-4" />
                  <span>Analytics</span>
                </Link>
                <Link
                  to="/users"
                  className={`flex items-center space-x-2 px-3.5 py-2 rounded-xl text-sm font-semibold transition-all whitespace-nowrap ${
                    isActive('/users')
                      ? 'bg-indigo-50 text-indigo-700 shadow-xs'
                      : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                  }`}
                >
                  <Users className="w-4 h-4" />
                  <span>Users & Roster</span>
                </Link>
                <Link
                  to="/audit-logs"
                  className={`flex items-center space-x-2 px-3.5 py-2 rounded-xl text-sm font-semibold transition-all whitespace-nowrap ${
                    isActive('/audit-logs')
                      ? 'bg-indigo-50 text-indigo-700 shadow-xs'
                      : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                  }`}
                >
                  <ShieldAlert className="w-4 h-4" />
                  <span>Audit Trail</span>
                </Link>
              </>
            )}
          </nav>

          {/* Right Action Menu */}
          <div className="flex items-center space-x-2.5 sm:space-x-3">
            {isAuthenticated && user ? (
              <div className="flex items-center space-x-2 sm:space-x-3">
                {/* User Profile Badge Card */}
                <div className="hidden sm:flex items-center space-x-2.5 px-3 py-1.5 rounded-xl bg-slate-50 border border-slate-200">
                  <div className="w-7 h-7 rounded-lg bg-indigo-600 text-white flex items-center justify-center font-bold text-xs uppercase shadow-xs">
                    {(user.name || user.email)[0]}
                  </div>
                  <div className="flex flex-col text-left">
                    <div className="flex items-center space-x-1.5">
                      <span className="text-xs font-bold text-slate-800 whitespace-nowrap">
                        {formatUserNameByRole(user.name || user.email.split('@')[0], user.role)}
                      </span>
                      {user.rollNo && (
                        <span className="text-[10px] font-mono font-bold px-1.5 py-0.5 rounded bg-white text-slate-600 border border-slate-200 whitespace-nowrap">
                          {user.rollNo}
                        </span>
                      )}
                    </div>
                    <span className="text-[10px] font-bold text-indigo-600 uppercase tracking-wider whitespace-nowrap">
                      {user.role}
                    </span>
                  </div>
                </div>

                {/* Change Password Button */}
                <button
                  onClick={() => setIsOtpModalOpen(true)}
                  className="flex items-center space-x-1.5 px-3 py-1.5 sm:py-2 rounded-xl text-xs font-semibold text-slate-700 hover:text-indigo-600 hover:bg-indigo-50 transition-all border border-slate-200 bg-white shadow-xs whitespace-nowrap"
                  title="Change Password with Institutional Email OTP"
                >
                  <KeyRound className="w-3.5 h-3.5 text-indigo-600" />
                  <span className="hidden md:inline">Change Password</span>
                </button>

                {/* Logout Button */}
                <button
                  onClick={handleLogout}
                  className="flex items-center space-x-1.5 px-3 py-1.5 sm:py-2 rounded-xl text-xs font-semibold text-slate-700 hover:text-rose-600 hover:bg-rose-50 transition-all border border-slate-200 bg-white shadow-xs whitespace-nowrap"
                  title="Logout"
                >
                  <LogOut className="w-3.5 h-3.5 text-rose-500" />
                  <span className="hidden md:inline">Logout</span>
                </button>
              </div>
            ) : (
              <div className="flex items-center space-x-2">
                <Link
                  to="/login"
                  className="flex items-center space-x-1.5 px-3.5 py-2 rounded-xl text-sm font-semibold bg-indigo-600 text-white hover:bg-indigo-700 transition-colors shadow-xs whitespace-nowrap"
                >
                  <LogIn className="w-4 h-4" />
                  <span>Login</span>
                </Link>
              </div>
            )}
          </div>
        </div>
      </div>

      <UniversalOtpModal
        isOpen={isOtpModalOpen}
        onClose={() => setIsOtpModalOpen(false)}
      />
    </header>
  );
};
