import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/handi_scaffold.dart';
import '../kine_models.dart';
import '../kine_catalog_service.dart';
import '../kine_theme.dart';
import '../../reeducation_ui_config.dart';

/// Page d'introduction d'un exercice.
///
/// Présente toutes les informations avant le démarrage.
/// Navigation entrante : /reeducation/kine/exercise/:exerciseId
/// Navigation sortante : /reeducation/kine/exercise/:exerciseId/session
class ExerciseIntroPage extends StatefulWidget {
  const ExerciseIntroPage({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  State<ExerciseIntroPage> createState() => _ExerciseIntroPageState();
}

class _ExerciseIntroPageState extends State<ExerciseIntroPage> {
  Exercise? _exercise;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _resolveExercise();
  }

  void _safeBack(String zoneName) {
    if (_navigating) return;
    _navigating = true;
    Future.delayed(
      const Duration(milliseconds: ReeducationUiConfig.backNavigationDelayMs),
      () { _navigating = false; if (mounted) context.go('/reeducation/kine/zone/$zoneName'); },
    );
  }

  void _safeStartSession(String exerciseId) {
    if (_navigating) return;
    _navigating = true;
    context.go('/reeducation/kine/exercise/$exerciseId/session');
    Future.delayed(const Duration(milliseconds: 300), () => _navigating = false);
  }

  void _resolveExercise() {
    final exercise = KineCatalogService.instance.findExerciseById(widget.exerciseId);

    if (exercise == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/reeducation/kine');
      });
      return;
    }

    setState(() => _exercise = exercise);
  }

  @override
  Widget build(BuildContext context) {
    if (_exercise == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final exercise = _exercise!;

    return HandiScaffold(
      title: exercise.zone.label,
      onBack: () => _safeBack(exercise.zone.name),
      backTooltip: 'Retour à la zone',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icône de zone ──────────────────────────────────────────────────
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: exercise.zone.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(exercise.zone.icon, size: 54, color: exercise.zone.color),
            ),
          ),
          const SizedBox(height: 16),

          // ── Titre ──────────────────────────────────────────────────────────
          Center(
            child: Text(
              exercise.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // ── Badges ────────────────────────────────────────────────────────
          Center(
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (exercise.side != ExerciseSide.bilateral)
                  _InfoPill(
                    icon: Icons.swap_horiz,
                    label: exercise.side.label,
                    color: exercise.zone.color,
                  ),
                _InfoPill(
                  icon: Icons.chair_rounded,
                  label: exercise.position,
                  color: const Color(0xFF555555),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ── Objectif ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: KineTheme.stepCardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: KineTheme.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Objectif',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF00796B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(exercise.objective, style: KineTheme.objective),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Infos pratiques ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: exercise.repetitions != null
                      ? Icons.repeat_rounded
                      : Icons.timer_rounded,
                  label: exercise.repetitions != null
                      ? '${exercise.repetitions} répétitions'
                      : exercise.durationLabel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.format_list_numbered_rounded,
                  label: '${exercise.steps.length} étapes guidées',
                ),
              ),
            ],
          ),

          const Spacer(),

          // ── Bouton Démarrer ────────────────────────────────────────────────
          FilledButton.icon(
            onPressed: () => _safeStartSession(exercise.id),
            icon: const Icon(Icons.play_arrow_rounded, size: 32),
            label: const Text('Démarrer l\'exercice'),
            style: KineTheme.startButtonStyle(),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDDDDD)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 26, color: KineTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
