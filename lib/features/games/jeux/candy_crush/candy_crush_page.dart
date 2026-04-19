import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/handi_scaffold.dart';
import '../../services/games_storage_service.dart';
import '../../theme/games_theme.dart';

class CandyCrushPage extends StatefulWidget {
  const CandyCrushPage({super.key});

  @override
  State<CandyCrushPage> createState() => _CandyCrushPageState();
}

class _CandyCrushPageState extends State<CandyCrushPage> {
  static const int _size = 4;
  // Réutilise la palette candy déjà définie dans GamesTheme (6 couleurs max)
  // On en prend 5 pour une grille 4x4 plus jouable
  static const List<Color> _colors = [
    Color(0xFFEF5350), // rouge
    Color(0xFFFDD835), // jaune
    Color(0xFF66BB6A), // vert
    Color(0xFF42A5F5), // bleu
    Color(0xFFCE93D8), // lilas
  ];

  late List<List<int>> _grid;
  int? _r1, _c1, _r2, _c2;
  int _score = 0;
  String? _message;

  @override
  void initState() {
    super.initState();
    _resetGrid();
  }

  // ── Initialisation ──────────────────────────────────────────────────────────

  void _resetGrid() {
    final rng = Random();
    _grid = List.generate(_size, (_) => List.generate(_size, (_) => rng.nextInt(_colors.length)));
    _removeInitialMatches();
    _r1 = _c1 = _r2 = _c2 = null;
    _score = 0;
    _message = null;
  }

  /// Sauvegarde le score courant puis réinitialise la partie.
  Future<void> _saveAndNewGame() async {
    if (_score > 0) {
      await GamesStorageService.instance.updateScore(
        gameId: 'candy-crush',
        score:  _score,
        level:  1,
      );
    }
    if (mounted) setState(_resetGrid);
  }

  /// Régénère les cases qui formeraient déjà un match au départ.
  void _removeInitialMatches() {
    final rng = Random();
    bool changed = true;
    while (changed) {
      changed = false;
      for (int r = 0; r < _size; r++) {
        for (int c = 0; c < _size; c++) {
          final v = _grid[r][c];
          if (c >= 2 && _grid[r][c - 1] == v && _grid[r][c - 2] == v) {
            _grid[r][c] = rng.nextInt(_colors.length);
            changed = true;
          } else if (r >= 2 && _grid[r - 1][c] == v && _grid[r - 2][c] == v) {
            _grid[r][c] = rng.nextInt(_colors.length);
            changed = true;
          }
        }
      }
    }
  }

  // ── Sélection ───────────────────────────────────────────────────────────────

  void _onTap(int row, int col) {
    setState(() {
      _message = null;

      if (_r1 == null) {
        // Première sélection
        _r1 = row; _c1 = col;
      } else if (row == _r1 && col == _c1) {
        // Désélectionner
        _r1 = _c1 = _r2 = _c2 = null;
      } else if (_r2 == null) {
        final dr = (row - _r1!).abs();
        final dc = (col - _c1!).abs();
        if (dr + dc == 1) {
          // Case adjacente → deuxième sélection valide
          _r2 = row; _c2 = col;
        } else {
          // Pas adjacent → nouvelle première sélection
          _r1 = row; _c1 = col;
        }
      } else if (row == _r2 && col == _c2) {
        // Désélectionner la deuxième
        _r2 = _c2 = null;
      } else {
        // Nouvelle sélection complète
        _r1 = row; _c1 = col;
        _r2 = _c2 = null;
      }
    });
  }

  bool get _canValidate => _r1 != null && _r2 != null;

  // ── Validation de l'échange ─────────────────────────────────────────────────

  void _validate() {
    if (!_canValidate) return;
    setState(() {
      _swap(_r1!, _c1!, _r2!, _c2!);
      final matched = _findMatches();

      if (matched.isEmpty) {
        _swap(_r1!, _c1!, _r2!, _c2!);
        _message = 'Aucune combinaison — échange annulé';
      } else {
        for (final (r, c) in matched) {
          _grid[r][c] = -1;
        }
        _applyGravity();
        _score += matched.length * 10;
        _message = '+${matched.length * 10} points !';
      }
      _r1 = _c1 = _r2 = _c2 = null;
    });
  }

  // ── Logique grille ──────────────────────────────────────────────────────────

  void _swap(int r1, int c1, int r2, int c2) {
    final tmp = _grid[r1][c1];
    _grid[r1][c1] = _grid[r2][c2];
    _grid[r2][c2] = tmp;
  }

  Set<(int, int)> _findMatches() {
    final matched = <(int, int)>{};

    // Horizontal
    for (int r = 0; r < _size; r++) {
      int run = 1;
      for (int c = 1; c < _size; c++) {
        if (_grid[r][c] == _grid[r][c - 1] && _grid[r][c] != -1) {
          run++;
        } else {
          if (run >= 3) {
            for (int k = c - run; k < c; k++) { matched.add((r, k)); }
          }
          run = 1;
        }
      }
      if (run >= 3) {
        for (int k = _size - run; k < _size; k++) { matched.add((r, k)); }
      }
    }

    // Vertical
    for (int c = 0; c < _size; c++) {
      int run = 1;
      for (int r = 1; r < _size; r++) {
        if (_grid[r][c] == _grid[r - 1][c] && _grid[r][c] != -1) {
          run++;
        } else {
          if (run >= 3) {
            for (int k = r - run; k < r; k++) { matched.add((k, c)); }
          }
          run = 1;
        }
      }
      if (run >= 3) {
        for (int k = _size - run; k < _size; k++) { matched.add((k, c)); }
      }
    }

    return matched;
  }

  /// Fait tomber les cases vers le bas et remplit le haut avec de nouvelles couleurs.
  void _applyGravity() {
    final rng = Random();
    for (int c = 0; c < _size; c++) {
      final remaining = [for (int r = 0; r < _size; r++) if (_grid[r][c] != -1) _grid[r][c]];
      final newCells = List.generate(_size - remaining.length, (_) => rng.nextInt(_colors.length));
      final newCol = [...newCells, ...remaining];
      for (int r = 0; r < _size; r++) {
        _grid[r][c] = newCol[r];
      }
    }
  }

  bool _isSelected(int r, int c) => (r == _r1 && c == _c1) || (r == _r2 && c == _c2);

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return HandiScaffold(
      title: '🍬 Candy Crush adapté',
      onBack: () => context.go('/games/candy-crush'),
      body: Container(
        color: GamesTheme.background,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          children: [
            // Score
            _ScoreBar(score: _score),
            const SizedBox(height: 12),

            // Feedback
            _FeedbackBanner(message: _message),
            const SizedBox(height: 12),

            // Grille
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final side = min(constraints.maxWidth, constraints.maxHeight);
                    const spacing = 10.0;
                    return SizedBox(
                      width: side,
                      height: side,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _size,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                        ),
                        itemCount: _size * _size,
                        itemBuilder: (_, idx) {
                          final r = idx ~/ _size;
                          final c = idx % _size;
                          return _Cell(
                            color: _grid[r][c] >= 0 ? _colors[_grid[r][c]] : Colors.grey.shade300,
                            selected: _isSelected(r, c),
                            onTap: () => _onTap(r, c),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bouton Valider
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _canValidate ? _validate : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GamesTheme.candyCrushColor,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Valider l\'échange',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _canValidate ? Colors.white : Colors.grey.shade500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Nouvelle partie
            TextButton(
              onPressed: _saveAndNewGame,
              child: const Text(
                'Nouvelle partie',
                style: TextStyle(fontSize: 16, color: GamesTheme.candyCrushColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets internes ──────────────────────────────────────────────────────────

class _Cell extends StatelessWidget {
  const _Cell({required this.color, required this.selected, required this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: selected ? Matrix4.diagonal3Values(0.88, 0.88, 1.0) : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: selected ? Border.all(color: Colors.white, width: 4) : null,
          boxShadow: [
            BoxShadow(
              color: selected ? Colors.black38 : Colors.black12,
              blurRadius: selected ? 10 : 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 30),
          const SizedBox(width: 10),
          Text(
            'Score : $score',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox(height: 34);
    final isError = message!.contains('Aucune');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: isError ? Colors.orange.shade100 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message!,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isError ? Colors.orange.shade900 : Colors.green.shade900,
        ),
      ),
    );
  }
}
