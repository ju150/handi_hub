import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/handi_scaffold.dart';
import 'data/games_data.dart';
import 'models/game_entry.dart';
import 'services/external_game_launcher.dart';
import 'services/games_storage_service.dart';
import 'theme/games_theme.dart';

/// Liste les jeux marqués favoris par l'utilisatrice.
class GamesFavorisPage extends StatefulWidget {
  const GamesFavorisPage({super.key});

  @override
  State<GamesFavorisPage> createState() => _GamesFavorisPageState();
}

class _GamesFavorisPageState extends State<GamesFavorisPage> {
  final _storage = GamesStorageService.instance;

  List<GameEntry> get _favorites {
    final favIds = _storage.getFavorites();
    return allGames.where((g) => favIds.contains(g.id)).toList();
  }

  void _openGame(BuildContext context, GameEntry game) {
    switch (game.id) {
      case 'briser-mots':  ExternalGameLauncher.launchBriserDesMots();
      case 'touche-cible': context.go('/games/touche-cible');
      case 'memory':       context.go('/games/memory');
      case 'color-match':  context.go('/games/color-match');
    }
  }

  Future<void> _removeFavorite(GameEntry game) async {
    await _storage.toggleFavorite(game.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final favs = _favorites;

    return HandiScaffold(
      title: '❤️ Mes Favoris',
      onBack: () => context.go('/games'),
      body: ColoredBox(
        color: GamesTheme.background,
        child: favs.isEmpty
            ? const _EmptyFavoris()
            : ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: favs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final game = favs[i];
                  return _FavRow(
                    game:          game,
                    onPlay:        () => _openGame(context, game),
                    onRemove:      () => _removeFavorite(game),
                  );
                },
              ),
      ),
    );
  }
}

class _FavRow extends StatelessWidget {
  const _FavRow({
    required this.game,
    required this.onPlay,
    required this.onRemove,
  });

  final GameEntry    game;
  final VoidCallback onPlay;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPlay,
      child: Container(
        height: 90,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(GamesTheme.cardRadius),
          boxShadow: [
            BoxShadow(
              color: game.color.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: game.color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(game.icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: GamesTheme.textPrimary,
                    ),
                  ),
                  Text(
                    game.shortDescription,
                    style: const TextStyle(
                      fontSize: 15,
                      color: GamesTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Bouton retirer favori
            GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFE53935),
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: GamesTheme.textSecondary,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFavoris extends StatelessWidget {
  const _EmptyFavoris();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('💔', style: TextStyle(fontSize: 64)),
          SizedBox(height: 20),
          Text(
            'Aucun favori pour l\'instant',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: GamesTheme.textPrimary,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Appuie sur ❤️ dans un jeu\npour l\'ajouter ici.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: GamesTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
