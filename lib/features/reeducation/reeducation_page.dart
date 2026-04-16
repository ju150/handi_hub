import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/widgets/handi_scaffold.dart';

/// Hub principal du module Rééducation.
///
/// Présente les 4 sous-modules actifs sous forme de grandes tuiles colorées
/// qui remplissent tout l'écran (grille 2×2).
///
/// Navigation entrante : /reeducation
/// Navigation sortante : /reeducation/kine | /reeducation/respiration | etc.
class ReeducationPage extends StatelessWidget {
  const ReeducationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HandiScaffold(
      title: 'Rééducation',
      onBack: () => context.go('/'),
      backTooltip: 'Retour à l\'accueil',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Texte d'introduction ───────────────────────────────────────────
          const Text(
            'Choisissez un module de rééducation.',
            style: TextStyle(
              fontSize: 20,
              color: Color(0xFF555555),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // ── Grille 2×2 — 4 modules actifs, remplit tout l'espace ──────────
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                _SubModuleTile(
                  label: 'Kiné',
                  icon: Icons.accessibility_new_rounded,
                  color: Color(0xFF00796B),
                  route: '/reeducation/kine',
                  available: true,
                ),
                _SubModuleTile(
                  label: 'Respiration',
                  icon: Icons.air_rounded,
                  color: Color(0xFF1565C0),
                  route: '/reeducation/respiration',
                  available: true,
                ),
                _SubModuleTile(
                  label: 'Orthophonie',
                  icon: Icons.record_voice_over_rounded,
                  color: Color(0xFF6A1B9A),
                  route: '/reeducation/orthophonie',
                  available: true,
                ),
                _SubModuleTile(
                  label: 'Relaxation',
                  icon: Icons.spa_rounded,
                  color: Color(0xFF2E7D32),
                  route: '/reeducation/relaxation',
                  available: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tuile de sous-module dans la grille de [ReeducationPage].
class _SubModuleTile extends StatelessWidget {
  const _SubModuleTile({
    required this.label,
    required this.icon,
    required this.color,
    this.route,
    this.available = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String? route;
  final bool available;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
      ),
      child: InkWell(
        onTap: available && route != null ? () => context.go(route!) : null,
        borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
          child: Container(
            color: color,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: HandiTheme.iconSize, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: HandiTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
