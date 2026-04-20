import { useState, useEffect } from 'react'
import { useAuth } from '../hooks/useAuth'
import { getAll, addOne, updateOne, deleteOne } from '../services/firestoreService'

export default function CrudPage({ title, collection, fields, toCard, transform, prepareInitial, adminOnly = false }) {
  const { user, profile } = useAuth()
  const [items, setItems]       = useState([])
  const [loading, setLoading]   = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [editing, setEditing]   = useState(null)

  const canEdit = adminOnly
    ? profile?.role === 'admin'
    : profile?.role === 'editor' || profile?.role === 'admin'

  const defaultSort = (a, b) => (b.date || b.createdAt || '').localeCompare(a.date || a.createdAt || '')

  useEffect(() => { load() }, [])

  async function load() {
    setLoading(true)
    const data = await getAll(collection)
    setItems([...data].sort(defaultSort))
    setLoading(false)
  }

  async function handleSubmit(values) {
    const data = transform ? transform(values) : values
    if (editing) {
      await updateOne(collection, editing.id, data)
      setEditing(null)
    } else {
      await addOne(collection, data, user?.email)
      setShowForm(false)
    }
    load()
  }

  async function handleDelete(id) {
    if (!window.confirm('Supprimer cette entrée ?')) return
    await deleteOne(collection, id)
    load()
  }

  if (loading) return <p className="page-loading">Chargement…</p>

  return (
    <div>
      <div className="page-header">
        <h1 className="page-title">{title}</h1>
        {canEdit && !showForm && !editing && (
          <button className="btn-primary" onClick={() => setShowForm(true)}>+ Ajouter</button>
        )}
      </div>

      {(showForm || editing) && (
        <div className="form-panel">
          <Form
            fields={fields}
            initial={editing && prepareInitial ? prepareInitial(editing) : (editing || {})}
            onSubmit={handleSubmit}
            onCancel={() => { setShowForm(false); setEditing(null) }}
            submitLabel={editing ? 'Mettre à jour' : 'Enregistrer'}
          />
        </div>
      )}

      {items.length === 0 ? (
        <div className="empty-state">
          <span className="empty-icon">📋</span>
          <p>Aucune entrée pour le moment.</p>
        </div>
      ) : (
        <div className="entries-list">
          {items.map(item => {
            const card = toCard(item)
            return (
              <div key={item.id} className="entry-card">
                <div className="entry-card-body">
                  <p className="entry-title">{card.title}</p>
                  {card.subtitle && <p className="entry-subtitle">{card.subtitle}</p>}
                  {card.details  && <p className="entry-details">{card.details}</p>}
                </div>
                {canEdit && (
                  <div className="entry-card-actions">
                    <button className="btn-icon" onClick={() => { setEditing(item); setShowForm(false) }}>✏️</button>
                    <button className="btn-icon btn-icon--danger" onClick={() => handleDelete(item.id)}>🗑️</button>
                  </div>
                )}
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}

// Formulaire inline — pas de fichier séparé nécessaire
function Form({ fields, initial, onSubmit, onCancel, submitLabel }) {
  const [values, setValues] = useState(
    Object.fromEntries(fields.map(f => [f.name, initial[f.name] ?? '']))
  )
  const [loading, setLoading] = useState(false)

  function set(name, value) {
    setValues(v => ({ ...v, [name]: value }))
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setLoading(true)
    try { await onSubmit(values) } finally { setLoading(false) }
  }

  return (
    <form className="entry-form" onSubmit={handleSubmit}>
      {fields.map(f => (
        <label key={f.name} className="form-field">
          {f.label}
          {f.type === 'select' ? (
            <select value={values[f.name]} onChange={e => set(f.name, e.target.value)} required={f.required}>
              <option value="">— Choisir —</option>
              {f.options.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
            </select>
          ) : f.type === 'textarea' ? (
            <textarea value={values[f.name]} onChange={e => set(f.name, e.target.value)} rows={3} />
          ) : (
            <input type={f.type || 'text'} value={values[f.name]} onChange={e => set(f.name, e.target.value)} required={f.required} />
          )}
        </label>
      ))}
      <div className="form-actions">
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Enregistrement…' : submitLabel}
        </button>
        <button type="button" className="btn-secondary" onClick={onCancel}>Annuler</button>
      </div>
    </form>
  )
}
