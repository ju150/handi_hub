import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/handi_scaffold.dart';
import 'data/games_data.dart';
import 'services/external_game_launcher.dart';
import 'theme/games_theme.dart';
import 'widgets/featured_game_card.dart';
import 'widgets/game_card.dart';

/// Page d'accueil du module Jeux.
///
/// Structure :
///  1. Grande carte fixe "Briser des Mots"
///  2. Grille 2×2 pour les 4 jeux intégrés
class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final featured   = allGames[0];        // Briser des Mots
    final innerGames = allGames.sublist(1); // 4 jeux intégrés

    return HandiScaffold(
      title: '🎮 Jeux',
      onBack: () => context.go('/'),
      body: Container(
        color: GamesTheme.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Carte principale ─────────────────────────────────────────
            FeaturedGameCard(
              game:  featured,
              onTap: () async {
                try {
                  await ExternalGameLauncher.launchBriserDesMots();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Launch error: $e'),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
            ),

            const SizedBox(height: 20),

            // ── Section jeux ─────────────────────────────────────────────
            const _SectionLabel(label: 'Jeux'),
            const SizedBox(height: 10),

            // Grille 2×2 qui remplit l'espace restant sans scroll
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const cols    = 2;
                  const rows    = 2;
                  const spacing = GamesTheme.cardSpacing;
                  final itemW   = (constraints.maxWidth  - spacing) / cols;
                  final itemH   = (constraints.maxHeight - spacing) / rows;

                  return GridView.count(
                    crossAxisCount:   cols,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing:  spacing,
                    childAspectRatio: itemW / itemH,
                    physics: const NeverScrollableScrollPhysics(),
                    children: innerGames.map((game) {
                      return GameCard(
                        game:  game,
                        onTap: () => _openGame(context, game.id),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openGame(BuildContext context, String id) {
    switch (id) {
      case 'touche-cible':
        context.go('/games/touche-cible');
      case 'memory':
        context.go('/games/memory');
      case 'color-match':
        context.go('/games/color-match');
      case 'candy-crush':
        context.go('/games/candy-crush');
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: GamesTheme.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }
}
