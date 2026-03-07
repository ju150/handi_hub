import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

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
}
