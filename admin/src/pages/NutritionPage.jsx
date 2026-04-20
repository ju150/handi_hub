import CrudPage from '../components/CrudPage'

const FIELDS = [
  { name: 'date', label: 'Date', type: 'date', required: true },
  { name: 'mealType', label: 'Repas', type: 'select', required: true, options: [
    { value: 'breakfast', label: 'Petit-déjeuner' },
    { value: 'lunch',     label: 'Déjeuner' },
    { value: 'dinner',    label: 'Dîner' },
    { value: 'snack',     label: 'Collation' },
  ]},
  { name: 'description',  label: 'Contenu',          type: 'textarea' },
  { name: 'hydrationMl',  label: 'Hydratation (ml)', type: 'number' },
  { name: 'appetite', label: 'Appétit', type: 'select', options: [
    { value: 'good',    label: 'Bon' },
    { value: 'average', label: 'Moyen' },
    { value: 'poor',    label: 'Faible' },
  ]},
  { name: 'notes', label: 'Notes', type: 'textarea' },
]

const MEAL = { breakfast: 'Petit-déjeuner', lunch: 'Déjeuner', dinner: 'Dîner', snack: 'Collation' }

export default function NutritionPage() {
  return (
    <CrudPage
      title="🥗 Nutrition"
      collection="nutrition_logs"
      fields={FIELDS}
      toCard={n => ({
        title:    `${n.date} — ${MEAL[n.mealType] || n.mealType}`,
        subtitle: `${n.hydrationMl ? n.hydrationMl + ' ml · ' : ''}Appétit : ${n.appetite || '—'}`,
        details:  n.description || n.notes,
      })}
    />
  )
}
