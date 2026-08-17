import React from 'react';
import { useAuth } from '../context/AuthContext';
import { PublicLandingPage } from '../components/PublicLandingPage';
import { UserDashboard } from '../components/UserDashboard';

export const HomePage: React.FC = () => {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="min-h-[70vh] flex items-center justify-center">
        <div className="text-slate-400 font-semibold animate-pulse text-sm">
          Loading ProjectVault...
        </div>
      </div>
    );
  }

  return isAuthenticated ? <UserDashboard /> : <PublicLandingPage />;
};
