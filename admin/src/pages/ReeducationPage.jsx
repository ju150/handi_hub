import { useState, useEffect } from 'react'
import { getKineSessions } from '../services/reeducationService'

// Traduit les valeurs de retour de l'app tablette
const ZONE_LABELS = {
  rightArm: 'Bras droit', leftArm: 'Bras gauche',
  hands: 'Mains', face: 'Visage', trunk: 'Tronc / Posture', legs: 'Jambes',
}
const SIDE_LABELS = { right: 'Droit', left: 'Gauche', bilateral: 'Les deux' }
const FEEDBACK_LABELS = { great: '😊 Bien passé', ok: '😐 Correct', hard: '😓 Difficile' }
const SUCCESS_LABELS  = { yes: '✅ Réussi', partial: '⚠️ Partiel', no: '❌ Non réussi' }

function formatDate(iso) {
  if (!iso) return '—'
  return new Date(iso).toLocaleString('fr-FR', {
    day: '2-digit', month: '2-digit', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  })
}

function SessionCard({ session }) {
  const progress = session.totalSteps > 0
    ? Math.round((session.stepsCompleted / session.totalSteps) * 100)
    : 0

  return (
    <div className="entry-card session-card">
      <div className="entry-card-body">
        <p className="entry-title">{session.exerciseTitle || session.exerciseId}</p>
        <p className="entry-subtitle">
          {ZONE_LABELS[session.zone] || session.zone}
          {session.side ? ` · ${SIDE_LABELS[session.side] || session.side}` : ''}
          {' · '}{formatDate(session.completedAt)}
        </p>
        <div className="session-meta">
          <span className="session-progress">
            {session.stepsCompleted}/{session.totalSteps} étapes ({progress}%)
          </span>
          {session.fullyCompleted
            ? <span className="badge badge--green">Complet</span>
            : <span className="badge badge--orange">Incomplet</span>
          }
          {session.feedback && (
            <span className="badge badge--blue">{FEEDBACK_LABELS[session.feedback] || session.feedback}</span>
          )}
          {session.success && (
            <span className="badge badge--grey">{SUCCESS_LABELS[session.success] || session.success}</span>
          )}
        </div>
        <p className="entry-details">Appareil : {session.deviceId}</p>
      </div>
    </div>
  )
}

export default function ReeducationPage() {
  const [sessions, setSessions] = useState([])
  const [loading, setLoading]   = useState(true)
  const [filter, setFilter]     = useState('all') // 'all' | 'complete' | 'incomplete'

  useEffect(() => { load() }, [])

  async function load() {
    setLoading(true)
    const data = await getKineSessions()
    setSessions(data)
    setLoading(false)
  }

  const filtered = sessions.filter(s => {
    if (filter === 'complete')   return s.fullyCompleted
    if (filter === 'incomplete') return !s.fullyCompleted
    return true
  })

  if (loading) return <p className="page-loading">Chargement…</p>

  return (
    <div>
      <div className="page-header">
        <h1 className="page-title">💪 Rééducation — Sessions kiné</h1>
      </div>

      <p className="page-info">
        Ces données sont enregistrées automatiquement depuis la tablette de la patiente.
        Cette page est en lecture seule.
      </p>

      {/* Filtre rapide */}
      <div className="filter-bar">
        {['all', 'complete', 'incomplete'].map(f => (
          <button
            key={f}
            className={`filter-btn ${filter === f ? 'filter-btn--active' : ''}`}
            onClick={() => setFilter(f)}
          >
            {{ all: 'Toutes', complete: 'Complètes', incomplete: 'Incomplètes' }[f]}
          </button>
        ))}
        <span className="filter-count">{filtered.length} session(s)</span>
      </div>

      {filtered.length === 0 ? (
        <div className="empty-state"><span className="empty-icon">💪</span><p>Aucune session kiné trouvée.</p></div>
      ) : (
        <div className="entries-list">
          {filtered.map(s => <SessionCard key={s.id} session={s} />)}
        </div>
      )}
    </div>
  )
}
