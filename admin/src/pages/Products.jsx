import { useEffect, useState, useCallback } from 'react';
import { useLocation } from 'react-router-dom';
import {
  getProducts,
  getShops,
  createProduct,
  updateProduct,
  updateStock,
  deleteProduct,
} from '../api/admin';
import { logAdminAction } from '../api/audit';
import { useShop } from '../context/ShopContext';
import Modal from '../components/Modal';

const EMPTY_FORM = {
  shop_code: '',
  code: '',
  name: '',
  subtitle: '',
  image: '',
  price: '',
  rating: '',
  review_count: '',
  description: '',
  stock: '',
};

export default function Products() {
  const location = useLocation();
  const { selectedShopCode, setShop } = useShop();

  const [products, setProducts] = useState([]);
  const [shops, setShops] = useState([]);
  const [filter, setFilter] = useState(selectedShopCode || '');
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(null);
  const [selected, setSelected] = useState(null);
  const [form, setForm] = useState(EMPTY_FORM);
  const [stockVal, setStockVal] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    setFilter(selectedShopCode || '');
  }, [selectedShopCode]);

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const [productRes, shopRes] = await Promise.all([
        getProducts(filter || undefined),
        getShops(),
      ]);
      setProducts(productRes.data);
      setShops(shopRes.data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }, [filter]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const inp = (field) => ({
    value: form[field],
    onChange: (e) => setForm((prev) => ({ ...prev, [field]: e.target.value })),
  });

  const openCreate = () => {
    setForm({ ...EMPTY_FORM, shop_code: filter || '' });
    setError('');
    setModal('create');
  };

  useEffect(() => {
    const params = new URLSearchParams(location.search);
    if (params.get('action') === 'create') {
      openCreate();
    }
    // only respond to URL search changes
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [location.search]);

  const openEdit = (product) => {
    setSelected(product);
    setForm({
      name: product.name,
      subtitle: product.subtitle,
      image: product.image,
      price: String(product.price),
      rating: String(product.rating),
      review_count: String(product.review_count),
      description: product.description,
      stock: String(product.stock),
    });
    setError('');
    setModal('edit');
  };

  const openStock = (product) => {
    setSelected(product);
    setStockVal(String(product.stock));
    setError('');
    setModal('stock');
  };

  const handleCreate = async (e) => {
    e.preventDefault();
    setSaving(true);
    setError('');

    try {
      const payload = {
        ...form,
        price: parseFloat(form.price),
        rating: form.rating ? parseFloat(form.rating) : undefined,
        review_count: form.review_count ? parseInt(form.review_count, 10) : undefined,
        stock: form.stock ? parseInt(form.stock, 10) : undefined,
      };
      const { data } = await createProduct(payload);
      await logAdminAction({
        action: 'product_create',
        entityType: 'product',
        entityId: data.code,
        payload: {
          name: data.name,
          shop_code: data.shop_code,
          price: data.price,
          stock: data.stock,
        },
      });
      setModal(null);
      await loadData();
    } catch (err) {
      setError(err.response?.data?.detail ?? 'Failed to create product');
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
        subtitle: form.subtitle,
        image: form.image,
        price: parseFloat(form.price),
        rating: parseFloat(form.rating),
        review_count: parseInt(form.review_count, 10),
        description: form.description,
        stock: parseInt(form.stock, 10),
      };
      const { data } = await updateProduct(selected.code, payload);
      await logAdminAction({
        action: 'product_update',
        entityType: 'product',
        entityId: selected.code,
        payload: { updated_fields: payload, latest_stock: data.stock },
      });
      setModal(null);
      await loadData();
    } catch (err) {
      setError(err.response?.data?.detail ?? 'Failed to update product');
    } finally {
      setSaving(false);
    }
  };

  const handleStock = async (e) => {
    e.preventDefault();
    setSaving(true);
    setError('');

    try {
      const nextStock = parseInt(stockVal, 10);
      const { data } = await updateStock(selected.code, nextStock);
      await logAdminAction({
        action: 'stock_update',
        entityType: 'product',
        entityId: selected.code,
        payload: { previous_stock: selected.stock, next_stock: data.stock },
      });
      setModal(null);
      await loadData();
    } catch (err) {
      setError(err.response?.data?.detail ?? 'Failed to update stock');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (code) => {
    if (!confirm(`Delete product "${code}"? This cannot be undone.`)) return;

    try {
      await deleteProduct(code);
      await logAdminAction({
        action: 'product_delete',
        entityType: 'product',
        entityId: code,
        payload: {},
      });
      await loadData();
    } catch (err) {
      alert(err.response?.data?.detail ?? 'Delete failed');
    }
  };

  const filteredProducts = products.filter((product) => {
    const q = search.toLowerCase();
    return product.name.toLowerCase().includes(q) || product.code.toLowerCase().includes(q);
  });

  const lowStockCount = filteredProducts.filter((item) => item.stock <= 5).length;

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <h2 className="page-title">Products and Inventory</h2>
          <p className="page-sub">Create products, update stock instantly, and keep inventory healthy per shop.</p>
        </div>
        <button className="btn-primary" onClick={openCreate}>+ Add Product</button>
      </div>

      <div className="filter-bar">
        <input
          className="search-input"
          placeholder="Search by product name or code"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <select
          className="select-input"
          value={filter}
          onChange={(e) => {
            const next = e.target.value;
            setFilter(next);
            setShop(next);
          }}
        >
          <option value="">All shops</option>
          {shops.map((shop) => (
            <option key={shop.code} value={shop.code}>{shop.name}</option>
          ))}
        </select>
        <span className="count-badge">Low stock: {lowStockCount}</span>
      </div>

      <div className="table-card">
        {loading ? (
          <div className="table-loading">Loading products...</div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Product</th>
                <th>Shop</th>
                <th>Price</th>
                <th>Stock</th>
                <th>Rating</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredProducts.length === 0 && (
                <tr><td colSpan={6} className="empty-msg">No products found.</td></tr>
              )}
              {filteredProducts.map((product) => (
                <tr key={product.code}>
                  <td>
                    <div className="cell-name">{product.name}</div>
                    <div className="cell-sub">{product.code}</div>
                  </td>
                  <td>{product.shop_name}</td>
                  <td>Rs {product.price}</td>
                  <td>
                    <span className={`stock-badge ${product.stock < 6 ? 'low' : ''}`}>{product.stock}</span>
                  </td>
                  <td>⭐ {product.rating} ({product.review_count})</td>
                  <td>
                    <div className="action-row">
                      <button className="btn-action" onClick={() => openStock(product)}>Update Stock</button>
                      <button className="btn-action" onClick={() => openEdit(product)}>Edit</button>
                      <button className="btn-action danger" onClick={() => handleDelete(product.code)}>Delete</button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {modal === 'create' && (
        <Modal title="Add New Product" onClose={() => setModal(null)}>
          {error && <div className="alert-error">{error}</div>}
          <form onSubmit={handleCreate} className="modal-form">
            <div className="form-row">
              <div className="form-group">
                <label>Shop *</label>
                <select {...inp('shop_code')} required>
                  <option value="">Select shop</option>
                  {shops.map((s) => <option key={s.code} value={s.code}>{s.name}</option>)}
                </select>
              </div>
              <div className="form-group">
                <label>Product Code *</label>
                <input type="text" placeholder="green_basket_onion" {...inp('code')} required minLength={2} />
              </div>
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Name *</label>
                <input type="text" placeholder="Onion" {...inp('name')} required minLength={2} />
              </div>
              <div className="form-group">
                <label>Subtitle</label>
                <input type="text" placeholder="Vegetable Shop" {...inp('subtitle')} />
              </div>
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Price *</label>
                <input type="number" min="0.01" step="0.01" placeholder="35.00" {...inp('price')} required />
              </div>
              <div className="form-group">
                <label>Stock</label>
                <input type="number" min="0" placeholder="20" {...inp('stock')} />
              </div>
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Rating</label>
                <input type="number" min="0" max="5" step="0.1" placeholder="4.5" {...inp('rating')} />
              </div>
              <div className="form-group">
                <label>Review Count</label>
                <input type="number" min="0" placeholder="0" {...inp('review_count')} />
              </div>
            </div>
            <div className="form-group">
              <label>Image URL / Path</label>
              <input type="text" placeholder="assets/products/Onion.png" {...inp('image')} />
            </div>
            <div className="form-group">
              <label>Description</label>
              <textarea rows={3} placeholder="Fresh onions" {...inp('description')} />
            </div>
            <div className="modal-actions">
              <button type="button" className="btn-outline" onClick={() => setModal(null)}>Cancel</button>
              <button type="submit" className="btn-primary" disabled={saving}>{saving ? 'Saving...' : 'Create Product'}</button>
            </div>
          </form>
        </Modal>
      )}

      {modal === 'edit' && selected && (
        <Modal title={`Edit Product - ${selected.name}`} onClose={() => setModal(null)}>
          {error && <div className="alert-error">{error}</div>}
          <form onSubmit={handleEdit} className="modal-form">
            <div className="form-row">
              <div className="form-group">
                <label>Name</label>
                <input type="text" minLength={2} {...inp('name')} />
              </div>
              <div className="form-group">
                <label>Subtitle</label>
                <input type="text" {...inp('subtitle')} />
              </div>
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Price</label>
                <input type="number" min="0.01" step="0.01" {...inp('price')} />
              </div>
              <div className="form-group">
                <label>Stock</label>
                <input type="number" min="0" {...inp('stock')} />
              </div>
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Rating</label>
                <input type="number" min="0" max="5" step="0.1" {...inp('rating')} />
              </div>
              <div className="form-group">
                <label>Review Count</label>
                <input type="number" min="0" {...inp('review_count')} />
              </div>
            </div>
            <div className="form-group">
              <label>Image URL / Path</label>
              <input type="text" {...inp('image')} />
            </div>
            <div className="form-group">
              <label>Description</label>
              <textarea rows={3} {...inp('description')} />
            </div>
            <div className="modal-actions">
              <button type="button" className="btn-outline" onClick={() => setModal(null)}>Cancel</button>
              <button type="submit" className="btn-primary" disabled={saving}>{saving ? 'Saving...' : 'Save Changes'}</button>
            </div>
          </form>
        </Modal>
      )}

      {modal === 'stock' && selected && (
        <Modal title={`Update Stock - ${selected.name}`} onClose={() => setModal(null)}>
          {error && <div className="alert-error">{error}</div>}
          <form onSubmit={handleStock} className="modal-form">
            <div className="form-group">
              <label>Current stock: <strong>{selected.stock}</strong></label>
              <input
                type="number"
                min="0"
                value={stockVal}
                onChange={(e) => setStockVal(e.target.value)}
                required
                autoFocus
              />
            </div>
            <div className="modal-actions">
              <button type="button" className="btn-outline" onClick={() => setModal(null)}>Cancel</button>
              <button type="submit" className="btn-primary" disabled={saving}>{saving ? 'Updating...' : 'Update Stock'}</button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
