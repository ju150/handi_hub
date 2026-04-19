import 'package:flutter/material.dart';
import '../theme/games_theme.dart';

/// En-tête gradient réutilisable pour les pages d'accueil de chaque jeu.
class GameHomeHeader extends StatelessWidget {
  const GameHomeHeader({
    super.key,
    required this.color,
    required this.lightColor,
    required this.icon,
    required this.bestScore,
    required this.played,
    required this.scoreUnit,
    required this.emptyText,
  });

  final Color    color, lightColor;
  final IconData icon;
  final int      bestScore, played;
  final String   scoreUnit;
  final String   emptyText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, lightColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(GamesTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 48),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bestScore > 0)
                  _HeaderChip('🏆 Record : $bestScore $scoreUnit'),
                if (played > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _HeaderChip(
                      '🎮 $played partie${played > 1 ? 's' : ''} jouée${played > 1 ? 's' : ''}',
                    ),
                  ),
                if (bestScore == 0)
                  Text(
                    emptyText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Carte de règles réutilisable pour les pages d'accueil de chaque jeu.
class GameRuleCard extends StatelessWidget {
  const GameRuleCard({super.key, required this.rules});
  final List<(String, String)> rules;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(GamesTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: rules
            .map(
              (r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.$1, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        r.$2,
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.4,
                          color: GamesTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Bouton principal "Jouer" réutilisable pour les pages d'accueil.
class GamePlayButton extends StatelessWidget {
  const GamePlayButton({
    super.key,
    required this.color,
    required this.onTap,
    this.label = 'Jouer',
  });

  final Color        color;
  final VoidCallback onTap;
  final String       label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: GamesTheme.buttonHeight,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(GamesTheme.cardRadius),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.40),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
