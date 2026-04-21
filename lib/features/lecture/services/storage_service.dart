import 'package:shared_preferences/shared_preferences.dart';

/// Persistance locale de toutes les données utilisateur liées à la lecture.
///
/// Utilise [SharedPreferences] (paires clé/valeur stockées sur l'appareil).
/// Singleton : StorageService.instance partout dans l'app.
/// Doit être initialisé dans main.dart avant runApp() via [init()].
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  late SharedPreferences _prefs;

  /// À appeler une seule fois au démarrage de l'app (dans main.dart).
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Position PDF (ancien système, conservé pour compatibilité) ────────────

  static const String _pagePrefix = 'pdf_page_';

  Future<void> saveLastPage(String bookId, int page) async {
    await _prefs.setInt('$_pagePrefix$bookId', page);
  }

  int getLastPage(String bookId) {
    return _prefs.getInt('$_pagePrefix$bookId') ?? 1;
  }

  Future<void> clearProgress(String bookId) async {
    await _prefs.remove('$_pagePrefix$bookId');
  }

  // ── Position EPUB (CFI — conservé mais non utilisé) ───────────────────────
  // Le CFI (Canonical Fragment Identifier) est le système natif d'epub_view
  // pour repérer une position dans un EPUB. Problème : epub_view 3.x génère
  // des CFI avec [null] comme ID de chapitre quand celui-ci est absent du
  // fichier EPUB, ex: "epubcfi(/6/0[null]!/4/10)". Ce CFI ne peut pas être
  // relu correctement et le livre repart toujours du début.
  // → Remplacé par l'index entier ci-dessous, plus fiable.

  Future<void> saveEpubCfi(String bookId, String cfi) async {
    await _prefs.setString('epub_cfi_$bookId', cfi);
  }

  String? getEpubCfi(String bookId) {
    return _prefs.getString('epub_cfi_$bookId');
  }

  Future<void> clearEpubProgress(String bookId) async {
    await _prefs.remove('epub_cfi_$bookId');
    await _prefs.remove('epub_pos_$bookId');
  }

  // ── Position EPUB par index de paragraphe ─────────────────────────────────
  // epub_view représente le contenu comme une liste plate de paragraphes.
  // Chaque paragraphe a un index (0, 1, 2…). On sauvegarde cet index et on
  // restaure via controller.jumpTo(index: savedIndex).
  // Précaution : on ne sauvegarde jamais l'index 0 (début du livre) pour ne
  // pas écraser une position valide si jumpTo() échoue silencieusement.

  Future<void> saveEpubPosition(String bookId, int index) async {
    await _prefs.setInt('epub_pos_$bookId', index);
  }

  /// Retourne null si le livre n'a jamais été ouvert (= "à découvrir").
  int? getEpubPosition(String bookId) {
    return _prefs.getInt('epub_pos_$bookId');
  }

  // ── Taille de police EPUB ─────────────────────────────────────────────────
  // Mémorisée globalement (pas par livre) — un seul réglage pour tous les livres.

  Future<void> saveEpubFontSize(double size) async {
    await _prefs.setDouble('epub_font_size', size);
  }

  double getEpubFontSize({double defaultSize = 22.0}) {
    return _prefs.getDouble('epub_font_size') ?? defaultSize;
  }

  // ── Dernier livre ouvert ──────────────────────────────────────────────────
  // Utilisé par LecturePage pour afficher en "vedette" le livre le plus récent.

  Future<void> saveLastOpenedBook(String bookId) async {
    await _prefs.setString('last_opened_book', bookId);
  }

  String? getLastOpenedBook() {
    return _prefs.getString('last_opened_book');
  }

  // ── Statut de lecture ─────────────────────────────────────────────────────
  // Liste des IDs de livres marqués "terminés", stockée comme StringList.
  // Togglable : on peut démARquer depuis les paramètres de lecture.

  Future<void> markFinished(String bookId) async {
    final set = _prefs.getStringList('finished_books') ?? [];
    if (!set.contains(bookId)) {
      set.add(bookId);
      await _prefs.setStringList('finished_books', set);
    }
  }

  Future<void> unmarkFinished(String bookId) async {
    final set = _prefs.getStringList('finished_books') ?? [];
    set.remove(bookId);
    await _prefs.setStringList('finished_books', set);
  }

  bool isFinished(String bookId) {
    return (_prefs.getStringList('finished_books') ?? []).contains(bookId);
  }
}
