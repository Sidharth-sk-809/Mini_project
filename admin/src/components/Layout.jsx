import { useState } from 'react'
import { Outlet, useLocation } from 'react-router-dom'
import Sidebar from './Sidebar'

const PAGE_TITLES = {
  '/':          { title: 'Dashboard',  sub: 'Platform overview & key metrics' },
  '/products':  { title: 'Products',   sub: 'Manage all products across shops' },
  '/shops':     { title: 'Shops',      sub: 'Manage shop listings' },
  '/users':     { title: 'Users',      sub: 'View registered users' },
  '/orders':    { title: 'Orders',     sub: 'View customer orders' },
}

export default function Layout() {
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const { pathname } = useLocation()
  const page = PAGE_TITLES[pathname] || { title: 'Admin', sub: '' }

  return (
    <div className="app-shell">
      <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />
      <div className="main-content">
        <header className="topbar">
          <div className="topbar-left">
            <button
              className="btn btn-ghost btn-icon"
              style={{ display: 'none' }}
              id="menu-btn"
              onClick={() => setSidebarOpen(true)}
              aria-label="Menu"
            >
              ☰
            </button>
            <div>
              <div className="topbar-title">{page.title}</div>
              <div className="topbar-sub">{page.sub}</div>
            </div>
          </div>
          <div className="topbar-right">
            <span style={{ fontSize: 12, color: 'var(--text3)', fontFamily: 'monospace' }}>
              neamet-admin v1.0
            </span>
          </div>
        </header>
        <main className="page-content">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
