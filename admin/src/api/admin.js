import client from './client';

// ── Stats ─────────────────────────────────────────────────────────────────────
export const getStats = () => client.get('/api/admin/stats');

// ── Products ──────────────────────────────────────────────────────────────────
export const getProducts = (shop_code) =>
  client.get('/api/admin/products', { params: shop_code ? { shop_code } : {} });

export const createProduct = (data) => client.post('/api/admin/products', data);

export const updateProduct = (code, data) =>
  client.put(`/api/admin/products/${code}`, data);

export const updateStock = (code, stock) =>
  client.patch(`/api/admin/products/${code}/stock`, { stock });

export const deleteProduct = (code) =>
  client.delete(`/api/admin/products/${code}`);

// ── Shops ─────────────────────────────────────────────────────────────────────
export const getShops = () => client.get('/api/admin/shops');

export const createShop = (data) => client.post('/api/admin/shops', data);

export const updateShop = (code, data) =>
  client.put(`/api/admin/shops/${code}`, data);

export const deleteShop = (code) => client.delete(`/api/admin/shops/${code}`);

// ── Users ─────────────────────────────────────────────────────────────────────
export const getUsers = (role) =>
  client.get('/api/admin/users', { params: role ? { role } : {} });

// ── Orders ────────────────────────────────────────────────────────────────────
export const getOrders = (status) =>
  client.get('/api/admin/orders', { params: status ? { status } : {} });
