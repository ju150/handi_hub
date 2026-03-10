import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Gère le téléchargement et le cache local des fichiers EPUB.
class EpubCacheService {
  EpubCacheService._();
  static final EpubCacheService instance = EpubCacheService._();

  /// Retourne le fichier EPUB en cache, ou le télécharge depuis [downloadUrl].
  Future<File> getOrDownload(String bookId, String downloadUrl) async {
    final file = await _cacheFile(bookId);
    if (await file.exists()) return file;
    await file.parent.create(recursive: true);
    final response = await http.get(Uri.parse(downloadUrl));
    if (response.statusCode != 200) {
      throw Exception('Téléchargement échoué (${response.statusCode})');
    }
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  /// Supprime le fichier EPUB du cache local.
  Future<void> clearCache(String bookId) async {
    final file = await _cacheFile(bookId);
    if (await file.exists()) await file.delete();
  }

  // Construit le chemin du fichier local
  Future<File> _cacheFile(String bookId) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/epubs/$bookId.epub');
  }
}
