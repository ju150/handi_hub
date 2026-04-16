import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../kine_catalog_service.dart';
import '../kine_models.dart';
import '../kine_firebase_service.dart';
import '../kine_theme.dart';
import '../../reeducation_ui_config.dart';

/// Écran de fin d'exercice — valorisant, simple, sans scroll.
///
/// Structure :
///   - Bouton Home (haut droite)
///   - Cercle animé ✓ + headline "Bravo !" ou "Exercice terminé"
///   - Auto-évaluation réussite (3 options)
///   - Feedback ressenti (3 emojis)
///   - 1 bouton principal : retour à la zone / origine
class ExerciseEndPage extends StatefulWidget {
  const ExerciseEndPage({
    super.key,
    required this.exerciseId,
    required this.stepsCompleted,
    required this.totalSteps,
    required this.fullyCompleted,
    this.fromRoute,
    this.fromLabel,
  });

  final String exerciseId;
  final int stepsCompleted;
  final int totalSteps;
  final bool fullyCompleted;
  final String? fromRoute;
  final String? fromLabel;

  @override
  State<ExerciseEndPage> createState() => _ExerciseEndPageState();
}

class _ExerciseEndPageState extends State<ExerciseEndPage>
    with SingleTickerProviderStateMixin {
  Exercise? _exercise;
  String? _feedback;
  String? _success; // 'yes' | 'partial' | 'no'
  bool _logged = false;
  bool _navigating = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _resolveExercise();
  }

  Future<void> _resolveExercise() async {
    final exercise =
        KineCatalogService.instance.findExerciseById(widget.exerciseId);
    if (exercise == null) return;
    if (mounted) {
      setState(() => _exercise = exercise);
      _animController.forward();
    }
    await _logSession();
  }

  Future<void> _logSession() async {
    if (_exercise == null || _logged) return;
    _logged = true;
    await KineFirebaseService.instance.logSession(
      exercise: _exercise!,
      stepsCompleted: widget.stepsCompleted,
      fullyCompleted: widget.fullyCompleted,
      feedback: _feedback,
      success: _success,
    );
  }

  Future<void> _selectFeedback(String value) async {
    if (!mounted) return;
    setState(() {
      _feedback = _feedback == value ? null : value;
      _logged = false;
    });
    await _logSession();
  }

  Future<void> _selectSuccess(String value) async {
    if (!mounted) return;
    setState(() {
      _success = _success == value ? null : value;
      _logged = false;
    });
    await _logSession();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String get _backRoute =>
      widget.fromRoute ??
      '/reeducation/kine/zone/${_exercise?.zone.name ?? ""}';

  String get _backLabel =>
      widget.fromLabel ??
      (_exercise != null ? _exercise!.zone.label : 'Retour');

  void _safeBack() {
    if (_navigating) return;
    _navigating = true;
    Future.delayed(
      const Duration(milliseconds: ReeducationUiConfig.backNavigationDelayMs),
      () { _navigating = false; if (mounted) context.go(_backRoute); },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_exercise == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final exercise = _exercise!;
    final headline = widget.fullyCompleted ? 'Bravo !' : 'Exercice terminé';
    final subline = widget.fullyCompleted
        ? 'Toutes les étapes réalisées.\nBeau travail !'
        : '${widget.stepsCompleted} étape${widget.stepsCompleted > 1 ? "s" : ""}'
            ' sur ${widget.totalSteps} réalisée${widget.stepsCompleted > 1 ? "s" : ""}.';

    return Scaffold(
      backgroundColor: KineTheme.background,
      bottomNavigationBar: Container(
        height: 112,
        color: KineTheme.primary,
        child: const Center(
          child: Icon(Icons.drag_handle, color: Colors.white54, size: 28),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              // ── Bouton Home ──────────────────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  iconSize: 48,
                  icon: const Icon(
                    Icons.home_rounded,
                    color: Color(0xFF555555),
                  ),
                  tooltip: 'Accueil',
                  onPressed: () => context.go('/'),
                ),
              ),

              const SizedBox(height: 4),

              // ── Cercle animé ✓ ───────────────────────────────────────────
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: widget.fullyCompleted
                        ? KineTheme.success
                        : KineTheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (widget.fullyCompleted
                                ? KineTheme.success
                                : KineTheme.primary)
                            .withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 66,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // ── Headline ─────────────────────────────────────────────────
              Text(
                headline,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subline,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFF555555),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                exercise.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: exercise.zone.color,
                ),
              ),

              const Spacer(),

              // ── Auto-évaluation réussite ─────────────────────────────────
              const Text(
                'As-tu réussi l\'exercice ?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _SuccessButton(
                    label: 'Oui',
                    value: 'yes',
                    selected: _success == 'yes',
                    color: const Color(0xFF388E3C),
                    onTap: () => _selectSuccess('yes'),
                  ),
                  const SizedBox(width: 10),
                  _SuccessButton(
                    label: 'Pas complètement',
                    value: 'partial',
                    selected: _success == 'partial',
                    color: const Color(0xFFF57C00),
                    onTap: () => _selectSuccess('partial'),
                  ),
                  const SizedBox(width: 10),
                  _SuccessButton(
                    label: 'Non',
                    value: 'no',
                    selected: _success == 'no',
                    color: const Color(0xFFBF360C),
                    onTap: () => _selectSuccess('no'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Feedback ressenti ────────────────────────────────────────
              const Text(
                'Comment c\'était ?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _FeedbackButton(
                    emoji: '😊',
                    label: 'Bien passé',
                    value: 'great',
                    selected: _feedback == 'great',
                    color: const Color(0xFF388E3C),
                    onTap: () => _selectFeedback('great'),
                  ),
                  const SizedBox(width: 10),
                  _FeedbackButton(
                    emoji: '😐',
                    label: 'Un peu dur',
                    value: 'ok',
                    selected: _feedback == 'ok',
                    color: const Color(0xFFF57C00),
                    onTap: () => _selectFeedback('ok'),
                  ),
                  const SizedBox(width: 10),
                  _FeedbackButton(
                    emoji: '😰',
                    label: 'Difficile',
                    value: 'hard',
                    selected: _feedback == 'hard',
                    color: const Color(0xFFBF360C),
                    onTap: () => _selectFeedback('hard'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Bouton principal ─────────────────────────────────────────
              FilledButton.icon(
                onPressed: _safeBack,
                icon: Icon(exercise.zone.icon, size: 26),
                label: Text('Retour à $_backLabel'),
                style: FilledButton.styleFrom(
                  backgroundColor: exercise.zone.color,
                  minimumSize: const Size(double.infinity, 80),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bouton auto-évaluation réussite
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessButton extends StatelessWidget {
  const _SuccessButton({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : const Color(0xFFDDDDDD),
              width: selected ? 2.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected ? color : const Color(0xFF666666),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bouton ressenti emoji
// ─────────────────────────────────────────────────────────────────────────────

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({
    required this.emoji,
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final String value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : const Color(0xFFDDDDDD),
              width: selected ? 2.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? color : const Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
