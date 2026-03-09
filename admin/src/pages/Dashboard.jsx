import { useEffect, useState, useCallback } from 'react';
import { Link } from 'react-router-dom';
import { getStats, getOrders, getProducts } from '../api/admin';
import { useShop } from '../context/ShopContext';
import StatCard from '../components/StatCard';

const STATUS_COLORS = {
  placed: '#2563eb',
  confirmed: '#0891b2',
  packed: '#ea580c',
  picked_up: '#7c3aed',
  delivered: '#16a34a',
  cancelled: '#dc2626',
};

export default function Dashboard() {
  const { selectedShopCode } = useShop();

  const [stats, setStats] = useState(null);
  const [products, setProducts] = useState([]);
  const [recentOrders, setRecentOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [lastSync, setLastSync] = useState(null);

  const loadDashboard = useCallback(async () => {
    const [statsRes, ordersRes, productsRes] = await Promise.all([
      getStats(),
      getOrders(),
      getProducts(selectedShopCode || undefined),
    ]);

    setStats(statsRes.data);
    setProducts(productsRes.data);
    setRecentOrders(ordersRes.data.slice(0, 6));
    setLastSync(new Date());
  }, [selectedShopCode]);

  useEffect(() => {
    loadDashboard()
      .catch(console.error)
      .finally(() => setLoading(false));

    const timer = setInterval(() => {
      loadDashboard().catch(console.error);
    }, 10000);

    return () => clearInterval(timer);
  }, [loadDashboard]);

  const inventoryUnits = products.reduce((sum, p) => sum + (p.stock ?? 0), 0);
  const lowStockItems = products.filter((p) => (p.stock ?? 0) <= 5).length;

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <h2 className="page-title">Shop Operations Dashboard</h2>
          <p className="page-sub">
            {selectedShopCode
              ? `Focused on ${selectedShopCode} workspace for product and stock operations.`
              : 'Track platform health, stock, and live order intake across all shops.'}
          </p>
        </div>
        <p className="live-indicator">Live sync: {lastSync ? lastSync.toLocaleTimeString('en-IN') : 'starting...'}</p>
      </div>

      {loading ? (
        <div className="loading-grid">
          {Array.from({ length: 6 }).map((_, idx) => <div className="skeleton-card" key={idx} />)}
        </div>
      ) : (
        <div className="stats-grid">
          <StatCard title="Total Orders" value={stats?.total_orders?.toLocaleString('en-IN')} icon="🧾" color="#2563eb" />
          <StatCard title="Pending Orders" value={stats?.pending_orders?.toLocaleString('en-IN')} icon="⏳" color="#ea580c" />
          <StatCard title="Delivered Orders" value={stats?.delivered_orders?.toLocaleString('en-IN')} icon="✅" color="#16a34a" />
          <StatCard title="Products in Scope" value={products.length.toLocaleString('en-IN')} icon="📦" color="#9333ea" />
          <StatCard title="Stock Units" value={inventoryUnits.toLocaleString('en-IN')} icon="🏷️" color="#0891b2" />
          <StatCard title="Low Stock Items" value={lowStockItems.toLocaleString('en-IN')} icon="⚠️" color="#dc2626" />
        </div>
      )}

      <div className="dash-row single-row">
        <div className="dash-orders-card">
          <div className="card-title-row">
            <h3 className="card-title">Recent Customer Orders (Realtime Feed)</h3>
            <Link to="/orders" className="see-all">Open live board</Link>
          </div>
          <div className="order-list">
            {recentOrders.length === 0 && !loading && <p className="empty-msg">No orders yet.</p>}
            {recentOrders.map((o) => (
              <div key={o.id} className="order-row">
                <div>
                  <p className="order-code">{o.order_code}</p>
                  <p className="order-meta">
                    {o.total_items} items · Rs {o.grand_total?.toFixed(2)}
                  </p>
                </div>
                <span
                  className="badge"
                  style={{
                    background: `${STATUS_COLORS[o.status] ?? '#6b7280'}1a`,
                    color: STATUS_COLORS[o.status] ?? '#6b7280',
                  }}
                >
                  {o.status}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="dash-row single-row">
        <div className="dash-orders-card">
          <div className="card-title-row">
            <h3 className="card-title">Product Management</h3>
            <div className="live-actions">
              <Link to="/products?action=create" className="btn-primary">Add New Product</Link>
              <Link to="/products" className="btn-outline">View All Products</Link>
            </div>
          </div>
          <div className="table-card">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Product</th>
                  <th>Shop</th>
                  <th>Price</th>
                  <th>Stock</th>
                </tr>
              </thead>
              <tbody>
                {products.length === 0 && (
                  <tr><td colSpan={4} className="empty-msg">No products available.</td></tr>
                )}
                {products.slice(0, 8).map((p) => (
                  <tr key={p.code}>
                    <td>
                      <div className="cell-name">{p.name}</div>
                      <div className="cell-sub">{p.code}</div>
                    </td>
                    <td>{p.shop_name}</td>
                    <td>Rs {p.price}</td>
                    <td>
                      <span className={`stock-badge ${p.stock < 6 ? 'low' : ''}`}>{p.stock}</span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
