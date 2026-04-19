import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/handi_scaffold.dart';
import '../../services/games_storage_service.dart';
import '../../theme/games_theme.dart';
import '../../widgets/game_home_widgets.dart';

/// Page d'accueil du Match Coloré — présentation + bouton Jouer.
class ColorMatchHomePage extends StatelessWidget {
  const ColorMatchHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final score = GamesStorageService.instance.getScore('color-match');

    return HandiScaffold(
      title: '🎨 Match Coloré',
      onBack: () => context.go('/games'),
      body: ColoredBox(
        color: GamesTheme.background,
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GameHomeHeader(
                color:      GamesTheme.colorMatchColor,
                lightColor: GamesTheme.colorMatchLight,
                icon:       Icons.bubble_chart_rounded,
                bestScore:  score.bestScore,
                played:     score.gamesPlayed,
                scoreUnit:  'pts',
                emptyText:  'Explose les groupes de couleurs !',
              ),
              const SizedBox(height: 28),
              const GameRuleCard(rules: [
                ('👆', 'Touche une case pour sélectionner son groupe de couleur'),
                ('💥', 'Appuie sur "Exploser !" pour détruire le groupe sélectionné'),
                ('⬇️', 'Les cases du dessus tombent pour remplir les espaces vides'),
                ('🎯', 'Atteins le score cible pour gagner la partie'),
                ('📈', 'Plus le groupe est grand, plus tu marques de points !'),
              ]),
              const SizedBox(height: 28),
              GamePlayButton(
                color: GamesTheme.colorMatchColor,
                onTap: () => context.go('/games/color-match/play?level=0'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
