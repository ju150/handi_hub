import { useState } from 'react'
import { NavLink, Outlet, useNavigate } from 'react-router-dom'
import { logout } from '../services/authService'
import { useAuth } from '../hooks/useAuth'

const navItems = [
  { to: '/',             label: 'Tableau de bord', icon: '🏠', end: true },
  { to: '/care-visits',  label: 'Auxiliaires',     icon: '🤝' },
  { to: '/activities',   label: 'Activités',       icon: '🎯' },
  { to: '/nutrition',    label: 'Nutrition',       icon: '🥗' },
  { to: '/books',        label: 'Livres',          icon: '📚' },
  { to: '/reeducation',  label: 'Rééducation',     icon: '💪' },
]

export default function AppLayout() {
  const [menuOpen, setMenuOpen] = useState(false)
  const { profile } = useAuth()
  const navigate = useNavigate()

  async function handleLogout() {
    await logout()
    navigate('/login')
  }

  function closeMenu() {
    setMenuOpen(false)
  }

  return (
    <div className="layout">
      {/* Barre du haut (mobile uniquement) */}
      <header className="topbar">
        <button
          className="hamburger"
          onClick={() => setMenuOpen(o => !o)}
          aria-label="Menu"
        >
          {menuOpen ? '✕' : '☰'}
        </button>
        <span className="topbar-title">HandiHub</span>
      </header>

      {/* Overlay sombre quand le menu mobile est ouvert */}
      {menuOpen && (
        <div className="overlay" onClick={closeMenu} />
      )}

      {/* Sidebar (desktop toujours visible, mobile dépend de menuOpen) */}
      <nav className={`sidebar ${menuOpen ? 'sidebar--open' : ''}`}>
        <div className="sidebar-header">
          <span className="sidebar-logo">HandiHub Admin</span>
        </div>

        <ul className="nav-list">
          {navItems.map(item => (
            <li key={item.to}>
              <NavLink
                to={item.to}
                end={item.end}
                className={({ isActive }) =>
                  'nav-link' + (isActive ? ' nav-link--active' : '')
                }
                onClick={closeMenu}
              >
                <span className="nav-icon">{item.icon}</span>
                {item.label}
              </NavLink>
            </li>
          ))}
        </ul>

        <div className="sidebar-footer">
          {profile && (
            <p className="sidebar-user">
              {profile.displayName || profile.email}
              <span className="role-badge">{profile.role}</span>
            </p>
          )}
          <button className="btn-logout" onClick={handleLogout}>
            Déconnexion
          </button>
        </div>
      </nav>

      {/* Contenu principal — Outlet = la page active */}
      <main className="main-content">
        <Outlet />
      </main>
    </div>
  )
}
