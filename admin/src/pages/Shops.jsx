import { useEffect, useState } from 'react'
import Modal from '../components/Modal'
import { getShops, createShop, updateShop, deleteShop } from '../api/client'

const EMPTY_FORM = {
  code: '', name: '', shop_type: '', distance_km: 5, delivery_available: true,
}

export default function Shops() {
  const [shops, setShops] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const [showCreate, setShowCreate] = useState(false)
  const [editItem, setEditItem] = useState(null)
  const [deleteItem, setDeleteItem] = useState(null)

  const [form, setForm] = useState(EMPTY_FORM)
  const [saving, setSaving] = useState(false)
  const [formError, setFormError] = useState(null)

  const load = () => {
    setLoading(true)
    getShops()
      .then(({ data }) => { setShops(data); setLoading(false) })
      .catch(() => { setError('Failed to load shops'); setLoading(false) })
  }

  useEffect(() => { load() }, [])

  const setF = (k, v) => setForm((f) => ({ ...f, [k]: v }))

  const openCreate = () => { setForm(EMPTY_FORM); setFormError(null); setShowCreate(true) }
  const openEdit = (s) => { setForm({ ...s }); setFormError(null); setEditItem(s) }

  const handleCreate = async (e) => {
    e.preventDefault(); setSaving(true); setFormError(null)
    try {
      await createShop({ ...form, distance_km: parseInt(form.distance_km) })
      setShowCreate(false); load()
    } catch (err) {
      setFormError(err.response?.data?.detail || 'Failed to create shop')
    } finally { setSaving(false) }
  }

  const handleEdit = async (e) => {
    e.preventDefault(); setSaving(true); setFormError(null)
    try {
      await updateShop(editItem.code, {
        name: form.name, shop_type: form.shop_type,
        distance_km: parseInt(form.distance_km),
        delivery_available: form.delivery_available,
      })
      setEditItem(null); load()
    } catch (err) {
      setFormError(err.response?.data?.detail || 'Failed to update shop')
    } finally { setSaving(false) }
  }

  const handleDelete = async () => {
    setSaving(true)
    try {
      await deleteShop(deleteItem.code)
      setDeleteItem(null); load()
    } catch (err) {
      alert(err.response?.data?.detail || 'Failed to delete shop')
      setSaving(false)
    }
  }

  return (
    <div>
      <div className="table-wrapper">
        <div className="table-header">
          <div className="table-title">Shops ({shops.length})</div>
          <div className="table-actions">
            <button className="btn btn-primary" onClick={openCreate}>+ Add Shop</button>
          </div>
        </div>

        {loading ? (
          <div className="page-loader"><div className="spinner" style={{ width: 32, height: 32, borderColor: 'var(--border)', borderTopColor: 'var(--accent)' }} /></div>
        ) : error ? (
          <div className="alert alert-danger" style={{ margin: 20 }}>{error}</div>
        ) : shops.length === 0 ? (
          <div className="empty-state"><div className="empty-icon">🏪</div><p>No shops found</p></div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Shop Name</th>
                <th>Code</th>
                <th>Type</th>
                <th>Distance</th>
                <th>Delivery</th>
                <th>Products</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {shops.map((s) => (
                <tr key={s.id}>
                  <td style={{ fontWeight: 600 }}>{s.name}</td>
                  <td><span className="td-code">{s.code}</span></td>
                  <td><span className="badge badge-info">{s.shop_type || '—'}</span></td>
                  <td>{s.distance_km} km</td>
                  <td>
                    <span className={`badge ${s.delivery_available ? 'badge-success' : 'badge-danger'}`}>
                      {s.delivery_available ? '✓ Available' : '✗ Unavailable'}
                    </span>
                  </td>
                  <td>
                    <span className="badge badge-neutral">{s.product_count} items</span>
                  </td>
                  <td>
                    <div style={{ display: 'flex', gap: 6 }}>
                      <button className="btn btn-ghost btn-sm" onClick={() => openEdit(s)}>✏️ Edit</button>
                      <button className="btn btn-danger btn-sm" onClick={() => setDeleteItem(s)}>🗑️</button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* CREATE */}
      {showCreate && (
        <Modal title="Add New Shop" onClose={() => setShowCreate(false)}>
          <ShopForm
            form={form} setF={setF} error={formError} saving={saving}
            onSubmit={handleCreate} onCancel={() => setShowCreate(false)} showCode
          />
        </Modal>
      )}

      {/* EDIT */}
      {editItem && (
        <Modal title={`Edit: ${editItem.name}`} onClose={() => setEditItem(null)}>
          <ShopForm
            form={form} setF={setF} error={formError} saving={saving}
            onSubmit={handleEdit} onCancel={() => setEditItem(null)}
          />
        </Modal>
      )}

      {/* DELETE CONFIRM */}
      {deleteItem && (
        <Modal
          title="Delete Shop"
          onClose={() => setDeleteItem(null)}
          footer={
            <>
              <button className="btn btn-ghost" onClick={() => setDeleteItem(null)}>Cancel</button>
              <button className="btn btn-danger" onClick={handleDelete} disabled={saving}>
                {saving ? <span className="spinner" /> : null} Delete
              </button>
            </>
          }
        >
          <div className="confirm-icon">⚠️</div>
          <p className="confirm-msg">Are you sure you want to delete</p>
          <p className="confirm-code">{deleteItem.name}</p>
          <p className="confirm-msg" style={{ marginTop: 8 }}>
            Note: Shops with products cannot be deleted. Remove all products first.
          </p>
        </Modal>
      )}
    </div>
  )
}

function ShopForm({ form, setF, error, saving, onSubmit, onCancel, showCode }) {
  return (
    <form onSubmit={onSubmit}>
      {error && <div className="alert alert-danger">{error}</div>}
      <div className="form-grid">
        {showCode && (
          <div className="form-group form-full">
            <label className="form-label">Shop Code *</label>
            <input className="form-input" placeholder="e.g. green_basket" value={form.code} onChange={(e) => setF('code', e.target.value)} required minLength={2} />
          </div>
        )}
        <div className="form-group">
          <label className="form-label">Shop Name *</label>
          <input className="form-input" placeholder="Green Basket" value={form.name} onChange={(e) => setF('name', e.target.value)} required minLength={2} />
        </div>
        <div className="form-group">
          <label className="form-label">Shop Type</label>
          <input className="form-input" placeholder="Vegetable Shop" value={form.shop_type} onChange={(e) => setF('shop_type', e.target.value)} />
        </div>
        <div className="form-group">
          <label className="form-label">Distance (km)</label>
          <input className="form-input" type="number" min="0" value={form.distance_km} onChange={(e) => setF('distance_km', e.target.value)} />
        </div>
        <div className="form-group" style={{ justifyContent: 'flex-end', paddingTop: 8 }}>
          <label className="checkbox-label">
            <input type="checkbox" checked={form.delivery_available} onChange={(e) => setF('delivery_available', e.target.checked)} />
            Delivery Available
          </label>
        </div>
      </div>
      <div className="modal-footer" style={{ marginTop: 20 }}>
        <button type="button" className="btn btn-ghost" onClick={onCancel}>Cancel</button>
        <button type="submit" className="btn btn-primary" disabled={saving}>
          {saving ? <span className="spinner" /> : null} Save
        </button>
      </div>
    </form>
  )
}
