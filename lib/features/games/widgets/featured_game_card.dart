import 'package:flutter/material.dart';
import '../models/game_entry.dart';
import '../theme/games_theme.dart';

/// Grande carte mise en avant pour "Briser des Mots".
/// Occupe toute la largeur, hauteur fixe, très lisible au stylet.
class FeaturedGameCard extends StatelessWidget {
  const FeaturedGameCard({
    super.key,
    required this.game,
    required this.onTap,
  });

  final GameEntry    game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 190,
        decoration: GamesTheme.featuredCardDecoration(game.color, game.lightColor),
        child: Stack(
          children: [
            // ── Cercles décoratifs ─────────────────────────────────────────
            Positioned(
              right: -25,
              top: -25,
              child: _circle(200, 0.08),
            ),
            Positioned(
              right: 40,
              bottom: -50,
              child: _circle(150, 0.06),
            ),

            // ── Contenu ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  _IconBadge(game: game),
                  const SizedBox(width: 22),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _MainChip(),
                        const SizedBox(height: 6),
                        Text(
                          game.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          game.shortDescription,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _PlayChip(color: game.color),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.game});
  final GameEntry game;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.20),
      ),
      child: Icon(game.icon, color: Colors.white, size: 52),
    );
  }
}

class _MainChip extends StatelessWidget {
  const _MainChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD600),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '⭐  Jeu principal',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PlayChip extends StatelessWidget {
  const _PlayChip({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        'Jouer maintenant  →',
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
