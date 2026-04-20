import {
  collection, getDocs, addDoc, updateDoc,
  deleteDoc, doc, serverTimestamp
} from 'firebase/firestore'
import { db } from './firebase'

// Service générique pour toutes les collections CRUD simples.
// Évite de dupliquer la même logique dans careVisits, activities, nutrition, books.

export async function getAll(col) {
  try {
    const snap = await getDocs(collection(db, col))
    return snap.docs.map(d => ({ id: d.id, ...d.data() }))
  } catch (e) {
    console.error(`getAll(${col}):`, e.message)
    return []
  }
}

export async function addOne(col, data, createdBy) {
  await addDoc(collection(db, col), { ...data, createdBy, createdAt: serverTimestamp() })
}

export async function updateOne(col, id, data) {
  await updateDoc(doc(db, col, id), data)
}

export async function deleteOne(col, id) {
  await deleteDoc(doc(db, col, id))
}
