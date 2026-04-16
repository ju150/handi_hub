import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/handi_scaffold.dart';
import 'simple_catalog_service.dart';
import 'simple_exercise.dart';
import '../reeducation_ui_config.dart';

/// Hub générique pour les modules simples de rééducation
/// (Respiration, Relaxation, Orthophonie).
///
/// Affiche une carte de description du module, puis la liste des exercices.
/// Chaque exercice est lancé via la route [sessionRoute]/:exerciseId.
///
/// Navigation entrante : /reeducation/{module}
/// Navigation sortante : [sessionRoute]/:exerciseId
class SimpleModulePage extends StatefulWidget {
  const SimpleModulePage({
    super.key,
    required this.title,
    required this.emoji,
    required this.description,
    required this.infoCardBgColor,
    required this.infoCardBorderColor,
    required this.infoCardTextColor,
    required this.service,
    required this.sessionRoute,
  });

  /// Nom du module affiché dans l'AppBar (ex. 'Respiration').
  final String title;

  /// Emoji représentant le module (affiché dans la carte info et le loader).
  final String emoji;

  /// Texte descriptif affiché dans la carte en haut de page.
  final String description;

  /// Couleur de fond de la carte info (propre à chaque module).
  final Color infoCardBgColor;

  /// Couleur de la bordure de la carte info.
  final Color infoCardBorderColor;

  /// Couleur du texte de la carte info et du spinner de chargement.
  final Color infoCardTextColor;

  /// Service fournissant la liste des exercices du module.
  final SimpleCatalogService service;

  /// Préfixe de route pour la session (ex. '/reeducation/respiration/session').
  final String sessionRoute;

  @override
  State<SimpleModulePage> createState() => _SimpleModulePageState();
}

class _SimpleModulePageState extends State<SimpleModulePage> {
  bool _loading = true;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(
      const Duration(milliseconds: ReeducationUiConfig.moduleEntryLoaderMs),
      () { if (mounted) setState(() => _loading = false); },
    );
    _refreshInBackground();
  }

  // Vérifie Firebase en arrière-plan à chaque ouverture de la page.
  // Si les données ont changé, redessine la liste des exercices.
  Future<void> _refreshInBackground() async {
    await widget.service.refresh();
    if (mounted) setState(() {});
  }

  void _safeBack() {
    if (_navigating) return;
    _navigating = true;
    Future.delayed(
      const Duration(milliseconds: ReeducationUiConfig.backNavigationDelayMs),
      () { _navigating = false; if (mounted) context.go('/reeducation'); },
    );
  }

  void _startExercise(SimpleExercise exercise) {
    if (_navigating) return;
    _navigating = true;
    context.go('${widget.sessionRoute}/${exercise.id}');
    Future.delayed(const Duration(milliseconds: 300), () => _navigating = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoader();

    final exercises = widget.service.exercises;

    return HandiScaffold(
      title: widget.title,
      onBack: _safeBack,
      backTooltip: 'Retour à Rééducation',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Description du module ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: widget.infoCardBgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.infoCardBorderColor),
            ),
            child: Row(
              children: [
                Text(widget.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.description,
                    style: TextStyle(
                      fontSize: 18,
                      color: widget.infoCardTextColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Choisissez un exercice',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 12),

          // ── Liste des exercices ───────────────────────────────────────────
          Expanded(
            child: exercises.isEmpty
                ? Center(
                    child: Text(
                      'Aucun exercice disponible.\nVérifiez votre connexion.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: widget.infoCardTextColor,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: exercises.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      return _ExerciseCard(
                        exercise: exercise,
                        onTap: () => _startExercise(exercise),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() {
    return Scaffold(
      backgroundColor: widget.infoCardBgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              color: widget.infoCardTextColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Chargement…',
              style: TextStyle(
                fontSize: 20,
                color: widget.infoCardTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Carte exercice — simple, grande, accessible au stylet
// Partagée par les 3 modules (remplace _ExerciseCard dupliqué 3 fois).
// ─────────────────────────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, required this.onTap});

  final SimpleExercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(exercise.colorValue);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // Emoji dans un cercle coloré.
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(exercise.emoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 14),

              // Titre + description + durée.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Color(0xFF666666),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: color),
                        const SizedBox(width: 4),
                        Text(
                          '${exercise.durationMinutes} min · ${exercise.steps.length} étapes',
                          style: TextStyle(
                            fontSize: 15,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Icon(Icons.play_circle_rounded, size: 42, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
