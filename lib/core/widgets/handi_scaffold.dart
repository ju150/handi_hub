import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

/// Scaffold commun avec AppBar et bouton Home permanent.
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
        title: Text(title),
        leading: showHomeButton
            ? IconButton(
                icon: const Icon(Icons.home, size: 32),
                tooltip: 'Accueil',
                onPressed: () => context.go('/'),
              )
            : null,
        actions: actions,
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
