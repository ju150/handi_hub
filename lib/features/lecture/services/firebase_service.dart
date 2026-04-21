import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/lecture_data.dart';



// Sert à centraliser l’accès à Firebase pour la partie livres et plus précisément :
    // Récupérer la liste des livres publiés depuis Firestore
    // Obtenir l’URL de téléchargement d’un fichier stocké dans Firebase Storage

class FirebaseService {
  // Constructeur privé : empêche de créer plusieurs instances de la classe
  FirebaseService._();
  
  // Instance unique accessible partout dans l'app
  static final FirebaseService instance = FirebaseService._();

  /// Mis à true dans main.dart après Firebase.initializeApp() réussi.
  static bool isInitialized = false;

  /// Retourne les livres publiés, triés par ordre.
  Future<List<BookEntry>> fetchBooks() async {
    if (!isInitialized) return [];
    try {
      debugPrint('🔍 fetchBooks: requête Firestore...');
      final snapshot = await FirebaseFirestore.instance
          .collection('books')
          .where('published', isEqualTo: true)
          .orderBy('order')
          .get()
          .timeout(const Duration(seconds: 15)); // 15s : réseau mobile parfois lent au premier lancement
      debugPrint('📚 fetchBooks: ${snapshot.docs.length} livre(s) trouvé(s)');
      return snapshot.docs.map((doc) {
        final d = doc.data();
        return BookEntry(
          id: doc.id,
          title: d['title'] as String,
          author: d['author'] as String? ?? '',
          storageRef: d['storageRef'] as String,
          coverUrl: d['coverUrl'] as String?,
          coverColor: d['coverColor'] as int? ?? 0xFF1565C0,
          order: d['order'] as int? ?? 0,
          summary: d['summary'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ fetchBooks erreur : $e');
      return [];
    }
  }

  /// Retourne l'URL publique/signée pour télécharger un fichier stocké dans Firebase Storage.
  ///
  /// Exemple de storageRef :
  /// 'books/le_petit_prince.epub'
  Future<String> getDownloadUrl(String storageRef) async {
    return FirebaseStorage.instance.ref(storageRef).getDownloadURL();
  }
}
