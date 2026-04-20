import { collectionGroup, getDocs } from 'firebase/firestore'
import { db } from './firebase'

// collectionGroup('sessions') lit toutes les sous-collections nommées "sessions"
// dans tout Firestore, peu importe le deviceId parent.
// Pas d'orderBy ici pour éviter d'avoir besoin d'un index — tri côté client.
export async function getKineSessions() {
  try {
    const snap = await getDocs(collectionGroup(db, 'sessions'))
    return snap.docs
      .map(d => ({ id: d.id, deviceId: d.ref.parent.parent.id, ...d.data() }))
      .sort((a, b) => (b.completedAt || '').localeCompare(a.completedAt || ''))
  } catch (e) {
    console.error('getKineSessions:', e.message)
    return []
  }
}
