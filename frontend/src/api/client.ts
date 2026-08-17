import axios from 'axios';

const api = axios.create({
  baseURL: '/api/v1',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request Interceptor: Attach JWT Token if available
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('pv_token');
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response Interceptor: Handle 401 Unauthorized globally
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      // Clear token on auth failure if token expired or invalid
      if (localStorage.getItem('pv_token')) {
        localStorage.removeItem('pv_token');
        localStorage.removeItem('pv_user');
      }
    }
    return Promise.reject(error);
  }
);

export const getErrorMessage = (err: any, defaultMsg: string = 'An error occurred'): string => {
  if (err?.response?.data) {
    const data = err.response.data;
    if (data.details && Array.isArray(data.details) && data.details.length > 0) {
      return data.details.join('; ');
    }
    if (data.message) {
      return data.message;
    }
    if (typeof data === 'string') {
      return data;
    }
  }
  return err?.message || defaultMsg;
};

export default api;
