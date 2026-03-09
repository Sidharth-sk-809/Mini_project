import { createContext, useContext, useState, useEffect, useCallback } from 'react'
import { loginAdmin, signupAdmin } from '../api/client'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => {
    try {
      const stored = localStorage.getItem('admin_user')
      return stored ? JSON.parse(stored) : null
    } catch {
      return null
    }
  })
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const logout = useCallback(() => {
    localStorage.removeItem('admin_token')
    localStorage.removeItem('admin_user')
    setUser(null)
  }, [])

  useEffect(() => {
    window.addEventListener('auth:logout', logout)
    return () => window.removeEventListener('auth:logout', logout)
  }, [logout])

  const login = async (email, password) => {
    setLoading(true)
    setError(null)
    try {
      const { data } = await loginAdmin(email, password)
      if (data.role !== 'admin') {
        setError('Access denied. Admin role required.')
        setLoading(false)
        return false
      }
      localStorage.setItem('admin_token', data.access_token)
      localStorage.setItem('admin_user', JSON.stringify(data))
      setUser(data)
      setLoading(false)
      return true
    } catch (err) {
      const msg =
        err.response?.data?.detail ||
        err.response?.data?.message ||
        'Login failed. Check credentials.'
      setError(msg)
      setLoading(false)
      return false
    }
  }

  const signup = async (name, email, password) => {
    setLoading(true)
    setError(null)
    try {
      const { data } = await signupAdmin(name, email, password)
      localStorage.setItem('admin_token', data.access_token)
      localStorage.setItem('admin_user', JSON.stringify(data))
      setUser(data)
      setLoading(false)
      return true
    } catch (err) {
      const detail = err.response?.data?.detail
      let msg
      if (Array.isArray(detail)) {
        // Pydantic 422 validation errors — pick the first message
        msg = detail[0]?.msg || 'Validation error.'
      } else {
        msg = detail || err.response?.data?.message || 'Signup failed. Try again.'
      }
      setError(typeof msg === 'string' ? msg : JSON.stringify(msg))
      setLoading(false)
      return false
    }
  }

  return (
    <AuthContext.Provider value={{ user, login, signup, logout, loading, error, setError }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  return useContext(AuthContext)
}
