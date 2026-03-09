export default function StatCard({ title, value, subtitle, color = '#f5c518', icon }) {
  return (
    <div className="stat-card">
      <div className="stat-icon" style={{ background: color + '20', color }}>
        {icon}
      </div>
      <div className="stat-body">
        <p className="stat-title">{title}</p>
        <p className="stat-value">{value ?? '—'}</p>
        {subtitle && <p className="stat-sub">{subtitle}</p>}
      </div>
    </div>
  );
}
