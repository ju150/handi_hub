import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/handi_scaffold.dart';
import '../../services/games_storage_service.dart';
import '../../theme/games_theme.dart';
import '../../widgets/game_home_widgets.dart';

/// Page d'accueil du jeu Memory — présentation + bouton Jouer.
class MemoryHomePage extends StatelessWidget {
  const MemoryHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final score = GamesStorageService.instance.getScore('memory');

    return HandiScaffold(
      title: '🃏 Memory',
      onBack: () => context.go('/games'),
      body: ColoredBox(
        color: GamesTheme.background,
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GameHomeHeader(
                color:      GamesTheme.memoryColor,
                lightColor: GamesTheme.memoryLight,
                icon:       Icons.grid_view_rounded,
                bestScore:  score.bestScore,
                played:     score.gamesPlayed,
                scoreUnit:  'paires',
                emptyText:  'Retrouve toutes les paires !',
              ),
              const SizedBox(height: 28),
              const GameRuleCard(rules: [
                ('🃏', 'Des cartes sont posées face cachée sur la table'),
                ('👆', 'Touche une carte pour la retourner'),
                ('🔍', 'Retrouve la carte identique parmi les autres'),
                ('✅', 'Quand tu trouves une paire, elle reste visible'),
                ('🏆', 'Gagne quand toutes les paires sont trouvées'),
              ]),
              const SizedBox(height: 28),
              GamePlayButton(
                color: GamesTheme.memoryColor,
                onTap: () => context.go('/games/memory/play?level=0'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
