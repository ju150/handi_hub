import 'dart:async';

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

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key, required this.books});
  final List<BookEntry> books;

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  // Délai anti-chevauchement : bloque les taps 800ms après ouverture
  bool _interactable = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _interactable = true);
    });
  }

  void _openBook(BuildContext ctx, BookEntry book) {
    Navigator.of(ctx, rootNavigator: true).pop(); // ferme dialog si ouvert
    StorageService.instance.saveLastOpenedBook(book.id);
    context.push('/lecture/epub/${book.id}', extra: book);
  }

  void _showBookCard(BookEntry book) {
    if (!_interactable) return;
    final size = MediaQuery.of(context).size;
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HandiTheme.borderRadius)),
        child: SizedBox(
          width: size.width - 32,
          height: size.height * 0.80,
          child: Column(
            children: [
              // ── Header coloré ───────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: HandiTheme.warning,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(HandiTheme.borderRadius)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        book.title,
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 32),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),

              // ── Corps scrollable ─────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Couverture + auteur
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<String?>(
                            future: _resolveCoverUrl(book.coverUrl),
                            builder: (_, snap) {
                              final url = snap.data;
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: url != null
                                    ? Image.network(url,
                                        width: 100,
                                        height: 140,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _colorCover(book, 100, 140))
                                    : _colorCover(book, 100, 140),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          if (book.author.isNotEmpty)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  book.author,
                                  style: const TextStyle(
                                      fontSize: 24,
                                      color: HandiTheme.textSecondary,
                                      fontStyle: FontStyle.italic),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Résumé complet
                      if (book.summary != null) ...[
                        const Text('Résumé',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: HandiTheme.primary)),
                        const SizedBox(height: 10),
                        Text(
                          book.summary!,
                          style: const TextStyle(
                              fontSize: 24, height: 1.6),
                        ),
                      ] else
                        const Text('Aucun résumé disponible.',
                            style: TextStyle(
                                fontSize: 24, color: HandiTheme.textSecondary)),
                    ],
                  ),
                ),
              ),

              // ── Bouton Commencer ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: HandiTheme.warning,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(HandiTheme.borderRadius)),
                      textStyle: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 36),
                    label: const Text('Commencer la lecture'),
                    onPressed: () => _openBook(ctx, book),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HandiScaffold(
      title: 'Découvrir',
      leading: IconButton(
        iconSize: 48,
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Bibliothèque',
        onPressed: () => context.pop(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête coloré
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: HandiTheme.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
              border: Border.all(
                  color: HandiTheme.warning.withValues(alpha: 0.4),
                  width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.explore_rounded,
                    color: HandiTheme.warning, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${widget.books.length} livre${widget.books.length > 1 ? 's' : ''} à découvrir — appuie pour voir le résumé',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: HandiTheme.warning),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Liste
          Expanded(
            child: ListView.builder(
              itemCount: widget.books.length,
              itemBuilder: (_, i) {
                final book = widget.books[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DiscoverTile(
                    book: book,
                    interactable: _interactable,
                    onTap: () => _showBookCard(book),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorCover(BookEntry book, double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Color(book.coverColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.menu_book, color: Colors.white, size: 48),
      );
}

// ── Tuile liste ──────────────────────────────────────────────────────────────

class _DiscoverTile extends StatefulWidget {
  const _DiscoverTile({
    required this.book,
    required this.interactable,
    required this.onTap,
  });
  final BookEntry book;
  final bool interactable;
  final VoidCallback onTap;

  @override
  State<_DiscoverTile> createState() => _DiscoverTileState();
}

class _DiscoverTileState extends State<_DiscoverTile> {
  DateTime? _lastTap;

  void _handleTap() {
    if (!widget.interactable) return;
    final now = DateTime.now();
    if (_lastTap != null &&
        now.difference(_lastTap!) < const Duration(milliseconds: 800)) return;
    _lastTap = now;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
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
                // Bande orange gauche
                Container(width: 6, color: HandiTheme.warning),
                // Contenu
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Couverture
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
                        // Titre + auteur + badge
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
                              const SizedBox(height: 10),
                              // Badge "Voir le résumé"
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: HandiTheme.warning
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: HandiTheme.warning
                                          .withValues(alpha: 0.5)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.info_outline,
                                        size: 22,
                                        color: HandiTheme.warning),
                                    SizedBox(width: 6),
                                    Text('Voir résumé & commencer',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: HandiTheme.warning)),
                                  ],
                                ),
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
        decoration: BoxDecoration(
          color: Color(widget.book.coverColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.menu_book, color: Colors.white, size: 36),
      );
}
