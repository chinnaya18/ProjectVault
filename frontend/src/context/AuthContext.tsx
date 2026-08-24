import React, { createContext, useContext, useState, useEffect } from 'react';
import { User, AuthResponse, LoginRequest, RegisterRequest, ApiResponse } from '../types';
import api from '../api/client';

interface AuthContextType {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (credentials: LoginRequest) => Promise<void>;
  register: (data: RegisterRequest) => Promise<void>;
  logout: () => void;
  refreshProfile: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(() => {
    try {
      const saved = localStorage.getItem('pv_user');
      return saved ? JSON.parse(saved) : null;
    } catch {
      return null;
    }
  });

  const [token, setToken] = useState<string | null>(() => {
    return localStorage.getItem('pv_token') || null;
  });

  const [isLoading, setIsLoading] = useState<boolean>(true);

  useEffect(() => {
    let isMounted = true;
    const initAuth = async () => {
      if (token) {
        try {
          const res = await api.get<ApiResponse<User>>('/auth/me');
          if (isMounted && res.data && res.data.data) {
            setUser(res.data.data);
            localStorage.setItem('pv_user', JSON.stringify(res.data.data));
          }
        } catch (err: any) {
          console.error('Failed to fetch user profile on init:', err);
          if (err.response?.status === 401 && isMounted) {
            setToken(null);
            setUser(null);
            localStorage.removeItem('pv_token');
            localStorage.removeItem('pv_user');
          }
        }
      }
      if (isMounted) {
        setIsLoading(false);
      }
    };
    initAuth();
    return () => {
      isMounted = false;
    };
  }, []);

  const handleAuthSuccess = (authData: AuthResponse) => {
    const jwtToken = authData.accessToken || authData.token || '';
    setToken(jwtToken);
    setUser(authData.user);
    localStorage.setItem('pv_token', jwtToken);
    localStorage.setItem('pv_user', JSON.stringify(authData.user));
  };

  const login = async (credentials: LoginRequest) => {
    const res = await api.post<ApiResponse<AuthResponse>>('/auth/login', credentials);
    if (res.data && res.data.data) {
      handleAuthSuccess(res.data.data);
    }
  };

  const register = async (data: RegisterRequest) => {
    const res = await api.post<ApiResponse<AuthResponse>>('/auth/register', data);
    if (res.data && res.data.data) {
      handleAuthSuccess(res.data.data);
    }
  };

  const logout = () => {
    setToken(null);
    setUser(null);
    localStorage.removeItem('pv_token');
    localStorage.removeItem('pv_user');
  };

  const refreshProfile = async () => {
    if (!token) return;
    try {
      const res = await api.get<ApiResponse<User>>('/auth/me');
      if (res.data && res.data.data) {
        setUser(res.data.data);
        localStorage.setItem('pv_user', JSON.stringify(res.data.data));
      }
    } catch (err) {
      console.error(err);
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        isAuthenticated: !!token && !!user,
        isLoading,
        login,
        register,
        logout,
        refreshProfile,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
