import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import api, { getErrorMessage } from '../api/client';
import { 
  X, 
  ShieldCheck, 
  Mail, 
  KeyRound, 
  Lock, 
  CheckCircle2, 
  AlertCircle, 
  RefreshCw,
  Eye, 
  EyeOff
} from 'lucide-react';

interface UniversalOtpModalProps {
  isOpen: boolean;
  onClose?: () => void;
  isFirstLogin?: boolean;
  initialEmail?: string;
  onSuccess?: () => void;
}

export const UniversalOtpModal: React.FC<UniversalOtpModalProps> = ({
  isOpen,
  onClose,
  isFirstLogin = false,
  initialEmail = '',
  onSuccess
}) => {
  const navigate = useNavigate();
  const { user, logout, refreshProfile } = useAuth();

  const [email, setEmail] = useState<string>(initialEmail || user?.email || '');
  const [otpSent, setOtpSent] = useState<boolean>(false);
  const [otpCode, setOtpCode] = useState<string>('');
  const [newPassword, setNewPassword] = useState<string>('');
  const [confirmPassword, setConfirmPassword] = useState<string>('');
  const [showPassword, setShowPassword] = useState<boolean>(false);

  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  // Close handler: logs out if pending password change and redirects straight to landing page
  const handleClose = () => {
    if (user?.mustChangePassword) {
      logout();
    }
    if (onClose) {
      onClose();
    }
    navigate('/');
  };

  // Keyboard navigation & browser history integration
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        handleClose();
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen]);

  if (!isOpen) return null;

  const targetEmail = email.trim() || user?.email || '';

  const handleRequestOtp = async () => {
    if (!targetEmail) {
      setError('Please provide your official @psgtech.ac.in email address.');
      return;
    }

    setIsLoading(true);
    setError(null);
    setSuccessMsg(null);

    try {
      if (user && !isFirstLogin) {
        // Authenticated user requesting password change OTP
        await api.post('/auth/change-password-otp');
      } else {
        // First login or unauthenticated activation
        await api.post('/auth/request-otp', { email: targetEmail });
      }

      setOtpSent(true);
      setSuccessMsg(`A 6-digit verification code has been dispatched to ${targetEmail}. Valid for 10 minutes.`);
    } catch (err: any) {
      setError(getErrorMessage(err, 'Failed to dispatch verification code. Please verify your email.'));
    } finally {
      setIsLoading(false);
    }
  };

  const handleVerifyAndSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!otpCode || otpCode.trim().length !== 6) {
      setError('Please enter the 6-digit OTP code sent to your email.');
      return;
    }

    if (newPassword.length < 8) {
      setError('New password must be at least 8 characters long.');
      return;
    }

    if (newPassword !== confirmPassword) {
      setError('Passwords do not match. Please re-enter.');
      return;
    }

    setIsLoading(true);
    setError(null);
    setSuccessMsg(null);

    try {
      if (user && !isFirstLogin) {
        // User logged in changing password
        await api.post('/auth/change-password-verify', {
          otpCode: otpCode.trim(),
          newPassword
        });
      } else {
        // First login activation for Faculty / Student
        const res = await api.post('/auth/faculty-first-login', {
          email: targetEmail,
          otpCode: otpCode.trim(),
          newPassword
        });

        // If returned JWT auth token, store and refresh
        if (res.data?.data?.accessToken) {
          localStorage.setItem('auth_token', res.data.data.accessToken);
        }
      }

      setSuccessMsg('Verification successful! Your new confidential password has been set.');
      await refreshProfile();

      setTimeout(() => {
        if (onSuccess) onSuccess();
        if (onClose) onClose();
      }, 1500);

    } catch (err: any) {
      setError(getErrorMessage(err, 'Verification failed. Please check the OTP or request a new code.'));
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto bg-slate-900/60 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="relative bg-white rounded-2xl shadow-2xl max-w-md w-full border border-slate-200 overflow-hidden animate-in fade-in zoom-in-95 duration-200">
        
        {/* Header */}
        <div className="bg-gradient-to-r from-indigo-700 via-indigo-800 to-slate-900 text-white p-6 relative">
          {/* Universal Close Cross Button */}
          <button
            type="button"
            onClick={handleClose}
            aria-label="Close modal and return"
            title="Close and return (Esc)"
            className="absolute top-4 right-4 text-slate-300 hover:text-white p-1.5 rounded-xl hover:bg-white/10 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>

          <div className="flex items-center gap-3 pr-8">
            <div className="w-10 h-10 rounded-xl bg-white/10 flex items-center justify-center backdrop-blur-sm shrink-0">
              <ShieldCheck className="w-6 h-6 text-indigo-300" />
            </div>
            <div>
              <h3 className="text-lg font-bold leading-tight">
                {isFirstLogin ? 'First-Login Verification' : 'Email OTP Password Security'}
              </h3>
              <p className="text-xs text-indigo-200 mt-0.5">
                PSG Tech MCA Department &bull; Universal Security Protocol
              </p>
            </div>
          </div>
        </div>

        {/* Body */}
        <div className="p-6 space-y-4">

          {isFirstLogin && (
            <div className="p-3 bg-amber-50 border border-amber-200 rounded-xl text-amber-900 text-xs leading-relaxed">
              <strong>Institutional Security Notice:</strong> All accounts (Faculty, Admin & Students) must verify their registered college email via One-Time Password on first login and set a private, confidential password.
            </div>
          )}

          {error && (
            <div className="p-3 bg-rose-50 border border-rose-200 rounded-xl text-rose-700 text-xs flex items-start gap-2">
              <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
              <span>{error}</span>
            </div>
          )}

          {successMsg && (
            <div className="p-3 bg-emerald-50 border border-emerald-200 rounded-xl text-emerald-800 text-xs flex items-start gap-2">
              <CheckCircle2 className="w-4 h-4 shrink-0 mt-0.5" />
              <span>{successMsg}</span>
            </div>
          )}

          {/* Email verification row */}
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
              Registered PSG Tech Email
            </label>
            <div className="flex gap-2">
              <div className="relative flex-1">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
                  <Mail className="w-4 h-4" />
                </div>
                <input
                  type="email"
                  disabled={!!user || otpSent}
                  value={targetEmail}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="rollno@psgtech.ac.in / name@psgtech.ac.in"
                  className="w-full pl-9 pr-3 py-2 text-xs rounded-xl border border-slate-300 bg-slate-50 text-slate-900 disabled:opacity-75 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <button
                type="button"
                onClick={handleRequestOtp}
                disabled={isLoading}
                className="px-3.5 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white text-xs font-semibold rounded-xl shadow-sm transition-colors flex items-center gap-1.5 shrink-0"
              >
                {isLoading ? (
                  <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                ) : (
                  <KeyRound className="w-3.5 h-3.5" />
                )}
                <span>{otpSent ? 'Resend' : 'Send OTP'}</span>
              </button>
            </div>
          </div>

          {/* Form for OTP + New Password */}
          {otpSent && (
            <form onSubmit={handleVerifyAndSubmit} className="space-y-4 pt-2 border-t border-slate-100">
              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                  6-Digit Verification OTP Code *
                </label>
                <input
                  type="text"
                  maxLength={6}
                  required
                  autoFocus
                  placeholder="123456"
                  value={otpCode}
                  onChange={(e) => setOtpCode(e.target.value.replace(/\D/g, ''))}
                  className="w-full text-center tracking-[0.5em] font-mono text-xl py-2.5 rounded-xl border-2 border-indigo-300 focus:border-indigo-600 focus:outline-none focus:ring-2 focus:ring-indigo-200 text-indigo-950 font-bold bg-indigo-50/30"
                />
                <p className="text-[11px] text-slate-500 mt-1">
                  Enter the 6-digit code received on your college email.
                </p>
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                  New Private Password *
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
                    <Lock className="w-4 h-4" />
                  </div>
                  <input
                    type={showPassword ? 'text' : 'password'}
                    required
                    minLength={8}
                    placeholder="Minimum 8 characters"
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    className="w-full pl-9 pr-9 py-2 text-xs rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500 text-slate-900"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute inset-y-0 right-0 pr-3 flex items-center text-slate-400 hover:text-slate-600"
                  >
                    {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold uppercase tracking-wider text-slate-700 mb-1.5">
                  Confirm Password *
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400">
                    <Lock className="w-4 h-4" />
                  </div>
                  <input
                    type={showPassword ? 'text' : 'password'}
                    required
                    minLength={8}
                    placeholder="Re-enter password"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    className="w-full pl-9 pr-3 py-2 text-xs rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-indigo-500 text-slate-900"
                  />
                </div>
              </div>

              <button
                type="submit"
                disabled={isLoading}
                className="w-full py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white font-semibold text-xs shadow-md transition-colors flex items-center justify-center gap-2"
              >
                {isLoading ? (
                  <RefreshCw className="w-4 h-4 animate-spin" />
                ) : (
                  <ShieldCheck className="w-4 h-4" />
                )}
                <span>Verify OTP & Set Confidential Password</span>
              </button>
            </form>
          )}


        </div>
      </div>
    </div>
  );
};
