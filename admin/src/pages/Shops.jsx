import { useEffect, useState, useCallback } from 'react';
import { getShops, createShop, updateShop, deleteShop } from '../api/admin';
import { logAdminAction } from '../api/audit';
import Modal from '../components/Modal';

const EMPTY_FORM = {
  code: '', name: '', shop_type: '', distance_km: '', delivery_available: 'true',
};

export default function Shops() {
  const [shops, setShops] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(null);
  const [selected, setSelected] = useState(null);
  const [form, setForm] = useState(EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const loadShops = useCallback(async () => {
    setLoading(true);
    try {
      const { data } = await getShops();
      setShops(data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { loadShops(); }, [loadShops]);

  const openCreate = () => {
    setForm(EMPTY_FORM);
    setError('');
    setModal('create');
  };

  const openEdit = (s) => {
    setSelected(s);
    setForm({
      name: s.name,
      shop_type: s.shop_type,
      distance_km: String(s.distance_km),
      delivery_available: String(s.delivery_available),
    });
    setError('');
    setModal('edit');
  };

  const inp = (field) => ({
    value: form[field],
    onChange: (e) => setForm((f) => ({ ...f, [field]: e.target.value })),
  });

  const handleCreate = async (e) => {
    e.preventDefault();
    setSaving(true);
    setError('');
    try {
      const payload = {
        code: form.code,
        name: form.name,
        shop_type: form.shop_type,
        distance_km: form.distance_km ? parseInt(form.distance_km) : undefined,
        delivery_available: form.delivery_available === 'true',
      };
      const { data } = await createShop(payload);
      await logAdminAction({
        action: 'shop_create',
        entityType: 'shop',
        entityId: data.code,
        payload,
      });
      setModal(null);
      loadShops();
    } catch (err) {
      setError(err.response?.data?.detail ?? 'Failed to create shop');
    } finally {
      setSaving(false);
    }
  };

  const handleEdit = async (e) => {
    e.preventDefault();
    setSaving(true);
    setError('');
    try {
      const payload = {
        name: form.name,
        shop_type: form.shop_type,
        distance_km: form.distance_km ? parseInt(form.distance_km) : undefined,
        delivery_available: form.delivery_available === 'true',
      };
      await updateShop(selected.code, payload);
      await logAdminAction({
        action: 'shop_update',
        entityType: 'shop',
        entityId: selected.code,
        payload,
      });
      setModal(null);
      loadShops();
    } catch (err) {
      setError(err.response?.data?.detail ?? 'Failed to update shop');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (code) => {
    if (!confirm(`Delete shop "${code}"? All its products must be removed first.`)) return;
    try {
      await deleteShop(code);
      await logAdminAction({
        action: 'shop_delete',
        entityType: 'shop',
        entityId: code,
        payload: {},
      });
      loadShops();
    } catch (err) {
      alert(err.response?.data?.detail ?? 'Delete failed');
    }
  };

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <h2 className="page-title">Shops</h2>
          <p className="page-sub">Manage all shops on the platform.</p>
        </div>
        <button className="btn-primary" onClick={openCreate}>+ Add Shop</button>
      </div>

      {loading ? (
        <div className="loading-grid">
          {Array.from({ length: 4 }).map((_, i) => <div key={i} className="skeleton-card" />)}
        </div>
      ) : (
        <div className="shop-grid">
          {shops.length === 0 && <p className="empty-msg">No shops found.</p>}
          {shops.map((s) => (
            <div key={s.code} className="shop-card">
              <div className="shop-card-top">
                <div className="shop-avatar">{s.name.charAt(0)}</div>
                <div>
                  <p className="shop-name">{s.name}</p>
                  <p className="shop-code-text">{s.code}</p>
                </div>
              </div>
              <div className="shop-meta">
                <span className="shop-type-badge">{s.shop_type || 'General'}</span>
                <span className={`delivery-badge ${s.delivery_available ? 'green' : 'red'}`}>
                  {s.delivery_available ? '🚚 Delivery' : '❌ No Delivery'}
                </span>
              </div>
              <div className="shop-stats-row">
                <div className="shop-stat">
                  <p className="shop-stat-val">{s.product_count}</p>
                  <p className="shop-stat-label">Products</p>
                </div>
                <div className="shop-stat">
                  <p className="shop-stat-val">{s.distance_km} km</p>
                  <p className="shop-stat-label">Distance</p>
                </div>
              </div>
              <div className="action-row">
                <button className="btn-outline w-full" onClick={() => openEdit(s)}>Edit</button>
                <button className="btn-action danger" onClick={() => handleDelete(s.code)}>Delete</button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Create Modal */}
      {modal === 'create' && (
        <Modal title="Add New Shop" onClose={() => setModal(null)}>
          {error && <div className="alert-error">{error}</div>}
          <form onSubmit={handleCreate} className="modal-form">
            <div className="form-row">
              <div className="form-group">
                <label>Shop Code *</label>
                <input type="text" placeholder="fresh_dairy" {...inp('code')} required minLength={2} />
              </div>
              <div className="form-group">
                <label>Shop Name *</label>
                <input type="text" placeholder="Fresh Dairy" {...inp('name')} required minLength={2} />
              </div>
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Shop Type</label>
                <input type="text" placeholder="Dairy Shop" {...inp('shop_type')} />
              </div>
              <div className="form-group">
                <label>Distance (km)</label>
                <input type="number" min="0" placeholder="3" {...inp('distance_km')} />
              </div>
            </div>
            <div className="form-group">
              <label>Delivery Available</label>
              <select {...inp('delivery_available')}>
                <option value="true">Yes</option>
                <option value="false">No</option>
              </select>
            </div>
            <div className="modal-actions">
              <button type="button" className="btn-outline" onClick={() => setModal(null)}>Cancel</button>
              <button type="submit" className="btn-primary" disabled={saving}>{saving ? 'Saving…' : 'Create Shop'}</button>
            </div>
          </form>
        </Modal>
      )}

      {/* Edit Modal */}
      {modal === 'edit' && selected && (
        <Modal title={`Edit — ${selected.name}`} onClose={() => setModal(null)}>
          {error && <div className="alert-error">{error}</div>}
          <form onSubmit={handleEdit} className="modal-form">
            <div className="form-row">
              <div className="form-group">
                <label>Shop Name</label>
                <input type="text" {...inp('name')} minLength={2} />
              </div>
              <div className="form-group">
                <label>Shop Type</label>
                <input type="text" {...inp('shop_type')} />
              </div>
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Distance (km)</label>
                <input type="number" min="0" {...inp('distance_km')} />
              </div>
              <div className="form-group">
                <label>Delivery Available</label>
                <select {...inp('delivery_available')}>
                  <option value="true">Yes</option>
                  <option value="false">No</option>
                </select>
              </div>
            </div>
            <div className="modal-actions">
              <button type="button" className="btn-outline" onClick={() => setModal(null)}>Cancel</button>
              <button type="submit" className="btn-primary" disabled={saving}>{saving ? 'Saving…' : 'Save Changes'}</button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
