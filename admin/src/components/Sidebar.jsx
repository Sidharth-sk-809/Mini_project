import { NavLink, useLocation } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'

const navItems = [
  { to: '/',          icon: '📊', label: 'Dashboard'  },
  { to: '/products',  icon: '📦', label: 'Products'   },
  { to: '/shops',     icon: '🏪', label: 'Shops'      },
  { to: '/users',     icon: '👥', label: 'Users'      },
  { to: '/orders',    icon: '🧾', label: 'Orders'     },
]

export default function Sidebar({ open, onClose }) {
  const { user, logout } = useAuth()
  const location = useLocation()

  return (
    <>
      {/* Mobile overlay */}
      {open && (
        <div
          style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', zIndex: 99 }}
          onClick={onClose}
        />
      )}

      <aside className={`sidebar${open ? ' open' : ''}`}>
        <div className="sidebar-logo">
          <div className="logo-icon">🌿</div>
          <div>
            <div className="sidebar-logo-text">Neamet</div>
            <div className="sidebar-logo-sub">Admin Panel</div>
          </div>
        </div>

        <nav className="sidebar-nav">
          <div className="nav-section-label">Main</div>
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              className={({ isActive }) => `nav-item${isActive ? ' active' : ''}`}
              onClick={onClose}
            >
              <span className="icon">{item.icon}</span>
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div className="sidebar-footer">
          <div className="user-info">
            <div className="user-avatar">{user?.name?.[0] || 'A'}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div className="user-name" style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                {user?.name || 'Admin'}
              </div>
              <div className="user-role">{user?.email}</div>
            </div>
            <button
              onClick={logout}
              style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text3)', fontSize: 18, flexShrink: 0 }}
              title="Logout"
            >
              ↩
            </button>
          </div>
        </div>
      </aside>
    </>
  )
}
