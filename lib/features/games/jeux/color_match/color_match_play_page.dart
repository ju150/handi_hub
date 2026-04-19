import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/games_data.dart';
import '../../services/games_storage_service.dart';
import '../../theme/games_theme.dart';

/// Page de jeu Match Coloré — adaptation accessible de Candy Crush.
///
/// Mécanique : l'utilisatrice touche une case pour sélectionner tout le groupe
/// de cases adjacentes de même couleur (flood-fill), puis appuie sur
/// "Exploser !" pour détruire ce groupe. Les cases du dessus tombent, de
/// nouvelles cases apparaissent en haut. Pas de glisser-déposer.
class ColorMatchPlayPage extends StatefulWidget {
  const ColorMatchPlayPage({super.key, required this.level});
  final int level;

  @override
  State<ColorMatchPlayPage> createState() => _ColorMatchPlayPageState();
}

class _ColorMatchPlayPageState extends State<ColorMatchPlayPage> {
  // ─── Config ───────────────────────────────────────────────────────────────
  late final int   _cols, _rows, _numColors, _targetScore;

  // ─── Grille : -1 = vide, 0..numColors-1 = couleur ────────────────────────
  late List<List<int>> _grid;

  // ─── État ─────────────────────────────────────────────────────────────────
  int          _score       = 0;
  Set<int>     _selected    = {};   // encodé row*100+col
  bool         _exploding   = false;
  bool         _won         = false;
  bool         _lost        = false; // plus aucun groupe ≥ 2

  final _rng = Random();

  @override
  void initState() {
    super.initState();
    final cfg   = colorMatchLevelConfig[widget.level.clamp(0, 2)];
    _cols       = cfg['cols']       as int;
    _rows       = cfg['rows']       as int;
    _numColors  = cfg['numColors']  as int;
    _targetScore = cfg['targetScore'] as int;
    _initGrid();
  }

  // ─── Grille ───────────────────────────────────────────────────────────────

  void _initGrid() {
    _grid = List.generate(
      _rows,
      (_) => List.generate(_cols, (_) => _rng.nextInt(_numColors)),
    );
  }

  // Flood-fill DFS : renvoie l'ensemble des positions du groupe connexe.
  Set<int> _findGroup(int row, int col) {
    final target  = _grid[row][col];
    if (target == -1) return {};

    final visited = <int>{};
    final stack   = [row * 100 + col];

    while (stack.isNotEmpty) {
      final key = stack.removeLast();
      if (visited.contains(key)) continue;
      final r = key ~/ 100;
      final c = key % 100;
      if (r < 0 || r >= _rows || c < 0 || c >= _cols) continue;
      if (_grid[r][c] != target) continue;
      visited.add(key);
      stack
        ..add((r - 1) * 100 + c)
        ..add((r + 1) * 100 + c)
        ..add(r * 100 + (c - 1))
        ..add(r * 100 + (c + 1));
    }
    return visited;
  }

  // Collapse : après explosion, les cases tombent vers le bas dans chaque colonne.
  void _collapse() {
    for (int c = 0; c < _cols; c++) {
      final nonEmpty = <int>[];
      for (int r = _rows - 1; r >= 0; r--) {
        if (_grid[r][c] != -1) nonEmpty.add(_grid[r][c]);
      }
      for (int r = _rows - 1; r >= 0; r--) {
        final idx = _rows - 1 - r;
        _grid[r][c] = idx < nonEmpty.length
            ? nonEmpty[idx]
            : _rng.nextInt(_numColors); // nouvelles cases en haut
      }
    }
  }

  bool _hasPlayableGroup() {
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        if (_findGroup(r, c).length >= 2) return true;
      }
    }
    return false;
  }

  // ─── Interactions ─────────────────────────────────────────────────────────

  void _onCellTap(int row, int col) {
    if (_exploding || _won || _lost) return;

    final group = _findGroup(row, col);
    if (group.length < 2) {
      // Groupe de 1 — désélectionner
      setState(() => _selected = {});
      return;
    }
    setState(() => _selected = group);
  }

  Future<void> _onExplode() async {
    if (_selected.isEmpty || _exploding) return;

    setState(() => _exploding = true);

    final pts = _selected.length * _selected.length; // points quadratiques

    // Marquer les cases comme vides
    for (final key in _selected) {
      _grid[key ~/ 100][key % 100] = -1;
    }

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    _collapse();
    final newScore = _score + pts;

    setState(() {
      _score     = newScore;
      _selected  = {};
      _exploding = false;

      if (_score >= _targetScore) {
        _won = true;
        _saveScore();
      } else if (!_hasPlayableGroup()) {
        _lost = true;
        _saveScore();
      }
    });
  }

  Future<void> _saveScore() async {
    await GamesStorageService.instance.updateScore(
      gameId: 'color-match',
      score:  _score,
      level:  widget.level + 1,
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2744),
      body: SafeArea(
        child: Column(
          children: [
            // ── HUD ───────────────────────────────────────────────────────
            _ColorMatchHud(
              score:       _score,
              targetScore: _targetScore,
              onQuit:      () => context.go('/games/color-match'),
            ),

            // ── Grille ────────────────────────────────────────────────────
            Expanded(
              child: (_won || _lost)
                  ? _EndOverlay(
                      won:    _won,
                      score:  _score,
                      target: _targetScore,
                      level:  widget.level,
                      onRetry: () => context.go(
                          '/games/color-match/play?level=${widget.level}'),
                      onHome: () => context.go('/games/color-match'),
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final cellSize = min(
                            (constraints.maxWidth - (_cols - 1) * 4) / _cols,
                            (constraints.maxHeight - (_rows - 1) * 4 - 84) /
                                _rows,
                          );
                          return Column(
                            children: [
                              // Grille
                              Expanded(
                                child: _buildGrid(cellSize),
                              ),
                              // Bouton Exploser
                              _ExplodeButton(
                                enabled:    _selected.length >= 2 && !_exploding,
                                groupSize:  _selected.length,
                                onExplode:  _onExplode,
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(double cellSize) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   _cols,
        crossAxisSpacing: 4,
        mainAxisSpacing:  4,
      ),
      itemCount: _rows * _cols,
      itemBuilder: (_, idx) {
        final r     = idx ~/ _cols;
        final c     = idx % _cols;
        final color = _grid[r][c];
        final key   = r * 100 + c;
        final isSel = _selected.contains(key);

        return _GridCell(
          colorIndex: color,
          isSelected: isSel,
          exploding:  _exploding && isSel,
          onTap:      () => _onCellTap(r, c),
        );
      },
    );
  }
}

// ─── Cellule ──────────────────────────────────────────────────────────────────

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.colorIndex,
    required this.isSelected,
    required this.exploding,
    required this.onTap,
  });

  final int          colorIndex;
  final bool         isSelected, exploding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final baseColor = colorIndex == -1
        ? Colors.transparent
        : GamesTheme.candyColors[
            colorIndex.clamp(0, GamesTheme.candyColors.length - 1)];

    return GestureDetector(
      onTap: colorIndex == -1 ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: exploding
              ? Colors.white
              : isSelected
                  ? Colors.white
                  : baseColor,
          borderRadius: BorderRadius.circular(10),
          border: isSelected && !exploding
              ? Border.all(color: Colors.white, width: 3)
              : null,
          boxShadow: isSelected && !exploding
              ? [
                  BoxShadow(
                    color:      Colors.white.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: isSelected && !exploding
            ? Center(
                child: Container(
                  width:  18,
                  height: 18,
                  decoration: BoxDecoration(
                    color:  baseColor,
                    shape:  BoxShape.circle,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

// ─── Bouton Exploser ──────────────────────────────────────────────────────────

class _ExplodeButton extends StatelessWidget {
  const _ExplodeButton({
    required this.enabled,
    required this.groupSize,
    required this.onExplode,
  });

  final bool         enabled;
  final int          groupSize;
  final VoidCallback onExplode;

  @override
  Widget build(BuildContext context) {
    final pts = groupSize * groupSize;

    return GestureDetector(
      onTap: enabled ? onExplode : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 72,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFFFF6F00)
              : Colors.grey.shade700,
          borderRadius: BorderRadius.circular(GamesTheme.cardRadius),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color:      const Color(0xFFFF6F00).withValues(alpha: 0.5),
                    blurRadius: 14,
                    offset:     const Offset(0, 5),
                  )
                ]
              : [],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💥', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Text(
                enabled
                    ? 'Exploser !  +$pts pts  ($groupSize cases)'
                    : 'Touche un groupe',
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── HUD ──────────────────────────────────────────────────────────────────────

class _ColorMatchHud extends StatelessWidget {
  const _ColorMatchHud({
    required this.score,
    required this.targetScore,
    required this.onQuit,
  });

  final int          score, targetScore;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final pct = (score / targetScore).clamp(0.0, 1.0);

    return Container(
      height: 72,
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: onQuit,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$score / $targetScore pts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value:           pct,
                    minHeight:       8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFFFD600)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD600),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '🎨 $score',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Écran de fin ─────────────────────────────────────────────────────────────

class _EndOverlay extends StatelessWidget {
  const _EndOverlay({
    required this.won,
    required this.score,
    required this.target,
    required this.level,
    required this.onRetry,
    required this.onHome,
  });

  final bool         won;
  final int          score, target, level;
  final VoidCallback onRetry, onHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B3E),
          borderRadius: BorderRadius.circular(GamesTheme.cardRadius),
          border: Border.all(
            color: won
                ? const Color(0xFFFFD600)
                : const Color(0xFFE53935),
            width: 3,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              won ? '🎉' : '😅',
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 12),
            Text(
              won ? 'Objectif atteint !' : 'Plus de groupes disponibles',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: won
                    ? const Color(0xFFFFD600)
                    : Colors.white12,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '$score pts  (objectif : $target)',
                style: TextStyle(
                  color: won ? Colors.black87 : Colors.white70,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 28),
            _EndButton(
              label: 'Rejouer',
              icon:  Icons.replay_rounded,
              color: GamesTheme.colorMatchColor,
              onTap: onRetry,
            ),
            const SizedBox(height: 14),
            _EndButton(
              label: 'Retour',
              icon:  Icons.arrow_back_rounded,
              color: const Color(0xFF37474F),
              onTap: onHome,
            ),
          ],
        ),
      ),
    );
  }
}

class _EndButton extends StatelessWidget {
  const _EndButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String       label;
  final IconData     icon;
  final Color        color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: GamesTheme.buttonHeight,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(GamesTheme.cardRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
