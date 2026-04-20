import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const _key = 'discussion_favorites';
  static const maxFavorites = 6;

  static Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> setFavorites(List<String> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, addresses.take(maxFavorites).toList());
  }
}
