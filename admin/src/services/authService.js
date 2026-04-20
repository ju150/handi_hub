import { signInWithEmailAndPassword, signOut } from 'firebase/auth'
import { doc, getDoc } from 'firebase/firestore'
import { auth, db } from './firebase'

// Connecte l'utilisateur via Firebase Auth, puis charge son profil Firestore.
// Les deux opérations sont séparées : une erreur de profil ne bloque pas la connexion.
export async function login(email, password) {
  // Peut lever FirebaseError si email/mdp incorrects → propagé vers LoginPage
  const credential = await signInWithEmailAndPassword(auth, email, password)

  // Chargement du profil séparé : une erreur ici ne doit pas masquer une connexion réussie
  const profile = await getUserProfile(credential.user.uid)
  return { user: credential.user, profile }
}

export async function logout() {
  await signOut(auth)
}

// Retourne le profil Firestore ou null si absent / règle bloquante
export async function getUserProfile(uid) {
  try {
    const snap = await getDoc(doc(db, 'users', uid))
    if (!snap.exists()) return null
    return { uid, ...snap.data() }
  } catch (e) {
    console.warn('getUserProfile: impossible de lire le profil Firestore', e.message)
    return null
  }
}
