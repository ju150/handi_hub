import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/lecture/lecture_data.dart';

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  Future<List<BookEntry>> fetchBooks() async {
    try {
      final db = FirebaseFirestore.instance;
      final snapshot = await db
          .collection('books')
          .orderBy('title')
          .get()
          .timeout(const Duration(seconds: 5));
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return BookEntry(
          id: doc.id,
          title: data['title'] as String,
          author: data['author'] as String? ?? '',
          pdfUrl: data['pdfUrl'] as String?,
          isLocal: data['isLocal'] as bool? ?? false,
          coverColor: data['coverColor'] as int? ?? 0xFF1565C0,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
