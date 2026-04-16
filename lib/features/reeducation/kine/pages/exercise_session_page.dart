import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../kine_models.dart';
import '../kine_catalog_service.dart';
import '../kine_theme.dart';
import '../../reeducation_ui_config.dart';

/// Page de session guidée d'un exercice — cœur du module Kiné.
///
/// Affiche les étapes une par une avec :
///   - Progression globale (barre + compteur)
///   - Grande consigne textuelle de l'étape courante
///   - Timer visuel si l'étape a une durée
///   - Grand bouton "Suivant" avec protection anti-double-clic :
///     → Le bouton alterne entre la gauche et la droite après chaque clic.
///       Position physiquement différente à chaque fois → impossible d'enchaîner
///       deux appuis sans déplacer volontairement le stylet.
///   - Croix de fermeture (en lieu et place du bouton pause) pour quitter proprement
///
/// Un écran de chargement est affiché au démarrage (durée : [ReeducationUiConfig.exerciseLaunchLoaderMs]).
class ExerciseSessionPage extends StatefulWidget {
  const ExerciseSessionPage({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  State<ExerciseSessionPage> createState() => _ExerciseSessionPageState();
}

class _ExerciseSessionPageState extends State<ExerciseSessionPage> {
  // ── Données ───────────────────────────────────────────────────────────────
  Exercise? _exercise;

  // ── État de la session ────────────────────────────────────────────────────
  int _stepIndex = 0;

  /// true pendant le cooldown post-clic (protection anti-double-tap).
  bool _nextCooldown = false;

  /// Position du bouton Suivant : alterne gauche/droite à chaque clic.
  bool _buttonOnRight = true;

  // ── Écran de chargement initial ───────────────────────────────────────────
  bool _loading = true;

  // ── Timer de l'étape ──────────────────────────────────────────────────────
  Timer? _timer;
  int _remainingSeconds = 0;
  int _stepStartSeconds = 0;
  int _stepsCompleted = 0;

  @override
  void initState() {
    super.initState();
    _exercise = KineCatalogService.instance.findExerciseById(widget.exerciseId);

    if (_exercise == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/reeducation/kine');
      });
      return;
    }

    // Écran de chargement visible avant la première consigne.
    Future.delayed(const Duration(milliseconds: ReeducationUiConfig.exerciseLaunchLoaderMs), () {
      if (mounted) {
        setState(() => _loading = false);
        _startStep();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Gestion des étapes ────────────────────────────────────────────────────

  void _startStep() {
    _timer?.cancel();
    if (_exercise == null) return;

    final step = _exercise!.steps[_stepIndex];

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

  /// Passe à l'étape suivante.
  void _next() {
    if (_exercise == null || _nextCooldown) return;

    setState(() {
      _nextCooldown = true;
      _buttonOnRight = !_buttonOnRight; // alterne gauche ↔ droite
    });
    Future.delayed(
      const Duration(milliseconds: ReeducationUiConfig.nextButtonCooldownMs),
      () { if (mounted) setState(() => _nextCooldown = false); },
    );

    _timer?.cancel();
    _stepsCompleted++;

    if (_stepIndex >= _exercise!.steps.length - 1) {
      context.go(
        '/reeducation/kine/exercise/${widget.exerciseId}/fin'
        '?steps=$_stepsCompleted&total=${_exercise!.steps.length}&full=1',
      );
    } else {
      setState(() => _stepIndex++);
      _startStep();
    }
  }

  void _askStop() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Arrêter l\'exercice ?',
          style: TextStyle(fontSize: 22),
        ),
        content: const Text(
          'Votre progression dans cet exercice ne sera pas sauvegardée.',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Continuer', style: TextStyle(fontSize: 18)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFBF360C),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(
                '/reeducation/kine/exercise/${widget.exerciseId}/fin'
                '?steps=$_stepsCompleted&total=${_exercise!.steps.length}&full=0',
              );
            },
            child: const Text('Terminer', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_exercise == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_loading) return _buildLoader();

    final exercise = _exercise!;
    final step = exercise.steps[_stepIndex];
    final isLastStep = _stepIndex == exercise.steps.length - 1;
    final hasTimer = _stepStartSeconds > 0;
    final timerDone = hasTimer && _remainingSeconds == 0;
    final globalProgress = (_stepIndex + 1) / exercise.steps.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askStop();
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 80,
          backgroundColor: KineTheme.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Text(
            exercise.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          // Croix de fermeture — seul bouton, à droite (position habituelle pendant l'exercice)
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
          color: KineTheme.primary,
          child: const Center(
            child: Icon(Icons.drag_handle, color: Colors.white54, size: 28),
          ),
        ),

        backgroundColor: KineTheme.background,

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
                      'Étape ${_stepIndex + 1} / ${exercise.steps.length}',
                      style: KineTheme.stepCounter,
                    ),
                    const Spacer(),
                    if (exercise.side != ExerciseSide.bilateral)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: exercise.zone.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          exercise.side.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: exercise.zone.color,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: globalProgress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFCCE5D8),
                    valueColor: const AlwaysStoppedAnimation<Color>(KineTheme.primary),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Carte de consigne ────────────────────────────────────────
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: KineTheme.primary.withValues(alpha: 0.3),
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
                          style: KineTheme.stepInstruction,
                        ),

                        // ── Timer ────────────────────────────────────────────
                        if (hasTimer) ...[
                          const SizedBox(height: 28),
                          Text(
                            timerDone ? '✓ Terminé' : '$_remainingSeconds s',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: timerDone ? KineTheme.success : KineTheme.primary,
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
                                timerDone ? KineTheme.success : KineTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Bouton Suivant / Terminer — alternance gauche / droite ────
                // Le bouton occupe ~62 % de la largeur et change de côté après
                // chaque clic. Déplacement physique réel → impossible d'enchaîner
                // deux appuis sans déplacer volontairement le stylet.
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
                        height: KineTheme.nextButtonHeight,
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
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: isLastStep
                                ? KineTheme.success
                                : KineTheme.nextButton,
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
    return Scaffold(
      backgroundColor: KineTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _exercise!.zone.icon,
              size: 88,
              color: _exercise!.zone.color.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 36),
            CircularProgressIndicator(
              color: _exercise!.zone.color,
              strokeWidth: 3,
            ),
            const SizedBox(height: 28),
            Text(
              _exercise!.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                color: _exercise!.zone.color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Préparez-vous…',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
