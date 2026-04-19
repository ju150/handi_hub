import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/games_data.dart';
import '../../services/games_storage_service.dart';
import '../../theme/games_theme.dart';

/// Page de jeu Memory.
///
/// Grille de cartes face cachée. L'utilisatrice touche deux cartes :
/// si elles sont identiques, elles restent face visible.
/// Si non, elles se retournent après un court délai.
class MemoryPlayPage extends StatefulWidget {
  const MemoryPlayPage({super.key, required this.level});
  final int level;

  @override
  State<MemoryPlayPage> createState() => _MemoryPlayPageState();
}

class _MemoryPlayPageState extends State<MemoryPlayPage> {
  // ─── Config ───────────────────────────────────────────────────────────────
  late final int    _cols, _pairs;
  late final List<String> _symbols;

  // ─── Cartes ───────────────────────────────────────────────────────────────
  late final List<_CardData> _cards;

  // ─── État ─────────────────────────────────────────────────────────────────
  _CardData? _firstFlipped;
  bool _checking = false;  // lock pendant la vérification
  int  _moves    = 0;
  int  _matched  = 0;
  bool _won      = false;

  @override
  void initState() {
    super.initState();
    final cfg  = memoryLevelConfig[widget.level.clamp(0, 2)];
    _cols  = cfg['cols']  as int;
    _pairs = cfg['pairs'] as int;

    final symbolSet = cfg['symbolSet'] as int;
    _symbols = memorySymbolSets[symbolSet].take(_pairs).toList();

    _buildCards();
  }

  void _buildCards() {
    final rng  = Random();
    final pool = [..._symbols, ..._symbols]..shuffle(rng);
    _cards = List.generate(
      pool.length,
      (i) => _CardData(id: i, symbol: pool[i]),
    );
  }

  // ─── Logique ──────────────────────────────────────────────────────────────

  void _onCardTap(_CardData card) {
    if (_checking) return;
    if (card.isMatched) return;
    if (card.isFlipped) return;
    if (_firstFlipped != null && _firstFlipped!.id == card.id) return;

    setState(() => card.isFlipped = true);
    _moves++;

    if (_firstFlipped == null) {
      _firstFlipped = card;
    } else {
      _checking = true;
      final first = _firstFlipped!;
      _firstFlipped = null;

      if (first.symbol == card.symbol) {
        // Paire trouvée
        Future.delayed(GamesTheme.feedbackDelay, () {
          if (!mounted) return;
          setState(() {
            first.isMatched = true;
            card.isMatched  = true;
            _matched++;
            _checking = false;
            if (_matched == _pairs) _onWin();
          });
        });
      } else {
        // Pas de correspondance → retourner après délai
        Future.delayed(
          const Duration(milliseconds: 1100),
          () {
            if (!mounted) return;
            setState(() {
              first.isFlipped = false;
              card.isFlipped  = false;
              _checking = false;
            });
          },
        );
      }
    }
  }

  Future<void> _onWin() async {
    await GamesStorageService.instance.updateScore(
      gameId: 'memory',
      score:  _pairs,
      level:  widget.level + 1,
    );
    if (!mounted) return;
    setState(() => _won = true);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B4B),
      body: SafeArea(
        child: Column(
          children: [
            // ── HUD ───────────────────────────────────────────────────────
            _MemoryHud(
              matched: _matched,
              pairs:   _pairs,
              moves:   _moves,
              onQuit:  () => context.go('/games/memory'),
            ),

            // ── Grille ────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _won
                    ? _WinOverlay(
                        pairs:   _pairs,
                        moves:   _moves,
                        level:   widget.level,
                        onRetry: () => context.go(
                            '/games/memory/play?level=${widget.level}'),
                        onHome:  () => context.go('/games/memory'),
                      )
                    : GridView.count(
                        crossAxisCount:   _cols,
                        crossAxisSpacing: 8,
                        mainAxisSpacing:  8,
                        children: _cards
                            .map((card) => _MemoryCard(
                                  card:  card,
                                  onTap: () => _onCardTap(card),
                                ))
                            .toList(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Modèle carte ─────────────────────────────────────────────────────────────

class _CardData {
  final int    id;
  final String symbol;
  bool isFlipped = false;
  bool isMatched = false;

  _CardData({required this.id, required this.symbol});
}

// ─── Widget carte ─────────────────────────────────────────────────────────────

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.card, required this.onTap});
  final _CardData    card;
  final VoidCallback onTap;

  // Couleur de fond quand la carte est retournée
  static const List<Color> _faceColors = [
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFF00695C),
    Color(0xFF827717),
    Color(0xFFBF360C),
    Color(0xFF37474F),
    Color(0xFF4527A0),
    Color(0xFF1B5E20),
  ];

  Color _faceColor() {
    final idx = card.id % 2 == 0
        ? card.id ~/ 2
        : (card.id - 1) ~/ 2;
    return _faceColors[idx % _faceColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final revealed = card.isFlipped || card.isMatched;

    return GestureDetector(
      onTap: revealed ? null : onTap,
      child: AnimatedSwitcher(
        duration: GamesTheme.flipDuration,
        transitionBuilder: (child, anim) => ScaleTransition(
          scale: anim,
          child: child,
        ),
        child: revealed
            ? _FaceFront(
                key:     ValueKey('front_${card.id}'),
                symbol:  card.symbol,
                color:   _faceColor(),
                matched: card.isMatched,
              )
            : _FaceBack(key: ValueKey('back_${card.id}')),
      ),
    );
  }
}

class _FaceBack extends StatelessWidget {
  const _FaceBack({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: const Center(
        child: Icon(Icons.question_mark_rounded,
            color: Colors.white54, size: 36),
      ),
    );
  }
}

class _FaceFront extends StatelessWidget {
  const _FaceFront({
    super.key,
    required this.symbol,
    required this.color,
    required this.matched,
  });

  final String symbol;
  final Color  color;
  final bool   matched;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: matched
            ? const Color(0xFF1B5E20)
            : color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: matched ? const Color(0xFF69F0AE) : Colors.white30,
          width: matched ? 3 : 2,
        ),
        boxShadow: matched
            ? [
                BoxShadow(
                  color: const Color(0xFF69F0AE).withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Center(
        child: Text(symbol, style: const TextStyle(fontSize: 40)),
      ),
    );
  }
}

// ─── HUD ──────────────────────────────────────────────────────────────────────

class _MemoryHud extends StatelessWidget {
  const _MemoryHud({
    required this.matched,
    required this.pairs,
    required this.moves,
    required this.onQuit,
  });

  final int          matched, pairs, moves;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
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

          // Progression
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$matched / $pairs paires trouvées',
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
                    value:           matched / pairs,
                    minHeight:       8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF69F0AE)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '✋ $moves',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Écran victoire ───────────────────────────────────────────────────────────

class _WinOverlay extends StatelessWidget {
  const _WinOverlay({
    required this.pairs,
    required this.moves,
    required this.level,
    required this.onRetry,
    required this.onHome,
  });

  final int          pairs, moves, level;
  final VoidCallback onRetry, onHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF0D2137),
          borderRadius: BorderRadius.circular(GamesTheme.cardRadius),
          border: Border.all(
            color: const Color(0xFF69F0AE),
            width: 3,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text(
              'Bravo !',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _StatRow('🃏 Paires trouvées', '$pairs / $pairs'),
            const SizedBox(height: 8),
            _StatRow('✋ Essais utilisés', '$moves'),
            const SizedBox(height: 28),
            _WinButton(
              label: 'Rejouer',
              icon:  Icons.replay_rounded,
              color: GamesTheme.memoryColor,
              onTap: onRetry,
            ),
            const SizedBox(height: 14),
            _WinButton(
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

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 17)),
        Text(value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            )),
      ],
    );
  }
}

class _WinButton extends StatelessWidget {
  const _WinButton({
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
