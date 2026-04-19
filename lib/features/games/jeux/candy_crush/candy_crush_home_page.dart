import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/handi_scaffold.dart';
import '../../services/games_storage_service.dart';
import '../../theme/games_theme.dart';
import '../../widgets/game_home_widgets.dart';

/// Page d'accueil de "Candy Crush adapté" — présentation + bouton Jouer.
class CandyCrushHomePage extends StatelessWidget {
  const CandyCrushHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final score = GamesStorageService.instance.getScore('candy-crush');

    return HandiScaffold(
      title: '🍬 Candy Crush adapté',
      onBack: () => context.go('/games'),
      body: ColoredBox(
        color: GamesTheme.background,
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GameHomeHeader(
                color:      GamesTheme.candyCrushColor,
                lightColor: GamesTheme.candyCrushLight,
                icon:       Icons.diamond_rounded,
                bestScore:  score.bestScore,
                played:     score.gamesPlayed,
                scoreUnit:  'pts',
                emptyText:  'Aligne les bonbons et explose-les !',
              ),
              const SizedBox(height: 28),
              const GameRuleCard(rules: [
                ('🍬', 'Touche une case pour la sélectionner'),
                ('🔄', 'Touche une case adjacente pour choisir l\'échange'),
                ('✅', 'Appuie sur "Valider" pour effectuer l\'échange'),
                ('💥', 'Si 3 bonbons ou plus s\'alignent, ils explosent !'),
                ('⭐', 'Marque le plus de points possible'),
              ]),
              const SizedBox(height: 28),
              GamePlayButton(
                color: GamesTheme.candyCrushColor,
                onTap: () => context.go('/games/candy-crush/play'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
