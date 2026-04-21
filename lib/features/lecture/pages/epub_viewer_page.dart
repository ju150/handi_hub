import 'dart:async';

import 'package:epub_view/epub_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../services/epub_cache_service.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../../../core/widgets/handi_scaffold.dart';
import '../models/lecture_data.dart';

class EpubViewerPage extends StatefulWidget {
  const EpubViewerPage({super.key, required this.book});
  final BookEntry book;

  @override
  State<EpubViewerPage> createState() => _EpubViewerPageState();
}

class _EpubViewerPageState extends State<EpubViewerPage> {
  EpubController? _controller;
  bool _loading = true;
  String? _error;

  /// Taille de police chargée depuis SharedPreferences au démarrage.
  /// Sauvegardée immédiatement à chaque changement dans le popup paramètres.
  late double _fontSize;

  /// Verrou anti-écrasement de position.
  ///
  /// Problème : epub_view fire le listener [_savePosition] dès que le widget
  /// est construit, avec l'index 0. Si on a une position sauvegardée (ex: 42),
  /// on appelle jumpTo(42), mais pendant les ~1 seconde que prend le saut,
  /// le listener peut sauvegarder 0 et écraser la vraie position.
  ///
  /// Solution : [_readyToSave] reste false pendant le saut initial.
  /// Il passe à true seulement après que epub_view a eu le temps de sauter.
  bool _readyToSave = false;

  /// Verrou anti-double-appui sur le bouton retour.
  bool _navigating = false;

  /// Timer du défilement press-and-hold (null quand inactif).
  Timer? _scrollTimer;

  // ── Constantes de défilement ──────────────────────────────────────────────
  //
  // Approche : chaque pas déplace le contenu d'une fraction fixe de la hauteur
  // du viewport, indépendamment de la longueur des paragraphes.
  //
  // Pourquoi cela fixe le scroll "paragraphe-dépendant" :
  //   Avant : scrollTo(index+1) → si le paragraphe est court : petit saut ;
  //           si le paragraphe est long : grand saut (expérience chaotique).
  //   Après : scrollTo(index, alignment: leadingEdge - step) → déplacement
  //           toujours égal à [_kScrollStep] * hauteur_viewport. La longueur
  //           du paragraphe n'influe plus sur la vitesse visuelle perçue.
  //
  // Ajuster [_kScrollStep] pour régler la vitesse (plus grand = plus rapide).
  static const double _kScrollStep = 0.10; // 10 % du viewport par pas
  static const int _kScrollIntervalMs = 450; // intervalle entre deux pas
  static const int _kScrollAnimMs = 400; // durée d'animation par pas

  @override
  void initState() {
    super.initState();
    _fontSize = StorageService.instance.getEpubFontSize();
    _loadEpub();
  }

  // ── Chargement ────────────────────────────────────────────────────────────

  Future<void> _loadEpub() async {
    try {
      // 1. Obtenir l'URL signée depuis Firebase Storage
      final url =
          await FirebaseService.instance.getDownloadUrl(widget.book.storageRef);

      // 2. Télécharger le fichier EPUB (ou récupérer le cache local)
      final file =
          await EpubCacheService.instance.getOrDownload(widget.book.id, url);

      // 3. Créer le contrôleur epub_view
      _controller = EpubController(document: EpubDocument.openFile(file));

      // 4. S'abonner aux changements de position pour sauvegarder en continu
      _controller!.currentValueListenable.addListener(_savePosition);

      if (mounted) {
        setState(() => _loading = false);

        // 5. Restaurer la position sauvegardée
        final savedIndex =
            StorageService.instance.getEpubPosition(widget.book.id);

        if (savedIndex != null && savedIndex > 0) {
          // Attendre que epub_view ait fini de parser le document ET de monter
          // la ScrollablePositionedList avant d'appeler jumpTo().
          //
          // Problème avec un délai fixe : si le parsing dépasse 600 ms,
          // ItemScrollController._scrollableListState est encore null → exception.
          //
          // Solution : écouter isBookLoaded (mis à true par epub_view après
          // _init() complet), puis attendre 300 ms supplémentaires pour que
          // le premier build() de la liste soit terminé.
          void restoreWhenReady() {
            if (!(_controller?.isBookLoaded.value ?? false)) return;
            _controller!.isBookLoaded.removeListener(restoreWhenReady);
            Future.delayed(const Duration(milliseconds: 300), () {
              if (!mounted) return;
              _controller!.jumpTo(index: savedIndex);
              // 800 ms de grâce avant d'autoriser les sauvegardes, pour que
              // le jump soit effectué et que le listener ne voie pas index=0.
              Future.delayed(const Duration(milliseconds: 800), () {
                if (mounted) _readyToSave = true;
              });
            });
          }

          if (_controller!.isBookLoaded.value) {
            restoreWhenReady();
          } else {
            _controller!.isBookLoaded.addListener(restoreWhenReady);
          }
        } else {
          // Pas de position sauvegardée : autoriser après le premier rendu.
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) _readyToSave = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  // ── Sauvegarde de position ────────────────────────────────────────────────

  void _savePosition() {
    if (!_readyToSave) return;

    final index = _controller?.currentValue?.position.index;

    // On ne sauvegarde pas l'index 0 : si jumpTo() échoue silencieusement
    // et que la vue reste au début, on ne veut pas écraser la vraie position.
    if (index != null && index > 0) {
      StorageService.instance.saveEpubPosition(widget.book.id, index);
    }
  }

  // ── Navigation retour ─────────────────────────────────────────────────────

  void _safeBack() {
    if (_navigating) return;
    _navigating = true;
    // Délai anti-double-appui stylet (même valeur que le module Kiné).
    Future.delayed(const Duration(milliseconds: 700), () {
      _navigating = false;
      if (mounted) context.pop();
    });
  }

  // ── Défilement press-and-hold ─────────────────────────────────────────────
  //
  // Comportement voulu : appuyer → scroll continu lent ; relever le stylet → arrêt.
  //
  // Choix technique : [Listener] plutôt que [GestureDetector].
  // GestureDetector.onLongPress a un délai de ~500ms avant de se déclencher.
  // Listener.onPointerDown se déclenche immédiatement au contact.
  //
  // Rythme : 1 pas immédiatement + 1 pas toutes les [_kScrollIntervalMs] ms.
  // Chaque pas = [_kScrollStep] fraction de la hauteur du viewport.

  void _startScroll(int delta) {
    _scrollTimer?.cancel();
    _doScroll(delta); // déclenchement immédiat au premier contact
    _scrollTimer = Timer.periodic(
      const Duration(milliseconds: _kScrollIntervalMs),
      (_) => _doScroll(delta),
    );
  }

  void _doScroll(int delta) {
    final pos = _controller?.currentValue?.position;
    if (pos == null || !mounted) return;

    // Décalage d'alignement constant : déplace le contenu de [_kScrollStep]
    // fraction de la hauteur du viewport à chaque pas.
    // L'alignement représente la position du bord supérieur du paragraphe
    // ancre dans le viewport (0 = haut, négatif = au-dessus du viewport).
    // En soustrayant [step], on demande au paragraphe de remonter davantage,
    // ce qui défile le contenu vers le bas (et inversement pour la montée).
    final newAlignment = pos.itemLeadingEdge - delta * _kScrollStep;

    _controller!.scrollTo(
      index: pos.index,
      alignment: newAlignment,
      duration: const Duration(milliseconds: _kScrollAnimMs),
      curve: Curves.easeOut,
    );
  }

  void _stopScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
  }

  // ── Statut terminé ────────────────────────────────────────────────────────

  Future<void> _markFinished() async {
    await StorageService.instance.markFinished(widget.book.id);
    if (mounted) setState(() {});
  }

  Future<void> _unmarkFinished() async {
    await StorageService.instance.unmarkFinished(widget.book.id);
    if (mounted) setState(() {});
  }

  // ── Popup paramètres ──────────────────────────────────────────────────────
  //
  // Choix : Dialog avec [StatefulBuilder] plutôt qu'un StatefulWidget séparé.
  //
  // StatefulBuilder donne accès à deux setState :
  //   - [setState] (parent) : met à jour EpubView visible derrière le dialog
  //     → l'utilisatrice voit le texte changer en temps réel
  //   - [setDlg] (dialog) : met à jour l'affichage "22 pt" dans le dialog
  //
  // barrierColor transparent (black26) : on voit le livre derrière, ce qui
  // permet de juger l'effet de la taille de police sans fermer le dialog.

  void _showSettings() {
    _stopScroll(); // stopper le scroll avant d'ouvrir les paramètres
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final isFinished =
              StorageService.instance.isFinished(widget.book.id);
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Paramètres de lecture',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),

                  // ── Taille du texte ──────────────────────────────────
                  const Text('Taille du texte',
                      style: TextStyle(
                          fontSize: 18, color: HandiTheme.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _SettingsButton(
                        icon: Icons.text_decrease,
                        label: 'A−',
                        enabled: _fontSize > 14,
                        onTap: () {
                          setState(() => _fontSize -= 2); // rebuild EpubView
                          StorageService.instance.saveEpubFontSize(_fontSize);
                          setDlg(() {}); // rebuild dialog (compteur "22 pt")
                        },
                      ),
                      const SizedBox(width: 16),
                      Text('${_fontSize.toInt()} pt',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      _SettingsButton(
                        icon: Icons.text_increase,
                        label: 'A+',
                        enabled: _fontSize < 36,
                        onTap: () {
                          setState(() => _fontSize += 2);
                          StorageService.instance.saveEpubFontSize(_fontSize);
                          setDlg(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Statut lecture ────────────────────────────────────
                  // Bouton togglable : vert si terminé, bleu sinon.
                  // Le label indique explicitement qu'on peut annuler
                  // pour éviter les missclicks.
                  const Text('Statut de lecture',
                      style: TextStyle(
                          fontSize: 18, color: HandiTheme.textSecondary)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: isFinished
                            ? HandiTheme.success
                            : HandiTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              HandiTheme.borderRadius),
                        ),
                      ),
                      icon: Icon(
                          isFinished
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          size: 28),
                      label: Text(isFinished
                          ? 'Terminé — appuyer pour annuler'
                          : 'Marquer comme terminé'),
                      onPressed: () async {
                        if (isFinished) {
                          await _unmarkFinished();
                        } else {
                          await _markFinished();
                        }
                        setDlg(() {}); // rafraîchir couleur + label du bouton
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Fermer',
                          style: TextStyle(fontSize: 20)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    // Sauvegarde finale avant fermeture (au cas où le listener ne se serait
    // pas déclenché depuis le dernier scroll)
    _savePosition();
    _controller?.currentValueListenable.removeListener(_savePosition);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Écran de chargement plein-écran (style module Kiné) pendant le
    // téléchargement/décompression du fichier EPUB.
    if (_loading) return _buildLoader();

    return HandiScaffold(
      title: widget.book.title,
      onBack: _safeBack,
      backTooltip: 'Bibliothèque',
      body: _buildBody(),
    );
  }

  // ── Loader kine-style ────────────────────────────────────────────────────

  Widget _buildLoader() {
    return Scaffold(
      backgroundColor: HandiTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 88,
              color: HandiTheme.primary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 36),
            const CircularProgressIndicator(
              color: HandiTheme.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Chargement de « ${widget.book.title} »…',
                style: const TextStyle(
                  fontSize: 22,
                  color: HandiTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Impossible de charger le livre.',
                style: TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }

    // Stack : le contenu EPUB en arrière-plan, la barre de contrôle par-dessus.
    // chapterPadding bas = 110px pour que le dernier paragraphe ne soit pas
    // caché sous la barre de contrôle.
    return Stack(
      children: [
        EpubView(
          controller: _controller!,
          onChapterChanged: (_) => _savePosition(),
          builders: EpubViewBuilders<DefaultBuilderOptions>(
            options: DefaultBuilderOptions(
              textStyle: TextStyle(fontSize: _fontSize, height: 1.6),
              chapterPadding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
              paragraphPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            ),
          ),
        ),

        // Barre de contrôle : ⚙️ Paramètres | ↑ Remonter | ↓ Descendre
        // Positionnée en bas, juste au-dessus de la zone de protection bleue
        // de HandiScaffold.
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.white.withValues(alpha: 0.95),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                _SettingsIconButton(onTap: _showSettings),
                const SizedBox(width: 10),
                Expanded(
                  child: _HoldScrollButton(
                    icon: Icons.keyboard_arrow_up_rounded,
                    label: 'Remonter',
                    onPressStart: () => _startScroll(-1),
                    onPressEnd: _stopScroll,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HoldScrollButton(
                    icon: Icons.keyboard_arrow_down_rounded,
                    label: 'Descendre',
                    onPressStart: () => _startScroll(1),
                    onPressEnd: _stopScroll,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Bouton press-and-hold ────────────────────────────────────────────────────
//
// Utilise [Listener] (couche bas niveau) plutôt que GestureDetector :
//   - onPointerDown  → départ immédiat au contact du stylet
//   - onPointerUp    → arrêt dès que le stylet se lève
//   - onPointerCancel → arrêt si le geste est annulé (scroll externe, etc.)
//
// AnimatedContainer donne un retour visuel instantané (assombrissement)
// pendant l'appui, ce qui confirme visuellement à l'utilisatrice que le
// bouton est actif.

class _HoldScrollButton extends StatefulWidget {
  const _HoldScrollButton({
    required this.icon,
    required this.label,
    required this.onPressStart,
    required this.onPressEnd,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;

  @override
  State<_HoldScrollButton> createState() => _HoldScrollButtonState();
}

class _HoldScrollButtonState extends State<_HoldScrollButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        HapticFeedback.lightImpact(); // retour haptique au contact
        setState(() => _pressed = true);
        widget.onPressStart();
      },
      onPointerUp: (_) {
        setState(() => _pressed = false);
        widget.onPressEnd();
      },
      onPointerCancel: (_) {
        setState(() => _pressed = false);
        widget.onPressEnd();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _pressed
              ? HandiTheme.primary.withValues(alpha: 0.75) // assombri = appuyé
              : HandiTheme.primary,
          borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: Colors.white, size: 36),
            const SizedBox(width: 8),
            Text(widget.label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ── Bouton ⚙️ (bas gauche) ───────────────────────────────────────────────────
//
// Volontairement plus petit que les boutons de scroll pour ne pas gêner,
// mais placé à gauche pour être accessible sans croiser la zone de texte.

class _SettingsIconButton extends StatelessWidget {
  const _SettingsIconButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Icon(Icons.settings_rounded,
              size: 36, color: HandiTheme.primary),
        ),
      ),
    );
  }
}

// ── Bouton A− / A+ dans le dialog ────────────────────────────────────────────

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? HandiTheme.primary : Colors.grey.shade300,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(icon,
                  color: enabled ? Colors.white : Colors.grey, size: 28),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: enabled ? Colors.white : Colors.grey,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
