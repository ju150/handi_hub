import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'simple_catalog_service.dart';
import '../reeducation_ui_config.dart';

/// Page de session guidée générique pour Respiration, Relaxation et Orthophonie.
///
/// Toute la personnalisation par module est passée via les paramètres
/// du constructeur — il n'y a pas de logique dupliquée entre les 3 modules.
///
/// Navigation entrante  : /reeducation/{module}/session/:exerciseId
/// Navigation sortante  : [backRoute] (retour après fin ou abandon)
///
/// Protections anti-double-tap stylet :
///   - Écran de chargement au démarrage ([ReeducationUiConfig.exerciseLaunchLoaderMs]).
///   - Bouton "Suivant" alterne gauche/droite après chaque clic.
///   - Cooldown [ReeducationUiConfig.nextButtonCooldownMs] entre deux clics.
class SimpleSessionPage extends StatefulWidget {
  const SimpleSessionPage({
    super.key,
    required this.exerciseId,
    required this.service,
    required this.backRoute,
    required this.bgColor,
    this.endDialogTitle = 'Exercice terminé 🎉',
    this.endDialogBody,
  });

  /// ID de l'exercice à charger depuis [service].
  final String exerciseId;

  /// Service fournissant le catalogue du module (Respiration / Relaxation / Orthophonie).
  final SimpleCatalogService service;

  /// Route de retour après fin ou abandon (ex. '/reeducation/respiration').
  final String backRoute;

  /// Couleur de fond de la page session et du loader (propre à chaque module).
  final Color bgColor;

  /// Titre de la boîte de dialogue de fin (ex. 'Exercice terminé 🌿').
  final String endDialogTitle;

  /// Corps optionnel de la boîte de dialogue de fin.
  /// Si null, seul le titre de l'exercice est affiché.
  final String? endDialogBody;

  @override
  State<SimpleSessionPage> createState() => _SimpleSessionPageState();
}

class _SimpleSessionPageState extends State<SimpleSessionPage> {
  late final exercise = widget.service.findById(widget.exerciseId);

  int _stepIndex = 0;

  Timer? _timer;
  int _remainingSeconds = 0;
  int _stepStartSeconds = 0;

  // ── Protections anti-double-tap ───────────────────────────────────────────
  bool _loading = true;
  bool _nextCooldown = false;
  bool _buttonOnRight = true;

  /// Couleur principale de l'exercice (extraite de l'exercice lui-même).
  Color get _color => Color(exercise!.colorValue);

  @override
  void initState() {
    super.initState();

    if (exercise == null) {
      // Exercice introuvable → retour immédiat au hub du module.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(widget.backRoute);
      });
      return;
    }

    // Loader visible avant la première consigne.
    Future.delayed(
      const Duration(milliseconds: ReeducationUiConfig.exerciseLaunchLoaderMs),
      () {
        if (mounted) {
          setState(() => _loading = false);
          _startStep();
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startStep() {
    _timer?.cancel();
    if (exercise == null) return;

    final step = exercise!.steps[_stepIndex];

    if (step.durationSeconds != null && step.durationSeconds! > 0) {
      _stepStartSeconds = step.durationSeconds!;
      _remainingSeconds = step.durationSeconds!;

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            _remainingSeconds = 0;
            timer.cancel();
          }
        });
      });
    } else {
      _stepStartSeconds = 0;
      _remainingSeconds = 0;
    }
  }

  void _next() {
    if (exercise == null || _nextCooldown) return;

    setState(() {
      _nextCooldown = true;
      _buttonOnRight = !_buttonOnRight; // alterne gauche ↔ droite
    });
    Future.delayed(
      const Duration(milliseconds: ReeducationUiConfig.nextButtonCooldownMs),
      () { if (mounted) setState(() => _nextCooldown = false); },
    );

    _timer?.cancel();

    if (_stepIndex >= exercise!.steps.length - 1) {
      _showEndDialog();
    } else {
      setState(() => _stepIndex++);
      _startStep();
    }
  }

  void _showEndDialog() {
    final body = widget.endDialogBody != null
        ? 'Bravo ! Vous avez réalisé "${exercise!.title}" jusqu\'au bout.\n\n${widget.endDialogBody}'
        : 'Bravo ! Vous avez réalisé "${exercise!.title}" jusqu\'au bout.';

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          widget.endDialogTitle,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        content: Text(
          body,
          style: const TextStyle(fontSize: 18, height: 1.5),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(widget.backRoute);
            },
            style: FilledButton.styleFrom(
              backgroundColor: _color,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            child: const Text('Retour aux exercices'),
          ),
        ],
      ),
    );
  }

  void _askStop() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter l\'exercice ?',
            style: TextStyle(fontSize: 22)),
        content: const Text(
            'Votre progression dans cet exercice sera perdue.',
            style: TextStyle(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Continuer', style: TextStyle(fontSize: 18)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFBF360C)),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(widget.backRoute);
            },
            child: const Text('Quitter', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (exercise == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_loading) return _buildLoader();

    final step = exercise!.steps[_stepIndex];
    final isLastStep = _stepIndex == exercise!.steps.length - 1;
    final hasTimer = _stepStartSeconds > 0;
    final timerDone = hasTimer && _remainingSeconds == 0;
    final globalProgress = (_stepIndex + 1) / exercise!.steps.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askStop();
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 80,
          backgroundColor: _color,
          foregroundColor: Colors.white,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Text(
            exercise!.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              iconSize: 44,
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Arrêter l\'exercice',
              onPressed: _askStop,
            ),
          ],
        ),

        bottomNavigationBar: Container(
          height: 112,
          color: _color,
          child: const Center(
            child: Icon(Icons.drag_handle, color: Colors.white54, size: 28),
          ),
        ),

        backgroundColor: widget.bgColor,

        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Progression ──────────────────────────────────────────────
                Row(
                  children: [
                    Text(
                      'Étape ${_stepIndex + 1} / ${exercise!.steps.length}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _color,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      exercise!.emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: globalProgress,
                    minHeight: 8,
                    backgroundColor: _color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(_color),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Carte de consigne ─────────────────────────────────────────
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _color.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          step.instruction,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                            height: 1.5,
                          ),
                        ),

                        if (hasTimer) ...[
                          const SizedBox(height: 28),
                          Text(
                            timerDone ? '✓ Terminé' : '$_remainingSeconds s',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: timerDone ? Colors.green : _color,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: _stepStartSeconds > 0
                                  ? _remainingSeconds / _stepStartSeconds
                                  : 0,
                              minHeight: 12,
                              backgroundColor: const Color(0xFFE0E0E0),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                timerDone ? Colors.green : _color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Bouton Suivant / Terminer — alternance gauche / droite ─────
                LayoutBuilder(
                  builder: (context, constraints) {
                    final btnWidth = constraints.maxWidth * 0.62;
                    return AnimatedAlign(
                      alignment: _buttonOnRight
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: SizedBox(
                        width: btnWidth,
                        height: 100,
                        child: FilledButton.icon(
                          onPressed: _nextCooldown ? null : _next,
                          icon: Icon(
                            isLastStep
                                ? Icons.check_circle_rounded
                                : Icons.arrow_forward_rounded,
                            size: 34,
                          ),
                          label: Text(
                            isLastStep ? 'Terminer' : 'Suivant',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: isLastStep
                                ? Colors.green.shade700
                                : _color,
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoader() {
    final color = Color(exercise!.colorValue);
    return Scaffold(
      backgroundColor: widget.bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(exercise!.emoji, style: const TextStyle(fontSize: 88)),
            const SizedBox(height: 36),
            CircularProgressIndicator(color: color, strokeWidth: 3),
            const SizedBox(height: 28),
            Text(
              exercise!.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Préparez-vous…',
              style: TextStyle(fontSize: 18, color: Color(0xFF888888)),
            ),
          ],
        ),
      ),
    );
  }
}
