import { useState, useEffect } from 'react'
import { useAuth } from '../hooks/useAuth'
import { getAll } from '../services/firestoreService'
import { getKineSessions } from '../services/reeducationService'

function StatCard({ icon, label, value, color }) {
  return (
    <div className="stat-card" style={{ borderLeftColor: color }}>
      <span className="stat-icon">{icon}</span>
      <div className="stat-body">
        <p className="stat-value">{value ?? '—'}</p>
        <p className="stat-label">{label}</p>
      </div>
    </div>
  )
}

function today() { return new Date().toISOString().slice(0, 10) }

export default function DashboardPage() {
  const { profile } = useAuth()
  const [stats, setStats] = useState(null)

  useEffect(() => { load() }, [])

  async function load() {
    const [visits, activities, nutrition, sessions] = await Promise.all([
      getAll('care_visits'),
      getAll('activity_logs'),
      getAll('nutrition_logs'),
      getKineSessions(),
    ])
    const t = today()
    setStats({
      visitsToday:      visits.filter(v => v.date === t).length,
      visitsTotal:      visits.length,
      activitiesTotal:  activities.length,
      nutritionToday:   nutrition.filter(n => n.date === t).length,
      sessionsTotal:    sessions.length,
      sessionsComplete: sessions.filter(s => s.fullyCompleted).length,
      recentVisits:     visits.sort((a,b) => b.date?.localeCompare(a.date)).slice(0, 3),
      recentSessions:   sessions.slice(0, 3),
    })
  }

  if (!stats) return <p className="page-loading">Chargement…</p>

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Bonjour {profile?.displayName || '👋'}</h1>
          <p className="page-date">{new Date().toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })}</p>
        </div>
      </div>

      <div className="stats-grid">
        <StatCard icon="🤝" label="Visites aujourd'hui"   value={stats.visitsToday}      color="#1565c0" />
        <StatCard icon="📋" label="Visites au total"      value={stats.visitsTotal}      color="#0d47a1" />
        <StatCard icon="🎯" label="Activités enregistrées" value={stats.activitiesTotal} color="#2e7d32" />
        <StatCard icon="🥗" label="Repas aujourd'hui"    value={stats.nutritionToday}   color="#e65100" />
        <StatCard icon="💪" label="Sessions kiné"         value={stats.sessionsTotal}    color="#6a1b9a" />
        <StatCard icon="✅" label="Sessions complètes"    value={stats.sessionsComplete} color="#00838f" />
      </div>

      <section className="dashboard-section">
        <h2 className="section-title">Dernières visites</h2>
        {stats.recentVisits.length === 0 ? <p className="section-empty">Aucune visite.</p> : (
          <div className="entries-list">
            {stats.recentVisits.map(v => (
              <div key={v.id} className="entry-card">
                <div className="entry-card-body">
                  <p className="entry-title">{v.date} — {v.caregiverName}</p>
                  <p className="entry-subtitle">{v.startTime}{v.endTime ? ' → ' + v.endTime : ''}</p>
                </div>
                <span className={`badge ${v.status === 'done' ? 'badge--green' : 'badge--orange'}`}>
                  {{ done: 'Effectuée', partial: 'Partielle', absent: 'Absent(e)', planned: 'Planifiée' }[v.status] || v.status}
                </span>
              </div>
            ))}
          </div>
        )}
      </section>

      <section className="dashboard-section">
        <h2 className="section-title">Dernières sessions kiné</h2>
        {stats.recentSessions.length === 0 ? <p className="section-empty">Aucune session depuis la tablette.</p> : (
          <div className="entries-list">
            {stats.recentSessions.map(s => (
              <div key={s.id} className="entry-card">
                <div className="entry-card-body">
                  <p className="entry-title">{s.exerciseTitle || s.exerciseId}</p>
                  <p className="entry-subtitle">{s.completedAt ? new Date(s.completedAt).toLocaleString('fr-FR') : ''}</p>
                </div>
                <span className={`badge ${s.fullyCompleted ? 'badge--green' : 'badge--orange'}`}>
                  {s.fullyCompleted ? 'Complet' : 'Incomplet'}
                </span>
              </div>
            ))}
          </div>
        )}
      </section>
    </div>
  )
}
