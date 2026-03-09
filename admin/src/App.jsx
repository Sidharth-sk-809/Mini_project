import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { ShopProvider } from './context/ShopContext';
import Navbar from './components/Navbar';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Products from './pages/Products';
import Shops from './pages/Shops';
import Users from './pages/Users';
import Orders from './pages/Orders';

function PrivateLayout({ children }) {
  const { isAuthenticated } = useAuth();
  const hasToken = !!localStorage.getItem('admin_token');
  if (!isAuthenticated && !hasToken) return <Navigate to="/login" replace />;

  return (
    <div className="app-layout">
      <Navbar />
      <main className="main-content">{children}</main>
    </div>
  );
}

function PublicRoute({ children }) {
  const { isAuthenticated } = useAuth();
  const hasToken = !!localStorage.getItem('admin_token');
  if (isAuthenticated || hasToken) return <Navigate to="/dashboard" replace />;
  return children;
}

export default function App() {
  return (
    <AuthProvider>
      <ShopProvider>
        <BrowserRouter>
          <Routes>
            <Route
              path="/login"
              element={<PublicRoute><Login /></PublicRoute>}
            />
            <Route path="/dashboard" element={<PrivateLayout><Dashboard /></PrivateLayout>} />
            <Route path="/products" element={<PrivateLayout><Products /></PrivateLayout>} />
            <Route path="/shops" element={<PrivateLayout><Shops /></PrivateLayout>} />
            <Route path="/users" element={<PrivateLayout><Users /></PrivateLayout>} />
            <Route path="/orders" element={<PrivateLayout><Orders /></PrivateLayout>} />
            <Route path="*" element={<Navigate to="/dashboard" replace />} />
          </Routes>
        </BrowserRouter>
      </ShopProvider>
    </AuthProvider>
  );
}
