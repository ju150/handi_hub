import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/handi_scaffold.dart';
import 'data/games_data.dart';
import 'services/games_storage_service.dart';
import 'theme/games_theme.dart';

/// Affiche le meilleur score et la progression pour chaque jeu interne.
class GamesScoresPage extends StatelessWidget {
  const GamesScoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storage    = GamesStorageService.instance;
    final innerGames = allGames.where((g) => g.id != 'briser-mots').toList();

    return HandiScaffold(
      title: '🏆 Meilleurs Scores',
      onBack: () => context.go('/games'),
      body: ColoredBox(
        color: GamesTheme.background,
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: innerGames.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, i) {
            final game  = innerGames[i];
            final score = storage.getScore(game.id);
            return _ScoreRow(
              icon:        game.icon,
              color:       game.color,
              title:       game.title,
              scoreUnit:   game.scoreUnit,
              bestScore:   score.bestScore,
              gamesPlayed: score.gamesPlayed,
              lastPlayed:  score.lastPlayed,
            );
          },
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.scoreUnit,
    required this.bestScore,
    required this.gamesPlayed,
    required this.lastPlayed,
  });

  final IconData  icon;
  final Color     color;
  final String    title;
  final String    scoreUnit;
  final int       bestScore;
  final int       gamesPlayed;
  final DateTime? lastPlayed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(GamesTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône colorée
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 18),

          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: GamesTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _Stat('🏆', 'Record', '$bestScore $scoreUnit'),
                    _Stat('🎮', 'Parties', '$gamesPlayed'),
                  ],
                ),
                if (lastPlayed != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Dernière partie : ${_formatDate(lastPlayed!)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: GamesTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.emoji, this.label, this.value);
  final String emoji, label, value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$emoji $label : $value',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: GamesTheme.textPrimary,
        ),
      ),
    );
  }
}
