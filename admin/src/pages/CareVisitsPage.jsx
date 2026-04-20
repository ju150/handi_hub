import CrudPage from '../components/CrudPage'

const FIELDS = [
  { name: 'date',          label: 'Date',               type: 'date',   required: true },
  { name: 'startTime',     label: 'Heure de début',     type: 'time',   required: true },
  { name: 'endTime',       label: 'Heure de fin',       type: 'time' },
  { name: 'caregiverName', label: 'Auxiliaire',         type: 'text',   required: true },
  { name: 'status', label: 'Statut', type: 'select', required: true, options: [
    { value: 'done',    label: 'Effectuée' },
    { value: 'partial', label: 'Partielle' },
    { value: 'absent',  label: 'Absent(e)' },
    { value: 'planned', label: 'Planifiée' },
  ]},
  { name: 'notes', label: 'Notes', type: 'textarea' },
]

const STATUS = { done: 'Effectuée', partial: 'Partielle', absent: 'Absent(e)', planned: 'Planifiée' }

export default function CareVisitsPage() {
  return (
    <CrudPage
      title="🤝 Suivi auxiliaires"
      collection="care_visits"
      fields={FIELDS}
      toCard={v => ({
        title:    `${v.date} — ${v.caregiverName}`,
        subtitle: `${v.startTime || ''}${v.endTime ? ' → ' + v.endTime : ''} · ${STATUS[v.status] || v.status}`,
        details:  v.notes,
      })}
    />
  )
}
