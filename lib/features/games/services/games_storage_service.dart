import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_score.dart';

/// Persistance locale des scores et favoris du module Jeux.
///
/// Utilise SharedPreferences (déjà en dépendance). Singleton, appeler
/// [init] au démarrage de l'application.
class GamesStorageService {
  GamesStorageService._();
  static final GamesStorageService instance = GamesStorageService._();

  late SharedPreferences _prefs;
  bool _initialized = false;

  static const String _scorePrefix  = 'game_score_';
  static const String _favoritesKey = 'game_favorites';

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // ─── Scores ───────────────────────────────────────────────────────────────

  GameScore getScore(String gameId) {
    final raw = _prefs.getString('$_scorePrefix$gameId');
    if (raw == null) return GameScore(gameId: gameId);
    try {
      return GameScore.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return GameScore(gameId: gameId);
    }
  }

  Future<void> updateScore({
    required String gameId,
    required int score,
    required int level,
  }) async {
    final s = getScore(gameId);
    s.gamesPlayed++;
    s.lastPlayed = DateTime.now();
    if (score > s.bestScore) s.bestScore = score;
    if (level > s.highestLevel) s.highestLevel = level;
    await _prefs.setString('$_scorePrefix$gameId', jsonEncode(s.toMap()));
  }

  // ─── Favoris ──────────────────────────────────────────────────────────────

  List<String> getFavorites() =>
      _prefs.getStringList(_favoritesKey) ?? [];

  bool isFavorite(String gameId) => getFavorites().contains(gameId);

  /// Bascule le favori et renvoie le nouvel état (true = ajouté).
  Future<bool> toggleFavorite(String gameId) async {
    final favs = getFavorites();
    final bool nowFav;
    if (favs.contains(gameId)) {
      favs.remove(gameId);
      nowFav = false;
    } else {
      favs.add(gameId);
      nowFav = true;
    }
    await _prefs.setStringList(_favoritesKey, favs);
    return nowFav;
  }
}
