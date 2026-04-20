import { Navigate } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'

export default function ProtectedRoute({ children }) {
  const { user } = useAuth()

  // undefined = Firebase Auth pas encore répondu → on attend
  if (user === undefined) {
    return <div className="loading-screen">Chargement...</div>
  }

  // null = confirmé non connecté → redirection login
  if (user === null) {
    return <Navigate to="/login" replace />
  }

  // user = objet Firebase → connecté, on affiche la page
  return children
}
