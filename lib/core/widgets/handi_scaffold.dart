import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

/// Scaffold commun : bouton Home à droite (grand), barre de protection en bas.
class HandiScaffold extends StatelessWidget {
  const HandiScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showHomeButton = true,
    this.actions,
  });

  final String title;
  final Widget body;
  final bool showHomeButton;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Text(title),
        automaticallyImplyLeading: false,
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
      // Barre de protection : empêche les taps accidentels sur les boutons Android
      bottomNavigationBar: Container(
        height: 112,
        color: HandiTheme.primary,
        child: const Center(
          child: Icon(Icons.drag_handle, color: Colors.white54, size: 28),
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
