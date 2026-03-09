import axios from 'axios'

const BASE_URL = 'https://mini-project-8sdo.onrender.com'

const api = axios.create({
  baseURL: BASE_URL,
  timeout: 15000,
})

// Attach JWT token to every request
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('admin_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Auto-logout on 401/403
api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401 || err.response?.status === 403) {
      localStorage.removeItem('admin_token')
      localStorage.removeItem('admin_user')
      window.dispatchEvent(new Event('auth:logout'))
    }
    return Promise.reject(err)
  }
)

// ─── Auth ────────────────────────────────────────────────
export const loginAdmin = (email, password) =>
  api.post('/api/auth/login', { email, password })

export const signupAdmin = (name, email, password) =>
  api.post('/api/auth/signup', { name, email, password, role: 'admin' })

// ─── Stats ───────────────────────────────────────────────
export const getStats = () => api.get('/api/admin/stats')

// ─── Products ────────────────────────────────────────────
export const getProducts = (shopCode) =>
  api.get('/api/admin/products', { params: shopCode ? { shop_code: shopCode } : {} })

export const createProduct = (data) => api.post('/api/admin/products', data)
export const updateProduct = (code, data) => api.put(`/api/admin/products/${code}`, data)
export const updateProductStock = (code, stock) =>
  api.patch(`/api/admin/products/${code}/stock`, { stock })
export const deleteProduct = (code) => api.delete(`/api/admin/products/${code}`)

// ─── Shops ───────────────────────────────────────────────
export const getShops = () => api.get('/api/admin/shops')
export const createShop = (data) => api.post('/api/admin/shops', data)
export const updateShop = (code, data) => api.put(`/api/admin/shops/${code}`, data)
export const deleteShop = (code) => api.delete(`/api/admin/shops/${code}`)

// ─── Users ───────────────────────────────────────────────
export const getUsers = (role) =>
  api.get('/api/admin/users', { params: role ? { role } : {} })

// ─── Orders ──────────────────────────────────────────────
export const getOrders = (status) =>
  api.get('/api/admin/orders', { params: status ? { status } : {} })

export default api
