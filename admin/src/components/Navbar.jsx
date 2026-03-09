import { useEffect, useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useShop } from '../context/ShopContext';
import { getShops } from '../api/admin';

const NAV_ITEMS = [
  { to: '/dashboard', label: 'Overview' },
  { to: '/products', label: 'Products' },
  { to: '/orders', label: 'Realtime Orders' },
  { to: '/shops', label: 'Shops' },
  { to: '/users', label: 'Users' },
];

export default function Navbar() {
  const { user, logout } = useAuth();
  const { selectedShopCode, setShop } = useShop();
  const location = useLocation();

  const [shops, setShops] = useState([]);

  useEffect(() => {
    getShops()
      .then(({ data }) => setShops(data))
      .catch(() => setShops([]));
  }, []);

  return (
    <header className="navbar-shell">
      <div className="navbar-brand">
        <div className="brand-icon">NP</div>
        <div>
          <p className="brand-name">Neamet Admin</p>
          <p className="brand-tag">Shop Owner Console</p>
        </div>
      </div>

      <nav className="navbar-links">
        {NAV_ITEMS.map((item) => (
          <Link
            key={item.to}
            to={item.to}
            className={`nav-link ${location.pathname === item.to ? 'active' : ''}`}
          >
            {item.label}
          </Link>
        ))}
      </nav>

      <div className="navbar-right">
        <div className="shop-select-wrap">
          <label htmlFor="nav-shop" className="shop-select-label">Workspace</label>
          <select
            id="nav-shop"
            className="shop-select"
            value={selectedShopCode}
            onChange={(e) => setShop(e.target.value)}
          >
            <option value="">All shops</option>
            {shops.map((shop) => (
              <option key={shop.code} value={shop.code}>{shop.name}</option>
            ))}
          </select>
        </div>

        <div className="user-meta">
          <span className="avatar">{user?.name?.charAt(0)?.toUpperCase() ?? 'A'}</span>
          <div>
            <p className="user-name">{user?.name ?? 'Admin User'}</p>
            <p className="user-email">{user?.email ?? ''}</p>
          </div>
        </div>

        <button className="btn-outline" onClick={logout}>Sign out</button>
      </div>
    </header>
  );
}
