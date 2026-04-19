import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/games_data.dart';
import '../../services/games_storage_service.dart';
import '../../theme/games_theme.dart';

/// Page de jeu "Touche la Cible".
///
/// Des cibles colorées apparaissent aléatoirement. L'utilisatrice les touche
/// pour marquer des points avant qu'elles ne disparaissent.
class ToucheCiblePlayPage extends StatefulWidget {
  const ToucheCiblePlayPage({super.key, required this.level});

  /// Index 0-based du niveau sélectionné.
  final int level;

  @override
  State<ToucheCiblePlayPage> createState() => _ToucheCiblePlayPageState();
}

class _ToucheCiblePlayPageState extends State<ToucheCiblePlayPage>
    with TickerProviderStateMixin {
  // ─── Config ───────────────────────────────────────────────────────────────
  late final Map<String, dynamic> _cfg;
  late final int    _gameDuration;
  late final double _targetSize;
  late final int    _targetDuration; // secondes avant disparition
  late final int    _maxTargets;

  // ─── État ─────────────────────────────────────────────────────────────────
  int  _score    = 0;
  int  _timeLeft = 0;
  bool _started  = false;
  bool _over     = false;

  final _rand    = Random();
  final _targets = <_TargetData>[];
  int  _nextId   = 0;

  Timer? _gameTimer;
  final _targetTimers = <int, Timer>{};

  // ─── Taille de l'aire de jeu (fournie par LayoutBuilder) ─────────────────
  double _areaW = 600;
  double _areaH = 400;

  @override
  void initState() {
    super.initState();
    _cfg           = toucheCibleLevelConfig[widget.level.clamp(0, 2)];
    _gameDuration  = _cfg['gameDuration']  as int;
    _targetSize    = _cfg['targetSize']    as double;
    _targetDuration = _cfg['targetDuration'] as int;
    _maxTargets    = _cfg['maxTargets']    as int;
    _timeLeft      = _gameDuration;

    // Démarre après un court délai (compte à rebours visuel)
    Future.delayed(const Duration(milliseconds: 800), _startGame);
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    for (final t in _targetTimers.values) { t.cancel(); }
    super.dispose();
  }

  // ─── Logique ──────────────────────────────────────────────────────────────

  void _startGame() {
    if (!mounted) return;
    setState(() => _started = true);

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) _endGame();
      });
    });

    _spawnIfNeeded();
  }

  void _spawnIfNeeded() {
    if (!_started || _over) return;
    while (_targets.length < _maxTargets) {
      _spawnTarget();
    }
  }

  void _spawnTarget() {
    final margin = _targetSize / 2 + 8;
    final x = margin + _rand.nextDouble() * (_areaW - _targetSize - margin * 2);
    final y = margin + _rand.nextDouble() * (_areaH - _targetSize - margin * 2);

    final color = GamesTheme
        .targetColors[_rand.nextInt(GamesTheme.targetColors.length)];
    final id = _nextId++;

    setState(() {
      _targets.add(_TargetData(id: id, x: x, y: y, color: color));
    });

    _targetTimers[id] = Timer(Duration(seconds: _targetDuration), () {
      _removeTarget(id, scored: false);
    });
  }

  void _onTargetTapped(int id) {
    _targetTimers[id]?.cancel();
    _targetTimers.remove(id);
    _removeTarget(id, scored: true);
    setState(() => _score++);
    _spawnIfNeeded();
  }

  void _removeTarget(int id, {required bool scored}) {
    if (!mounted) return;
    setState(() => _targets.removeWhere((t) => t.id == id));
    if (!scored && !_over) {
      // Délai avant réapparition quand on rate
      Future.delayed(const Duration(milliseconds: 400), _spawnIfNeeded);
    }
  }

  Future<void> _endGame() async {
    _gameTimer?.cancel();
    for (final t in _targetTimers.values) { t.cancel(); }
    _targetTimers.clear();

    await GamesStorageService.instance.updateScore(
      gameId: 'touche-cible',
      score:  _score,
      level:  widget.level + 1,
    );

    if (!mounted) return;
    setState(() => _over = true);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            // ── HUD ────────────────────────────────────────────────────────
            _Hud(
              score:    _score,
              timeLeft: _timeLeft,
              total:    _gameDuration,
              onQuit:   () => context.go('/games/touche-cible'),
            ),

            // ── Zone de jeu ────────────────────────────────────────────────
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _areaW = constraints.maxWidth;
                  _areaH = constraints.maxHeight;

                  if (_over) {
                    return _GameOverOverlay(
                      score:   _score,
                      level:   widget.level,
                      onRetry: () => context.go(
                          '/games/touche-cible/play?level=${widget.level}'),
                      onHome:  () => context.go('/games/touche-cible'),
                    );
                  }

                  if (!_started) {
                    return const Center(
                      child: Text(
                        'Prête ?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  return Stack(
                    children: _targets
                        .map((t) => Positioned(
                              left: t.x,
                              top:  t.y,
                              child: _TargetWidget(
                                key:      ValueKey(t.id),
                                data:     t,
                                size:     _targetSize,
                                duration: _targetDuration,
                                onTap:    () => _onTargetTapped(t.id),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Modèle cible ─────────────────────────────────────────────────────────────

class _TargetData {
  final int   id;
  final double x, y;
  final Color color;
  _TargetData({
    required this.id,
    required this.x,
    required this.y,
    required this.color,
  });
}

// ─── Widget cible ─────────────────────────────────────────────────────────────

class _TargetWidget extends StatefulWidget {
  const _TargetWidget({
    super.key,
    required this.data,
    required this.size,
    required this.duration,
    required this.onTap,
  });

  final _TargetData  data;
  final double       size;
  final int          duration; // secondes
  final VoidCallback onTap;

  @override
  State<_TargetWidget> createState() => _TargetWidgetState();
}

class _TargetWidgetState extends State<_TargetWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Animation de rétrécissement : montre visuellement le temps restant
    _controller = AnimationController(
      vsync:    this,
      duration: Duration(seconds: widget.duration),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.data.color;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final scale = 1.0 - _controller.value * 0.35;
          return Transform.scale(
            scale: scale,
            child: Container(
              width:  widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color:      color.withValues(alpha: 0.6),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_circle_outline_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── HUD ──────────────────────────────────────────────────────────────────────

class _Hud extends StatelessWidget {
  const _Hud({
    required this.score,
    required this.timeLeft,
    required this.total,
    required this.onQuit,
  });

  final int          score, timeLeft, total;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final pct = timeLeft / total;
    final barColor = pct > 0.4
        ? const Color(0xFF43A047)
        : pct > 0.2
            ? const Color(0xFFFB8C00)
            : const Color(0xFFE53935);

    return Container(
      height: 72,
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Quitter
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

          // Timer
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⏱ $timeLeft s',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD600),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '🎯 $score',
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

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.score,
    required this.level,
    required this.onRetry,
    required this.onHome,
  });

  final int          score, level;
  final VoidCallback onRetry, onHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F3A),
          borderRadius: BorderRadius.circular(GamesTheme.cardRadius),
          border: Border.all(
            color: GamesTheme.toucheCibleColor,
            width: 3,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⏱️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text(
              'Temps écoulé !',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD600),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '🎯 $score cibles touchées',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 28),
            _BigButton(
              label: 'Rejouer',
              icon:  Icons.replay_rounded,
              color: GamesTheme.toucheCibleColor,
              onTap: onRetry,
            ),
            const SizedBox(height: 14),
            _BigButton(
              label: 'Retour',
              icon:  Icons.arrow_back_rounded,
              color: const Color(0xFF455A64),
              onTap: onHome,
            ),
          ],
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
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
