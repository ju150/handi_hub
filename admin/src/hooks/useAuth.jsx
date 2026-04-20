import { useState, useEffect, createContext, useContext } from 'react'
import { onAuthStateChanged } from 'firebase/auth'
import { auth } from '../services/firebase'
import { getUserProfile } from '../services/authService'

// Contexte partagé dans toute l'app : user (Firebase) + profile (Firestore)
export const AuthContext = createContext(null)

export function useAuth() {
  return useContext(AuthContext)
}

// Provider à placer autour de tout le routeur dans App.jsx
export function AuthProvider({ children }) {
  const [user, setUser]       = useState(undefined) // undefined = pas encore chargé
  const [profile, setProfile] = useState(null)

  useEffect(() => {
    // onAuthStateChanged se déclenche au montage et à chaque changement de session
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      // On met user à jour immédiatement — sans attendre le profil Firestore.
      // Sinon la navigation depuis LoginPage se bloque en attendant Firestore.
      setUser(firebaseUser ?? null)

      if (firebaseUser) {
        const p = await getUserProfile(firebaseUser.uid)
        setProfile(p)
      } else {
        setProfile(null)
      }
    })
    return unsubscribe // nettoyage à la destruction du composant
  }, [])

  return (
    <AuthContext.Provider value={{ user, profile }}>
      {children}
    </AuthContext.Provider>
  )
}
