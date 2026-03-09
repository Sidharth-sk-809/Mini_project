import { createContext, useContext, useState, useCallback } from 'react';
import { login as loginApi } from '../api/auth';
import { logAdminAction } from '../api/audit';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => {
    try {
      const u = localStorage.getItem('admin_user');
      return u ? JSON.parse(u) : null;
    } catch {
      return null;
    }
  });

  const login = useCallback(async (email, password) => {
    const { data } = await loginApi(email, password);
    if (data.role !== 'admin') {
      throw new Error('Access denied: admin role required');
    }
    localStorage.setItem('admin_token', data.access_token);
    localStorage.setItem('admin_user', JSON.stringify(data));
    setUser(data);
    void logAdminAction({
      action: 'admin_login',
      entityType: 'auth',
      entityId: String(data.user_id ?? data.id ?? ''),
      payload: { email: data.email, role: data.role },
    });
    return data;
  }, []);

  const logout = useCallback(() => {
    void logAdminAction({
      action: 'admin_logout',
      entityType: 'auth',
      entityId: String(user?.user_id ?? user?.id ?? ''),
      payload: { email: user?.email ?? null },
    });
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
    localStorage.removeItem('admin_selected_shop_code');
    setUser(null);
  }, [user]);

  return (
    <AuthContext.Provider value={{ user, login, logout, isAuthenticated: !!user }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
