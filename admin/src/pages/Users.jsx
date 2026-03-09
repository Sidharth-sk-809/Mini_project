import { useEffect, useState } from 'react'
import { getUsers } from '../api/client'

const ROLE_BADGE = {
  admin:           'badge-danger',
  customer:        'badge-info',
  delivery_person: 'badge-warning',
}

const ROLE_ICON = {
  admin: '🛡️', customer: '👤', delivery_person: '🚴',
}

export default function Users() {
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [roleFilter, setRoleFilter] = useState('')
  const [search, setSearch] = useState('')

  const load = (role = roleFilter) => {
    setLoading(true)
    getUsers(role || undefined)
      .then(({ data }) => { setUsers(data); setLoading(false) })
      .catch(() => { setError('Failed to load users'); setLoading(false) })
  }

  useEffect(() => { load() }, [])

  const filtered = users.filter(
    (u) =>
      u.name.toLowerCase().includes(search.toLowerCase()) ||
      u.email.toLowerCase().includes(search.toLowerCase())
  )

  const fmt = (dt) => {
    if (!dt) return '—'
    return new Date(dt).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })
  }

  return (
    <div>
      <div className="table-wrapper">
        <div className="table-header">
          <div className="table-title">Users ({filtered.length})</div>
          <div className="table-actions">
            <div className="search-input-wrap">
              <span className="search-icon">🔍</span>
              <input className="search-input" placeholder="Search users…" value={search} onChange={(e) => setSearch(e.target.value)} />
            </div>
            <select
              className="form-input"
              style={{ width: 170, padding: '7px 12px' }}
              value={roleFilter}
              onChange={(e) => { setRoleFilter(e.target.value); load(e.target.value) }}
            >
              <option value="">All Roles</option>
              <option value="customer">Customer</option>
              <option value="delivery_person">Delivery Person</option>
              <option value="admin">Admin</option>
            </select>
          </div>
        </div>

        {loading ? (
          <div className="page-loader"><div className="spinner" style={{ width: 32, height: 32, borderColor: 'var(--border)', borderTopColor: 'var(--accent)' }} /></div>
        ) : error ? (
          <div className="alert alert-danger" style={{ margin: 20 }}>{error}</div>
        ) : filtered.length === 0 ? (
          <div className="empty-state"><div className="empty-icon">👥</div><p>No users found</p></div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>User</th>
                <th>Email</th>
                <th>Role</th>
                <th>Location</th>
                <th>Joined</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((u) => (
                <tr key={u.id}>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                      <div style={{
                        width: 32, height: 32, borderRadius: '50%',
                        background: 'linear-gradient(135deg, #4f8ef7, #7c3aed)',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        fontSize: 13, fontWeight: 700, flexShrink: 0,
                      }}>
                        {u.name?.[0]?.toUpperCase()}
                      </div>
                      <span style={{ fontWeight: 600 }}>{u.name}</span>
                    </div>
                  </td>
                  <td style={{ color: 'var(--text2)' }}>{u.email}</td>
                  <td>
                    <span className={`badge ${ROLE_BADGE[u.role] || 'badge-neutral'}`}>
                      {ROLE_ICON[u.role]} {u.role?.replace('_', ' ')}
                    </span>
                  </td>
                  <td style={{ color: 'var(--text2)' }}>{u.location || '—'}</td>
                  <td style={{ color: 'var(--text2)' }}>{fmt(u.created_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}
