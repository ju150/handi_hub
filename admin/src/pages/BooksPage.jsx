import CrudPage from '../components/CrudPage'

// ADMIN-02 : ajout et gestion des livres dans Firestore.
// storageRef = chemin dans Firebase Storage (ex: books/mon_livre.epub)
// L'epub doit être uploadé manuellement dans Firebase Storage.
// published est stocké comme booléen dans Firestore mais géré comme string dans le formulaire.

const FIELDS = [
  { name: 'title',      label: 'Titre',              type: 'text',   required: true },
  { name: 'author',     label: 'Auteur',             type: 'text' },
  { name: 'storageRef', label: 'Chemin Storage (ex: books/livre.epub)', type: 'text', required: true },
  { name: 'coverUrl',   label: 'URL de couverture',  type: 'text' },
  { name: 'summary',    label: 'Résumé',             type: 'textarea' },
  { name: 'order',      label: 'Ordre d\'affichage', type: 'number', required: true },
  { name: 'published', label: 'Publié', type: 'select', required: true, options: [
    { value: 'true',  label: 'Oui — visible dans l\'app' },
    { value: 'false', label: 'Non — masqué' },
  ]},
]

// Convertit published de string vers booléen avant l'envoi à Firestore
function transform(values) {
  return { ...values, published: values.published === 'true', order: Number(values.order) || 0 }
}

// Convertit published de booléen vers string pour l'affichage dans le formulaire
function prepareInitial(item) {
  return { ...item, published: item.published ? 'true' : 'false' }
}

export default function BooksPage() {
  return (
    <CrudPage
      title="📚 Livres"
      collection="books"
      fields={FIELDS}
      toCard={b => ({
        title:    b.title + (b.author ? ` — ${b.author}` : ''),
        subtitle: `Ordre : ${b.order ?? '—'} · ${b.published ? '✅ Publié' : '🔒 Masqué'}`,
        details:  b.storageRef,
      })}
      transform={transform}
      prepareInitial={prepareInitial}
      adminOnly
    />
  )
}
