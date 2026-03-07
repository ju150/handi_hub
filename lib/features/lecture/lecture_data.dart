class BookEntry {
  const BookEntry({
    required this.id,
    required this.title,
    this.author = '',
    this.pdfUrl,
    this.isLocal = true,
    this.coverColor = 0xFF1565C0,
  });

  final String id;
  final String title;
  final String author;
  final String? pdfUrl;
  final bool isLocal;
  final int coverColor;

  String get localAssetPath => 'assets/pdfs/$id.pdf';
}

const List<BookEntry> kLocalBooks = [
  BookEntry(
    id: 'exemple',
    title: 'Exemple de livre',
    author: 'Auteur',
    isLocal: true,
    coverColor: 0xFF1565C0,
  ),
];
