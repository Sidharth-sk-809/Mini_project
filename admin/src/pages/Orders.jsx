import { useEffect, useState } from 'react'
import { getOrders } from '../api/client'

const STATUS_BADGE = {
  placed:     'badge-info',
  confirmed:  'badge-warning',
  packed:     'badge-warning',
  picked_up:  'badge-warning',
  delivered:  'badge-success',
  cancelled:  'badge-danger',
}

const STATUS_ICON = {
  placed: '🆕', confirmed: '✅', packed: '📦',
  picked_up: '🛵', delivered: '🎉', cancelled: '❌',
}

export default function Orders() {
  const [orders, setOrders] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [statusFilter, setStatusFilter] = useState('')
  const [search, setSearch] = useState('')

  const load = (status = statusFilter) => {
    setLoading(true)
    getOrders(status || undefined)
      .then(({ data }) => { setOrders(data); setLoading(false) })
      .catch(() => { setError('Failed to load orders'); setLoading(false) })
  }

  useEffect(() => { load() }, [])

  const filtered = orders.filter(
    (o) =>
      o.order_code?.toLowerCase().includes(search.toLowerCase()) ||
      String(o.customer_user_id).includes(search) ||
      o.delivery_address?.toLowerCase().includes(search.toLowerCase())
  )

  const fmt = (dt) => {
    if (!dt) return '—'
    return new Date(dt).toLocaleString('en-IN', {
      day: '2-digit', month: 'short', year: 'numeric',
      hour: '2-digit', minute: '2-digit',
    })
  }

  return (
    <div>
      <div className="table-wrapper">
        <div className="table-header">
          <div className="table-title">Orders ({filtered.length})</div>
          <div className="table-actions">
            <div className="search-input-wrap">
              <span className="search-icon">🔍</span>
              <input className="search-input" placeholder="Search orders…" value={search} onChange={(e) => setSearch(e.target.value)} />
            </div>
            <select
              className="form-input"
              style={{ width: 170, padding: '7px 12px' }}
              value={statusFilter}
              onChange={(e) => { setStatusFilter(e.target.value); load(e.target.value) }}
            >
              <option value="">All Statuses</option>
              <option value="placed">Placed</option>
              <option value="confirmed">Confirmed</option>
              <option value="packed">Packed</option>
              <option value="picked_up">Picked Up</option>
              <option value="delivered">Delivered</option>
              <option value="cancelled">Cancelled</option>
            </select>
          </div>
        </div>

        {loading ? (
          <div className="page-loader"><div className="spinner" style={{ width: 32, height: 32, borderColor: 'var(--border)', borderTopColor: 'var(--accent)' }} /></div>
        ) : error ? (
          <div className="alert alert-danger" style={{ margin: 20 }}>{error}</div>
        ) : filtered.length === 0 ? (
          <div className="empty-state"><div className="empty-icon">🧾</div><p>No orders found</p></div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Order Code</th>
                <th>Customer ID</th>
                <th>Address</th>
                <th>Items</th>
                <th>Total</th>
                <th>Status</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((o) => (
                <tr key={o.id}>
                  <td><span className="td-code">{o.order_code}</span></td>
                  <td><span className="badge badge-neutral">#{o.customer_user_id}</span></td>
                  <td style={{ color: 'var(--text2)', maxWidth: 180, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {o.delivery_address || '—'}
                  </td>
                  <td style={{ textAlign: 'center' }}>{o.total_items}</td>
                  <td style={{ fontWeight: 700 }}>
                    ₹{Number(o.grand_total).toLocaleString('en-IN', { maximumFractionDigits: 2 })}
                  </td>
                  <td>
                    <span className={`badge ${STATUS_BADGE[o.status] || 'badge-neutral'}`}>
                      {STATUS_ICON[o.status]} {o.status?.replace('_', ' ')}
                    </span>
                  </td>
                  <td style={{ color: 'var(--text2)', fontSize: 12, whiteSpace: 'nowrap' }}>{fmt(o.created_at)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}
