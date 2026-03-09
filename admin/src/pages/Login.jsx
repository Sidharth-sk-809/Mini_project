import { useState } from 'react'
import { useAuth } from '../context/AuthContext'

export default function Login() {
  const { login, signup, loading, error, setError } = useAuth()
  const [mode, setMode] = useState('login') // 'login' | 'signup'

  // Login fields
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')

  // Signup fields
  const [name, setName] = useState('')
  const [signupEmail, setSignupEmail] = useState('')
  const [signupPassword, setSignupPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')

  const switchMode = (m) => {
    setMode(m)
    setError(null)
  }

  const handleLogin = async (e) => {
    e.preventDefault()
    setError(null)
    await login(email, password)
  }

  const handleSignup = async (e) => {
    e.preventDefault()
    setError(null)
    if (signupPassword !== confirmPassword) {
      setError('Passwords do not match.')
      return
    }
    if (signupPassword.length < 6) {
      setError('Password must be at least 6 characters.')
      return
    }
    await signup(name, signupEmail, signupPassword)
  }

  return (
    <div className="login-page">
      <div className="login-card">
        {/* Logo */}
        <div className="login-logo">
          <div className="login-logo-icon">🌿</div>
          <div>
            <div className="login-title">Neamet Admin</div>
            <div className="login-subtitle">Platform management portal</div>
          </div>
        </div>

        {/* Tab switcher */}
        <div style={{
          display: 'flex',
          background: 'var(--bg3)',
          borderRadius: 'var(--radius-sm)',
          padding: 3,
          marginBottom: 24,
          gap: 3,
        }}>
          {['login', 'signup'].map((m) => (
            <button
              key={m}
              type="button"
              onClick={() => switchMode(m)}
              style={{
                flex: 1,
                padding: '7px 0',
                border: 'none',
                borderRadius: 6,
                cursor: 'pointer',
                fontWeight: 600,
                fontSize: 13,
                fontFamily: 'inherit',
                transition: 'all 0.15s',
                background: mode === m ? 'var(--bg2)' : 'transparent',
                color: mode === m ? 'var(--text)' : 'var(--text3)',
                boxShadow: mode === m ? '0 1px 4px rgba(0,0,0,0.3)' : 'none',
              }}
            >
              {m === 'login' ? '🔑 Sign In' : '✨ Create Account'}
            </button>
          ))}
        </div>

        {/* Error */}
        {error && (
          <div className="login-error" style={{ marginBottom: 16 }}>
            ⚠️ {error}
          </div>
        )}

        {/* LOGIN FORM */}
        {mode === 'login' && (
          <form className="login-form" onSubmit={handleLogin}>
            <div className="form-group">
              <label className="form-label">Email</label>
              <input
                className="form-input"
                type="email"
                placeholder="admin@example.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoFocus
              />
            </div>
            <div className="form-group">
              <label className="form-label">Password</label>
              <input
                className="form-input"
                type="password"
                placeholder="Enter password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>
            <button className="btn btn-primary" type="submit" disabled={loading}>
              {loading ? <span className="spinner" /> : null}
              {loading ? 'Signing in…' : 'Sign In'}
            </button>
          </form>
        )}

        {/* SIGNUP FORM */}
        {mode === 'signup' && (
          <form className="login-form" onSubmit={handleSignup}>
            <div className="form-group">
              <label className="form-label">Full Name</label>
              <input
                className="form-input"
                type="text"
                placeholder="e.g. John Admin"
                value={name}
                onChange={(e) => setName(e.target.value)}
                required
                minLength={2}
                autoFocus
              />
            </div>
            <div className="form-group">
              <label className="form-label">Email</label>
              <input
                className="form-input"
                type="email"
                placeholder="admin@example.com"
                value={signupEmail}
                onChange={(e) => setSignupEmail(e.target.value)}
                required
              />
            </div>
            <div className="form-group">
              <label className="form-label">Password</label>
              <input
                className="form-input"
                type="password"
                placeholder="Min. 6 characters"
                value={signupPassword}
                onChange={(e) => setSignupPassword(e.target.value)}
                required
                minLength={6}
              />
            </div>
            <div className="form-group">
              <label className="form-label">Confirm Password</label>
              <input
                className="form-input"
                type="password"
                placeholder="Repeat password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                required
              />
            </div>
            <div style={{
              background: 'var(--accent-light)',
              border: '1px solid rgba(79,142,247,0.25)',
              borderRadius: 'var(--radius-sm)',
              padding: '8px 12px',
              fontSize: 12,
              color: 'var(--accent)',
              display: 'flex',
              gap: 6,
              alignItems: 'center',
            }}>
              🛡️ Account will be created with <strong>&nbsp;admin&nbsp;</strong> role and saved to the database.
            </div>
            <button className="btn btn-primary" type="submit" disabled={loading}>
              {loading ? <span className="spinner" /> : null}
              {loading ? 'Creating account…' : 'Create Admin Account'}
            </button>
          </form>
        )}
      </div>
    </div>
  )
}
