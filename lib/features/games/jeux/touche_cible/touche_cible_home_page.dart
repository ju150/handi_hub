import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/handi_scaffold.dart';
import '../../services/games_storage_service.dart';
import '../../theme/games_theme.dart';
import '../../widgets/game_home_widgets.dart';

/// Page d'accueil de "Touche la Cible" — présentation + bouton Jouer.
class ToucheCibleHomePage extends StatelessWidget {
  const ToucheCibleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final score = GamesStorageService.instance.getScore('touche-cible');

    return HandiScaffold(
      title: '🎯 Touche la Cible',
      onBack: () => context.go('/games'),
      body: ColoredBox(
        color: GamesTheme.background,
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GameHomeHeader(
                color:      GamesTheme.toucheCibleColor,
                lightColor: GamesTheme.toucheCibleLight,
                icon:       Icons.my_location_rounded,
                bestScore:  score.bestScore,
                played:     score.gamesPlayed,
                scoreUnit:  'cibles',
                emptyText:  'Aucune partie jouée — lance-toi !',
              ),
              const SizedBox(height: 28),
              const GameRuleCard(rules: [
                ('🎯', 'Des cibles colorées apparaissent à l\'écran'),
                ('👆', 'Touche-les avant qu\'elles ne disparaissent'),
                ('⏱️', 'Tu as 60 secondes — marque le plus de points possible'),
                ('💡', 'Plus tu touches vite, mieux c\'est !'),
              ]),
              const SizedBox(height: 28),
              GamePlayButton(
                color: GamesTheme.toucheCibleColor,
                onTap: () => context.go('/games/touche-cible/play?level=0'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
