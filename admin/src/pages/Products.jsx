import { useEffect, useState, useRef } from 'react'
import Modal from '../components/Modal'
import {
  getProducts, getShops, createProduct, updateProduct,
  updateProductStock, deleteProduct,
} from '../api/client'

const EMPTY_FORM = {
  shop_code: '', code: '', name: '', subtitle: '',
  image: '', price: '', rating: 4.5, review_count: 0,
  description: '', stock: 10,
}

export default function Products() {
  const [products, setProducts] = useState([])
  const [shops, setShops] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [search, setSearch] = useState('')
  const [filterShop, setFilterShop] = useState('')

  // Modals
  const [showCreate, setShowCreate] = useState(false)
  const [editItem, setEditItem] = useState(null)
  const [stockItem, setStockItem] = useState(null)
  const [deleteItem, setDeleteItem] = useState(null)

  const [form, setForm] = useState(EMPTY_FORM)
  const [stockVal, setStockVal] = useState('')
  const [saving, setSaving] = useState(false)
  const [formError, setFormError] = useState(null)

  const load = (shopCode = filterShop) => {
    setLoading(true)
    Promise.all([getProducts(shopCode || undefined), getShops()])
      .then(([p, s]) => { setProducts(p.data); setShops(s.data); setLoading(false) })
      .catch(() => { setError('Failed to load products'); setLoading(false) })
  }

  useEffect(() => { load() }, [])

  const openCreate = () => { setForm(EMPTY_FORM); setFormError(null); setShowCreate(true) }
  const openEdit = (p) => { setForm({ ...p, price: p.price.toString(), rating: p.rating, review_count: p.review_count, stock: p.stock }); setFormError(null); setEditItem(p) }
  const openStock = (p) => { setStockVal(p.stock.toString()); setStockItem(p) }

  const setF = (k, v) => setForm((f) => ({ ...f, [k]: v }))

  const handleCreate = async (e) => {
    e.preventDefault(); setSaving(true); setFormError(null)
    try {
      await createProduct({ ...form, price: parseFloat(form.price), rating: parseFloat(form.rating), review_count: parseInt(form.review_count), stock: parseInt(form.stock) })
      setShowCreate(false); load()
    } catch (err) {
      setFormError(err.response?.data?.detail || 'Failed to create product')
    } finally { setSaving(false) }
  }

  const handleEdit = async (e) => {
    e.preventDefault(); setSaving(true); setFormError(null)
    try {
      await updateProduct(editItem.code, {
        name: form.name, subtitle: form.subtitle, image: form.image,
        price: parseFloat(form.price), rating: parseFloat(form.rating),
        review_count: parseInt(form.review_count), description: form.description,
        stock: parseInt(form.stock),
      })
      setEditItem(null); load()
    } catch (err) {
      setFormError(err.response?.data?.detail || 'Failed to update product')
    } finally { setSaving(false) }
  }

  const handleStock = async (e) => {
    e.preventDefault(); setSaving(true)
    try {
      await updateProductStock(stockItem.code, parseInt(stockVal))
      setStockItem(null); load()
    } catch (err) {
      alert(err.response?.data?.detail || 'Failed to update stock')
    } finally { setSaving(false) }
  }

  const handleDelete = async () => {
    setSaving(true)
    try {
      await deleteProduct(deleteItem.code)
      setDeleteItem(null); load()
    } catch (err) {
      alert(err.response?.data?.detail || 'Failed to delete product')
    } finally { setSaving(false) }
  }

  const filtered = products.filter((p) =>
    p.name.toLowerCase().includes(search.toLowerCase()) ||
    p.code.toLowerCase().includes(search.toLowerCase()) ||
    p.shop_name?.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div>
      <div className="table-wrapper">
        <div className="table-header">
          <div className="table-title">Products ({filtered.length})</div>
          <div className="table-actions">
            <div className="search-input-wrap">
              <span className="search-icon">🔍</span>
              <input className="search-input" placeholder="Search products…" value={search} onChange={(e) => setSearch(e.target.value)} />
            </div>
            <select
              className="form-input"
              style={{ width: 160, padding: '7px 12px' }}
              value={filterShop}
              onChange={(e) => { setFilterShop(e.target.value); load(e.target.value) }}
            >
              <option value="">All Shops</option>
              {shops.map((s) => <option key={s.code} value={s.code}>{s.name}</option>)}
            </select>
            <button className="btn btn-primary" onClick={openCreate}>+ Add Product</button>
          </div>
        </div>

        {loading ? (
          <div className="page-loader"><div className="spinner" style={{ width: 32, height: 32, borderColor: 'var(--border)', borderTopColor: 'var(--accent)' }} /></div>
        ) : error ? (
          <div className="alert alert-danger" style={{ margin: 20 }}>{error}</div>
        ) : filtered.length === 0 ? (
          <div className="empty-state"><div className="empty-icon">📦</div><p>No products found</p></div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Code</th>
                <th>Shop</th>
                <th>Price</th>
                <th>Stock</th>
                <th>Rating</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((p) => (
                <tr key={p.id}>
                  <td>
                    <div style={{ fontWeight: 600 }}>{p.name}</div>
                    <div style={{ fontSize: 12, color: 'var(--text3)' }}>{p.subtitle}</div>
                  </td>
                  <td><span className="td-code">{p.code}</span></td>
                  <td><span className="badge badge-info">{p.shop_name}</span></td>
                  <td style={{ fontWeight: 600 }}>₹{p.price}</td>
                  <td>
                    <span className={`badge ${p.stock === 0 ? 'badge-danger' : p.stock < 5 ? 'badge-warning' : 'badge-success'}`}>
                      {p.stock} units
                    </span>
                  </td>
                  <td>⭐ {p.rating} <span style={{ color: 'var(--text3)', fontSize: 12 }}>({p.review_count})</span></td>
                  <td>
                    <div style={{ display: 'flex', gap: 6 }}>
                      <button className="btn btn-ghost btn-sm" onClick={() => openEdit(p)}>✏️ Edit</button>
                      <button className="btn btn-ghost btn-sm" onClick={() => openStock(p)}>📦 Stock</button>
                      <button className="btn btn-danger btn-sm" onClick={() => setDeleteItem(p)}>🗑️</button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* CREATE MODAL */}
      {showCreate && (
        <Modal title="Add New Product" onClose={() => setShowCreate(false)}>
          <ProductForm
            form={form} setF={setF} shops={shops}
            error={formError} saving={saving}
            onSubmit={handleCreate} onCancel={() => setShowCreate(false)}
            showShopSelect
          />
        </Modal>
      )}

      {/* EDIT MODAL */}
      {editItem && (
        <Modal title={`Edit: ${editItem.name}`} onClose={() => setEditItem(null)}>
          <ProductForm
            form={form} setF={setF} shops={shops}
            error={formError} saving={saving}
            onSubmit={handleEdit} onCancel={() => setEditItem(null)}
          />
        </Modal>
      )}

      {/* STOCK MODAL */}
      {stockItem && (
        <Modal
          title={`Update Stock: ${stockItem.name}`}
          onClose={() => setStockItem(null)}
          footer={
            <>
              <button className="btn btn-ghost" onClick={() => setStockItem(null)}>Cancel</button>
              <button className="btn btn-primary" onClick={handleStock} disabled={saving}>
                {saving ? <span className="spinner" /> : null} Update
              </button>
            </>
          }
        >
          <div className="form-group">
            <label className="form-label">New Stock Quantity</label>
            <input className="form-input" type="number" min="0" value={stockVal} onChange={(e) => setStockVal(e.target.value)} autoFocus />
          </div>
          <p style={{ marginTop: 8, fontSize: 12, color: 'var(--text3)' }}>Current stock: {stockItem.stock} units</p>
        </Modal>
      )}

      {/* DELETE CONFIRM */}
      {deleteItem && (
        <Modal
          title="Delete Product"
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
          <p className="confirm-msg" style={{ marginTop: 8 }}>This action cannot be undone.</p>
        </Modal>
      )}
    </div>
  )
}

function ProductForm({ form, setF, shops, error, saving, onSubmit, onCancel, showShopSelect }) {
  return (
    <form onSubmit={onSubmit}>
      {error && <div className="alert alert-danger">{error}</div>}
      <div className="form-grid">
        {showShopSelect && (
          <div className="form-group form-full">
            <label className="form-label">Shop *</label>
            <select className="form-input" value={form.shop_code} onChange={(e) => setF('shop_code', e.target.value)} required>
              <option value="">Select shop…</option>
              {shops.map((s) => <option key={s.code} value={s.code}>{s.name}</option>)}
            </select>
          </div>
        )}
        {showShopSelect && (
          <div className="form-group form-full">
            <label className="form-label">Product Code *</label>
            <input className="form-input" placeholder="e.g. green_basket_tomato" value={form.code} onChange={(e) => setF('code', e.target.value)} required minLength={2} />
          </div>
        )}
        <div className="form-group">
          <label className="form-label">Name *</label>
          <input className="form-input" placeholder="Product name" value={form.name} onChange={(e) => setF('name', e.target.value)} required minLength={2} />
        </div>
        <div className="form-group">
          <label className="form-label">Subtitle</label>
          <input className="form-input" placeholder="Short description" value={form.subtitle} onChange={(e) => setF('subtitle', e.target.value)} />
        </div>
        <div className="form-group">
          <label className="form-label">Price (₹) *</label>
          <input className="form-input" type="number" min="0.01" step="0.01" placeholder="0.00" value={form.price} onChange={(e) => setF('price', e.target.value)} required />
        </div>
        <div className="form-group">
          <label className="form-label">Stock</label>
          <input className="form-input" type="number" min="0" value={form.stock} onChange={(e) => setF('stock', e.target.value)} />
        </div>
        <div className="form-group">
          <label className="form-label">Rating (0–5)</label>
          <input className="form-input" type="number" min="0" max="5" step="0.1" value={form.rating} onChange={(e) => setF('rating', e.target.value)} />
        </div>
        <div className="form-group">
          <label className="form-label">Review Count</label>
          <input className="form-input" type="number" min="0" value={form.review_count} onChange={(e) => setF('review_count', e.target.value)} />
        </div>
        <div className="form-group form-full">
          <label className="form-label">Image Path</label>
          <input className="form-input" placeholder="assets/products/Image.png" value={form.image} onChange={(e) => setF('image', e.target.value)} />
        </div>
        <div className="form-group form-full">
          <label className="form-label">Description</label>
          <textarea className="form-input" rows={3} placeholder="Product description…" value={form.description} onChange={(e) => setF('description', e.target.value)} style={{ resize: 'vertical' }} />
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
