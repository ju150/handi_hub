// Modèle représentant un livre dans la bibliothèque.

// Les données viennent de Firestore (collection "books").
// [coverUrl] et [summary] sont optionnels.
class BookEntry {
  const BookEntry({
    required this.id,
    required this.title,
    this.author = '',
    required this.storageRef,
    this.coverUrl,
    this.coverColor = 0xFF1565C0, //couleur de fallback si pas de cover
    this.order = 0,
    this.summary,
  }); //déclaré const car les books viennet de Firestore et ne changent jamais une fois créés

  // Identifiant Firestore du document — sert aussi de clé de cache local
  // et de clé SharedPreferences (position, statut terminé, etc.).
  final String id;

  final String title;
  final String author;

  // Chemin dans Firebase Storage, ex: "books/le-petit-prince.epub".
  // On appelle [FirebaseService.getDownloadUrl] pour obtenir une URL signée.
  final String storageRef;

  // URL de la couverture — peut être une URL https directe OU un chemin Firebase Storage. 
  // La fonction _resolveCoverUrl dans les pages gère les deux cas automatiquement.
  final String? coverUrl;

  final int coverColor;

  /// Ordre d'affichage (trié côté Firestore, pas côté client, possibilité future de réfléxion/d'amélioration).
  final int order;

  final String? summary;
}
