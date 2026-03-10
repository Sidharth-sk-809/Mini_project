import axios from 'axios';

const BASE_URL = 'https://neamet-backend-nfbh.onrender.com';

const client = axios.create({
  baseURL: BASE_URL,
  headers: { 'Content-Type': 'application/json' },
});

// Attach token from localStorage on every request
client.interceptors.request.use((config) => {
  const token = localStorage.getItem('admin_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Redirect to login on 401/403 ONLY for protected API calls, not auth endpoints
client.interceptors.response.use(
  (res) => res,
  (err) => {
    const url = err.config?.url ?? '';
    const isAuthEndpoint = url.includes('/api/auth/');
    if (!isAuthEndpoint && (err.response?.status === 401 || err.response?.status === 403)) {
      localStorage.removeItem('admin_token');
      localStorage.removeItem('admin_user');
      window.location.href = '/login';
    }
    return Promise.reject(err);
  }
);

export default client;
