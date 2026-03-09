import { useEffect, useState } from 'react';
import { getUsers } from '../api/admin';

const ROLE_COLORS = {
  admin: { bg: '#fef3c7', text: '#d97706' },
  customer: { bg: '#dbeafe', text: '#2563eb' },
  delivery_person: { bg: '#d1fae5', text: '#059669' },
};

export default function Users() {
  const [users, setUsers] = useState([]);
  const [filter, setFilter] = useState('');
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    getUsers(filter || undefined)
      .then(({ data }) => setUsers(data))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [filter]);

  const filtered = users.filter(
    (u) =>
      u.name.toLowerCase().includes(search.toLowerCase()) ||
      u.email.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <h2 className="page-title">Users</h2>
          <p className="page-sub">View all registered users.</p>
        </div>
        <div className="header-count">
          <span className="count-badge">{users.length} users</span>
        </div>
      </div>

      {/* Filters */}
      <div className="filter-bar">
        <input
          className="search-input"
          placeholder="Search by name or email…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <div className="role-tabs">
          {['', 'customer', 'delivery_person', 'admin'].map((r) => (
            <button
              key={r}
              className={`role-tab ${filter === r ? 'active' : ''}`}
              onClick={() => setFilter(r)}
            >
              {r === '' ? 'All' : r === 'delivery_person' ? 'Delivery' : r.charAt(0).toUpperCase() + r.slice(1)}
            </button>
          ))}
        </div>
      </div>

      {/* Table */}
      <div className="table-card">
        {loading ? (
          <div className="table-loading">Loading…</div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Role</th>
                <th>Location</th>
                <th>Joined</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 && (
                <tr><td colSpan={5} className="empty-msg">No users found.</td></tr>
              )}
              {filtered.map((u) => {
                const color = ROLE_COLORS[u.role] ?? { bg: '#f3f4f6', text: '#4b5563' };
                return (
                  <tr key={u.id}>
                    <td>
                      <div className="user-cell">
                        <div className="user-initials">
                          {u.name.split(' ').map((w) => w[0]).join('').toUpperCase().slice(0, 2)}
                        </div>
                        <span>{u.name}</span>
                      </div>
                    </td>
                    <td>{u.email}</td>
                    <td>
                      <span className="badge" style={{ background: color.bg, color: color.text }}>
                        {u.role}
                      </span>
                    </td>
                    <td>{u.location || '—'}</td>
                    <td>{new Date(u.created_at).toLocaleDateString('en-IN')}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
