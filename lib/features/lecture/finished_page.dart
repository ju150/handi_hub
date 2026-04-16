import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/handi_scaffold.dart';
import 'lecture_data.dart';

Future<String?> _resolveCoverUrl(String? raw) async {
  if (raw == null) return null;
  if (raw.startsWith('http')) return raw;
  try {
    return await FirebaseService.instance.getDownloadUrl(raw);
  } catch (_) {
    return null;
  }
}

class FinishedPage extends StatefulWidget {
  const FinishedPage({super.key, required this.books});
  final List<BookEntry> books;

  @override
  State<FinishedPage> createState() => _FinishedPageState();
}

class _FinishedPageState extends State<FinishedPage> {
  bool _loading = true;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  void _safeBack() {
    if (_navigating) return;
    _navigating = true;
    Future.delayed(const Duration(milliseconds: 700), () {
      _navigating = false;
      if (mounted) context.pop();
    });
  }

  Widget _buildLoader() {
    return Scaffold(
      backgroundColor: HandiTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 88,
              color: HandiTheme.success.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 36),
            const CircularProgressIndicator(
              color: HandiTheme.success,
              strokeWidth: 3,
            ),
            const SizedBox(height: 28),
            const Text(
              'Chargement des livres terminés…',
              style: TextStyle(
                fontSize: 22,
                color: HandiTheme.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoader();

    return HandiScaffold(
      title: 'Livres terminés',
      onBack: _safeBack,
      backTooltip: 'Bibliothèque',
      body: ListView.builder(
        itemCount: widget.books.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _FinishedTile(book: widget.books[i]),
        ),
      ),
    );
  }
}

class _FinishedTile extends StatefulWidget {
  const _FinishedTile({required this.book});
  final BookEntry book;

  @override
  State<_FinishedTile> createState() => _FinishedTileState();
}

class _FinishedTileState extends State<_FinishedTile> {
  DateTime? _lastTap;

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTap != null &&
        now.difference(_lastTap!) < const Duration(milliseconds: 800)) {
      return;
    }
    _lastTap = now;
    StorageService.instance.saveLastOpenedBook(widget.book.id);
    context.push('/lecture/epub/${widget.book.id}', extra: widget.book);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HandiTheme.borderRadius)),
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bande verte gauche
                Container(width: 6, color: HandiTheme.success),
                // Contenu
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        FutureBuilder<String?>(
                          future: _resolveCoverUrl(widget.book.coverUrl),
                          builder: (_, snap) {
                            final url = snap.data;
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: url != null
                                  ? Image.network(url,
                                      width: 70,
                                      height: 98,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _colorCover())
                                  : _colorCover(),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(widget.book.title,
                                  style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold)),
                              if (widget.book.author.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(widget.book.author,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        color: HandiTheme.textSecondary)),
                              ],
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: HandiTheme.success, size: 24),
                                  SizedBox(width: 6),
                                  Text('Terminé',
                                      style: TextStyle(
                                          color: HandiTheme.success,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 36, color: HandiTheme.textSecondary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _colorCover() => Container(
        width: 70,
        height: 98,
        color: Color(widget.book.coverColor),
        child: const Icon(Icons.menu_book, color: Colors.white, size: 36),
      );
}
