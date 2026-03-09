import { useEffect, useState } from 'react'
import { getStats } from '../api/client'
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend
} from 'recharts'

function StatCard({ icon, label, value, sub, color }) {
  return (
    <div className="stat-card">
      <div className="stat-icon" style={{ background: color + '22', fontSize: 20 }}>{icon}</div>
      <div className="stat-value">{value}</div>
      <div className="stat-label">{label}</div>
      {sub && <div className="stat-sub">{sub}</div>}
    </div>
  )
}

const CHART_COLORS = ['#4f8ef7', '#22c55e', '#f59e0b', '#a855f7', '#ef4444', '#06b6d4']

export default function Dashboard() {
  const [stats, setStats] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    getStats()
      .then(({ data }) => { setStats(data); setLoading(false) })
      .catch(() => { setError('Failed to load stats'); setLoading(false) })
  }, [])

  if (loading) return <div className="page-loader"><div className="spinner" style={{ width: 36, height: 36, borderColor: 'var(--border)', borderTopColor: 'var(--accent)' }} /></div>
  if (error) return <div className="alert alert-danger">{error}</div>

  const barData = [
    { name: 'Total Orders', value: stats.total_orders },
    { name: 'Pending',      value: stats.pending_orders },
    { name: 'Delivered',    value: stats.delivered_orders },
  ]

  const pieData = [
    { name: 'Products', value: stats.total_products },
    { name: 'Shops',    value: stats.total_shops },
    { name: 'Users',    value: stats.total_users },
  ]

  const orderStatusData = [
    { name: 'Pending',   value: stats.pending_orders,   fill: '#f59e0b' },
    { name: 'Delivered', value: stats.delivered_orders, fill: '#22c55e' },
    { name: 'Other',     value: Math.max(0, stats.total_orders - stats.pending_orders - stats.delivered_orders), fill: '#4f8ef7' },
  ]

  return (
    <div>
      {/* Stat Cards */}
      <div className="stats-grid">
        <StatCard icon="📦" label="Total Products"  value={stats.total_products}  color="#4f8ef7" />
        <StatCard icon="🏪" label="Total Shops"     value={stats.total_shops}     color="#a855f7" />
        <StatCard icon="👥" label="Total Users"     value={stats.total_users}     color="#06b6d4" />
        <StatCard icon="🧾" label="Total Orders"    value={stats.total_orders}    color="#f59e0b" />
        <StatCard
          icon="💰"
          label="Total Revenue"
          value={`₹${Number(stats.total_revenue).toLocaleString('en-IN', { maximumFractionDigits: 0 })}`}
          color="#22c55e"
          sub="From delivered orders"
        />
        <StatCard
          icon="⏳"
          label="Pending Orders"
          value={stats.pending_orders}
          color="#ef4444"
          sub={`${stats.delivered_orders} delivered`}
        />
      </div>

      {/* Charts */}
      <div className="charts-grid">
        <div className="card">
          <div className="card-title">Orders Overview</div>
          <ResponsiveContainer width="100%" height={240}>
            <BarChart data={barData} barSize={44}>
              <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
              <XAxis dataKey="name" tick={{ fill: 'var(--text2)', fontSize: 12 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: 'var(--text2)', fontSize: 12 }} axisLine={false} tickLine={false} />
              <Tooltip
                contentStyle={{ background: 'var(--bg3)', border: '1px solid var(--border)', borderRadius: 8, fontSize: 13 }}
                cursor={{ fill: 'rgba(255,255,255,0.03)' }}
              />
              <Bar dataKey="value" radius={[6, 6, 0, 0]}>
                {barData.map((_, i) => (
                  <Cell key={i} fill={CHART_COLORS[i]} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className="card">
          <div className="card-title">Platform Distribution</div>
          <ResponsiveContainer width="100%" height={240}>
            <PieChart>
              <Pie
                data={pieData}
                cx="50%"
                cy="50%"
                innerRadius={60}
                outerRadius={90}
                paddingAngle={4}
                dataKey="value"
              >
                {pieData.map((_, i) => (
                  <Cell key={i} fill={CHART_COLORS[i]} />
                ))}
              </Pie>
              <Legend
                iconType="circle"
                formatter={(value) => <span style={{ color: 'var(--text2)', fontSize: 12 }}>{value}</span>}
              />
              <Tooltip
                contentStyle={{ background: 'var(--bg3)', border: '1px solid var(--border)', borderRadius: 8, fontSize: 13 }}
              />
            </PieChart>
          </ResponsiveContainer>
        </div>

        <div className="card" style={{ gridColumn: '1 / -1' }}>
          <div className="card-title">Order Status Breakdown</div>
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={orderStatusData} layout="vertical" barSize={28}>
              <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" horizontal={false} />
              <XAxis type="number" tick={{ fill: 'var(--text2)', fontSize: 12 }} axisLine={false} tickLine={false} />
              <YAxis type="category" dataKey="name" tick={{ fill: 'var(--text2)', fontSize: 12 }} axisLine={false} tickLine={false} width={70} />
              <Tooltip
                contentStyle={{ background: 'var(--bg3)', border: '1px solid var(--border)', borderRadius: 8, fontSize: 13 }}
                cursor={{ fill: 'rgba(255,255,255,0.03)' }}
              />
              <Bar dataKey="value" radius={[0, 6, 6, 0]}>
                {orderStatusData.map((item, i) => (
                  <Cell key={i} fill={item.fill} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  )
}
