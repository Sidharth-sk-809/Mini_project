import { useEffect, useState, useCallback } from 'react';
import { getOrders } from '../api/admin';
import { useShop } from '../context/ShopContext';

const STATUS_META = {
  placed: { bg: '#dbeafe', text: '#1d4ed8', label: 'Placed' },
  confirmed: { bg: '#cffafe', text: '#0e7490', label: 'Confirmed' },
  packed: { bg: '#ffedd5', text: '#c2410c', label: 'Packed' },
  picked_up: { bg: '#ede9fe', text: '#6d28d9', label: 'Picked Up' },
  delivered: { bg: '#dcfce7', text: '#15803d', label: 'Delivered' },
  cancelled: { bg: '#fee2e2', text: '#b91c1c', label: 'Cancelled' },
};

const STATUSES = ['', 'placed', 'confirmed', 'packed', 'picked_up', 'delivered', 'cancelled'];

export default function Orders() {
  const { selectedShopCode } = useShop();

  const [orders, setOrders] = useState([]);
  const [filter, setFilter] = useState('');
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [live, setLive] = useState(true);
  const [lastUpdated, setLastUpdated] = useState(null);

  const loadOrders = useCallback(async () => {
    const { data } = await getOrders();
    setOrders(data);
    setLastUpdated(new Date());
  }, []);

  useEffect(() => {
    setLoading(true);
    loadOrders()
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [loadOrders]);

  useEffect(() => {
    if (!live) return undefined;

    const timer = setInterval(() => {
      loadOrders().catch(console.error);
    }, 6000);

    return () => clearInterval(timer);
  }, [live, loadOrders]);

  const filtered = orders.filter((order) => {
    const q = search.toLowerCase();
    const matchesStatus = !filter || order.status === filter;
    return matchesStatus && (
      order.order_code.toLowerCase().includes(q) ||
      String(order.customer_user_id).includes(q)
    );
  });

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <h2 className="page-title">Realtime Customer Orders</h2>
          <p className="page-sub">
            Auto-refresh every 6 seconds for live intake. {selectedShopCode ? `Workspace: ${selectedShopCode}.` : ''}
          </p>
        </div>
        <div className="live-actions">
          <span className="count-badge">{filtered.length} orders</span>
          <button className="btn-outline" onClick={() => setLive((prev) => !prev)}>{live ? 'Pause Live' : 'Resume Live'}</button>
          <button className="btn-primary" onClick={() => loadOrders().catch(console.error)}>Refresh</button>
        </div>
      </div>

      <p className="live-indicator">Last updated: {lastUpdated ? lastUpdated.toLocaleTimeString('en-IN') : '-'}</p>

      <div className="filter-bar">
        <input
          className="search-input"
          placeholder="Search by order code or customer ID"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <div className="status-tabs">
          {STATUSES.map((status) => (
            <button
              key={status}
              className={`role-tab ${filter === status ? 'active' : ''}`}
              style={
                filter === status && status
                  ? {
                      background: STATUS_META[status].bg,
                      color: STATUS_META[status].text,
                      borderColor: STATUS_META[status].text,
                    }
                  : {}
              }
              onClick={() => setFilter(status)}
            >
              {status === '' ? 'All' : STATUS_META[status].label}
            </button>
          ))}
        </div>
      </div>

      <div className="table-card">
        {loading ? (
          <div className="table-loading">Loading orders...</div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Order Code</th>
                <th>Customer</th>
                <th>Items</th>
                <th>Total</th>
                <th>Status</th>
                <th>Placed At</th>
                <th>Address</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 && (
                <tr><td colSpan={7} className="empty-msg">No orders found.</td></tr>
              )}
              {filtered.map((order) => {
                const meta = STATUS_META[order.status] ?? { bg: '#f3f4f6', text: '#4b5563', label: order.status };

                return (
                  <tr key={order.id}>
                    <td className="font-mono">{order.order_code}</td>
                    <td>#{order.customer_user_id}</td>
                    <td>{order.total_items}</td>
                    <td>Rs {order.grand_total?.toFixed(2)}</td>
                    <td>
                      <span className="badge" style={{ background: meta.bg, color: meta.text }}>
                        {meta.label}
                      </span>
                    </td>
                    <td>{new Date(order.created_at).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' })}</td>
                    <td className="address-cell">{order.delivery_address}</td>
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
