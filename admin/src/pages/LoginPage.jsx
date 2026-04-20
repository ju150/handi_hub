import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { login } from '../services/authService'
import { useAuth } from '../hooks/useAuth'

export default function LoginPage() {
  const [email, setEmail]       = useState('')
  const [password, setPassword] = useState('')
  const [error, setError]       = useState('')
  const [loading, setLoading]   = useState(false)

  const navigate   = useNavigate()
  const { user }   = useAuth()

  // Redirige dès que onAuthStateChanged confirme la connexion dans le contexte
  useEffect(() => {
    if (user) navigate('/', { replace: true })
  }, [user])

  async function handleSubmit(e) {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      await login(email, password)
      // Pas de navigate() ici — c'est le useEffect ci-dessus qui redirige
      // une fois que le contexte Auth est réellement mis à jour
    } catch (err) {
      const authErrors = ['auth/invalid-credential', 'auth/wrong-password', 'auth/user-not-found', 'auth/invalid-email']
      if (authErrors.includes(err.code)) {
        setError('Email ou mot de passe incorrect.')
      } else {
        setError('Erreur de connexion. Vérifie ta configuration Firebase.')
        console.error(err)
      }
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="login-wrapper">
      <div className="login-card">
        <h1 className="login-title">HandiHub Admin</h1>
        <p className="login-subtitle">Connexion à l'espace de suivi</p>

        <form onSubmit={handleSubmit} className="login-form">
          <label>
            Email
            <input
              type="email"
              value={email}
              onChange={e => setEmail(e.target.value)}
              required
              autoComplete="email"
            />
          </label>

          <label>
            Mot de passe
            <input
              type="password"
              value={password}
              onChange={e => setPassword(e.target.value)}
              required
              autoComplete="current-password"
            />
          </label>

          {error && <p className="form-error">{error}</p>}

          <button type="submit" className="btn-primary" disabled={loading}>
            {loading ? 'Connexion…' : 'Se connecter'}
          </button>
        </form>
      </div>
    </div>
  )
}
