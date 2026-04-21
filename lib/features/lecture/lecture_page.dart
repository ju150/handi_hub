import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import 'services/firebase_service.dart';
import 'services/storage_service.dart';
import '../../core/widgets/handi_scaffold.dart';
import 'models/lecture_data.dart';

/// Résout l'URL de couverture quelle que soit sa forme :
/// - URL https directe (ex: image hébergée ailleurs) → utilisée telle quelle
/// - Chemin Firebase Storage (ex: "covers/livre.jpg") → on demande l'URL signée
///
/// Retourne null si [raw] est null ou si Firebase échoue (pas de réseau, etc.)
/// → dans ce cas la couverture de couleur [BookEntry.coverColor] est affichée.
Future<String?> _resolveCoverUrl(String? raw) async {
  if (raw == null) return null;
  if (raw.startsWith('http')) return raw;
  try {
    return await FirebaseService.instance.getDownloadUrl(raw);
  } catch (_) {
    return null;
  }
}

class LecturePage extends StatefulWidget {
  const LecturePage({super.key});

  @override
  State<LecturePage> createState() => _LecturePageState();
}

class _LecturePageState extends State<LecturePage> {
  List<BookEntry> _books = [];
  bool _loading = true;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    // Durée minimale d'affichage du loader (évite le flash de contenu
    // si Firebase répond en moins de 900 ms) — même constante que Kiné.
    final minDelay = Future<void>.delayed(const Duration(milliseconds: 900));
    final books = await FirebaseService.instance.fetchBooks();
    await minDelay;
    if (!mounted) return;
    setState(() {
      _books = books;
      _loading = false;
    });
  }

  void _safeBack() {
    if (_navigating) return;
    _navigating = true;
    Future.delayed(const Duration(milliseconds: 700), () {
      _navigating = false;
      if (mounted) context.go('/');
    });
  }

  /// Répartit les livres en 4 catégories calculées en temps réel depuis
  /// SharedPreferences (pas de state supplémentaire nécessaire).
  ///
  /// Règles de catégorisation :
  ///   - [termines]   : isFinished == true
  ///   - [enCours]    : position sauvegardée > 0 ET pas terminé
  ///   - [aDecouvrir] : pas de position sauvegardée ET pas terminé
  ///   - [featured]   : livre "en cours" ouvert en dernier (via lastOpenedBook),
  ///                    affiché en grand (style Netflix). Fallback = premier en cours.
  ({
    BookEntry? featured,
    List<BookEntry> enCours,
    List<BookEntry> aDecouvrir,
    List<BookEntry> termines,
  }) get _sections {
    final lastId = StorageService.instance.getLastOpenedBook();

    final termines =
        _books.where((b) => StorageService.instance.isFinished(b.id)).toList();
    final enCours = _books
        .where((b) =>
            !StorageService.instance.isFinished(b.id) &&
            StorageService.instance.getEpubPosition(b.id) != null)
        .toList();
    final aDecouvrir = _books
        .where((b) =>
            !StorageService.instance.isFinished(b.id) &&
            StorageService.instance.getEpubPosition(b.id) == null)
        .toList();

    BookEntry? featured;
    if (enCours.isNotEmpty) {
      featured = enCours.firstWhere(
        (b) => b.id == lastId,
        orElse: () => enCours.first,
      );
    }
    final enCoursSans =
        enCours.where((b) => b.id != featured?.id).toList();

    return (
      featured: featured,
      enCours: enCoursSans,
      aDecouvrir: aDecouvrir,
      termines: termines,
    );
  }

  void _openBook(BookEntry book) {
    // Mémoriser quel livre est ouvert → détermine le "featured" au prochain retour.
    // context.push (pas go) : empile la page, le retour revient ici.
    StorageService.instance.saveLastOpenedBook(book.id);
    context.push('/lecture/epub/${book.id}', extra: book);
  }

  @override
  Widget build(BuildContext context) {
    // Loader plein-écran (style Kiné) pendant la récupération Firebase.
    if (_loading) return _buildLoader();

    return HandiScaffold(
      title: 'Bibliothèque',
      onBack: _safeBack,
      backTooltip: 'Accueil',
      body: _buildBody(),
    );
  }

  Widget _buildLoader() {
    return Scaffold(
      backgroundColor: HandiTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              size: 88,
              color: HandiTheme.primary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 36),
            const CircularProgressIndicator(
              color: HandiTheme.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 28),
            const Text(
              'Chargement de la bibliothèque…',
              style: TextStyle(
                fontSize: 22,
                color: HandiTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {

    if (_books.isEmpty) {
      return Center(
        child: Text(
          FirebaseService.isInitialized
              ? 'Aucun livre disponible pour le moment.'
              : 'Connexion requise pour accéder aux livres.',
          style: const TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
      );
    }

    final s = _sections;

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              if (s.featured != null) ...[
                _sectionLabel('Reprendre la lecture'),
                _FeaturedCard(
                    book: s.featured!, onTap: () => _openBook(s.featured!)),
                const SizedBox(height: 16),
              ],
              if (s.enCours.isNotEmpty) ...[
                _sectionLabel('Aussi en cours'),
                ...s.enCours.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SmallBookTile(
                          book: b, onTap: () => _openBook(b)),
                    )),
                const SizedBox(height: 8),
              ],
              if (s.featured == null && s.enCours.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.auto_stories_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text('Aucune lecture en cours.',
                            style:
                                TextStyle(fontSize: 20, color: Colors.grey)),
                        const SizedBox(height: 8),
                        const Text(
                            'Appuyez sur Découvrir pour commencer !',
                            style:
                                TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Barre de navigation bas ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              Expanded(
                child: _NavButton(
                  icon: Icons.check_circle_outline,
                  label: 'Déjà lus',
                  count: s.termines.length,
                  activeColor: HandiTheme.success,
                  onTap: s.termines.isEmpty
                      ? null
                      : () => context.push('/lecture/termines',
                          extra: s.termines),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NavButton(
                  icon: Icons.explore_outlined,
                  label: 'Découvrir',
                  count: s.aDecouvrir.length,
                  activeColor: HandiTheme.warning,
                  onTap: s.aDecouvrir.isEmpty
                      ? null
                      : () => context.push('/lecture/decouvrir',
                          extra: s.aDecouvrir),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: HandiTheme.primary)),
      );
}

// ── Grande carte livre vedette ───────────────────────────────────────────────

class _FeaturedCard extends StatefulWidget {
  const _FeaturedCard({required this.book, required this.onTap});
  final BookEntry book;
  final VoidCallback onTap;

  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard> {
  DateTime? _lastTap;

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTap != null &&
        now.difference(_lastTap!) < const Duration(milliseconds: 800)) return;
    _lastTap = now;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
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
                // Bande accent gauche
                Container(width: 8, color: HandiTheme.accent),
                // Contenu
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
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
                                      width: 90,
                                      height: 125,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _colorCover(90, 125))
                                  : _colorCover(90, 125),
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        // Infos
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.book.title,
                                  style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold)),
                              if (widget.book.author.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(widget.book.author,
                                    style: const TextStyle(
                                        fontSize: 22,
                                        color: HandiTheme.textSecondary)),
                              ],
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: HandiTheme.primary,
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 14),
                                  textStyle: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.play_arrow_rounded,
                                    size: 26),
                                label: const Text('Reprendre'),
                                onPressed: _handleTap,
                              ),
                            ],
                          ),
                        ),
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

  Widget _colorCover(double w, double h) => Container(
        width: w,
        height: h,
        color: Color(widget.book.coverColor),
        child: const Icon(Icons.menu_book, color: Colors.white, size: 36),
      );
}

// ── Petite tuile (en cours secondaires) ─────────────────────────────────────

class _SmallBookTile extends StatefulWidget {
  const _SmallBookTile({required this.book, required this.onTap});
  final BookEntry book;
  final VoidCallback onTap;

  @override
  State<_SmallBookTile> createState() => _SmallBookTileState();
}

class _SmallBookTileState extends State<_SmallBookTile> {
  DateTime? _lastTap;

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTap != null &&
        now.difference(_lastTap!) < const Duration(milliseconds: 800)) return;
    _lastTap = now;
    widget.onTap();
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
                // Bande primaire gauche
                Container(width: 5, color: HandiTheme.primary),
                // Contenu
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        FutureBuilder<String?>(
                          future: _resolveCoverUrl(widget.book.coverUrl),
                          builder: (_, snap) {
                            final url = snap.data;
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: url != null
                                  ? Image.network(url,
                                      width: 52,
                                      height: 72,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _colorCover())
                                  : _colorCover(),
                            );
                          },
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.book.title,
                                  style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold)),
                              if (widget.book.author.isNotEmpty)
                                Text(widget.book.author,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        color: HandiTheme.textSecondary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 32, color: HandiTheme.textSecondary),
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
        width: 52,
        height: 72,
        color: Color(widget.book.coverColor),
        child: const Icon(Icons.menu_book, color: Colors.white, size: 28),
      );
}

// ── Bouton navigation bas ────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
    required this.activeColor,
  });

  final IconData icon;
  final String label;
  final int count;
  final VoidCallback? onTap;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? activeColor : Colors.grey.shade300,
      borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 32,
                  color: enabled ? Colors.white : Colors.grey.shade500),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color:
                          enabled ? Colors.white : Colors.grey.shade500)),
              if (count > 0)
                Text('$count livre${count > 1 ? 's' : ''}',
                    style: TextStyle(
                        fontSize: 18,
                        color: enabled
                            ? Colors.white70
                            : Colors.grey.shade400)),
            ],
          ),
        ),
      ),
    );
  }
}
