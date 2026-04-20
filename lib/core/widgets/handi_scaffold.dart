import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

/// Scaffold commun à toutes les pages HandiHub.
///
/// Bouton Retour optionnel en bas à gauche dans la barre de protection :
/// zone accessible au stylet depuis une position assise en fauteuil.
/// Passer [onBack] pour l'activer ; [leading] reste disponible pour l'AppBar.
class HandiScaffold extends StatelessWidget {
  const HandiScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showHomeButton = true,
    this.actions,
    this.leading,
    this.onBack,
    this.backTooltip = 'Retour',
  });

  final String title;
  final Widget body;
  final bool showHomeButton;
  final List<Widget>? actions;

  /// Widget gauche de l'AppBar (rétro-compatibilité — préférer [onBack]).
  final Widget? leading;

  /// Si fourni, affiche un ← en bas à gauche dans la barre de protection.
  final VoidCallback? onBack;

  /// Tooltip du bouton retour.
  final String backTooltip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Text(title),
        automaticallyImplyLeading: false,
        leading: leading,
        actions: [
          ...?actions,
          if (showHomeButton)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                iconSize: 56,
                icon: const Icon(Icons.home_rounded),
                tooltip: 'Accueil',
                onPressed: () => context.go('/'),
              ),
            ),
        ],
      ),
      // ── Barre de protection bas ────────────────────────────────────────
      // 112dp : empêche les taps accidentels sur les boutons Android natifs.
      // Bouton Retour en bas à gauche quand [onBack] est fourni.
      bottomNavigationBar: Container(
        height: 112,
        color: HandiTheme.primary,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.drag_handle, color: Colors.white54, size: 28),
            if (onBack != null)
              Positioned(
                left: 4,
                child: IconButton(
                  iconSize: 52,
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  tooltip: backTooltip,
                  onPressed: onBack,
                ),
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(HandiTheme.padding),
          child: body,
        ),
      ),
    );
  }
}
