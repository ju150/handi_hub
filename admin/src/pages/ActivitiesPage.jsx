import CrudPage from '../components/CrudPage'

const FIELDS = [
  { name: 'date',        label: 'Date',            type: 'date',   required: true },
  { name: 'title',       label: 'Activité',        type: 'text',   required: true },
  { name: 'category', label: 'Catégorie', type: 'select', required: true, options: [
    { value: 'leisure',   label: 'Loisir' },
    { value: 'social',    label: 'Social' },
    { value: 'outdoor',   label: 'Sortie' },
    { value: 'creative',  label: 'Créatif' },
    { value: 'cognitive', label: 'Cognitif' },
    { value: 'other',     label: 'Autre' },
  ]},
  { name: 'durationMin', label: 'Durée (min)', type: 'number' },
  { name: 'notes',       label: 'Notes',       type: 'textarea' },
]

const CAT = { leisure: 'Loisir', social: 'Social', outdoor: 'Sortie', creative: 'Créatif', cognitive: 'Cognitif', other: 'Autre' }

export default function ActivitiesPage() {
  return (
    <CrudPage
      title="🎯 Activités"
      collection="activity_logs"
      fields={FIELDS}
      toCard={a => ({
        title:    `${a.date} — ${a.title}`,
        subtitle: `${CAT[a.category] || a.category}${a.durationMin ? ' · ' + a.durationMin + ' min' : ''}`,
        details:  a.notes,
      })}
    />
  )
}
