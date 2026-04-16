import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/handi_scaffold.dart';
import '../kine_models.dart';
import '../kine_catalog_service.dart';
import '../exercise_card.dart';
import '../kine_theme.dart';
import '../../reeducation_ui_config.dart';

/// Page listant les exercices d'une zone anatomique.
///
/// Affiche un écran de chargement de 1,2 s avant la liste pour éviter
/// une transition trop brutale lors du changement de zone.
///
/// Navigation entrante : /reeducation/kine/zone/:zoneId
/// Navigation sortante : /reeducation/kine/exercise/:exerciseId
class KineZonePage extends StatefulWidget {
  const KineZonePage({super.key, required this.zoneId});

  final String zoneId;

  @override
  State<KineZonePage> createState() => _KineZonePageState();
}

class _KineZonePageState extends State<KineZonePage> {
  late BodyZone _zone;
  bool _loading = true;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();

    try {
      _zone = BodyZone.values.firstWhere((z) => z.name == widget.zoneId);
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/reeducation/kine');
      });
      _zone = BodyZone.rightArm;
    }

    // Écran de transition visible — laisse le temps de lever le stylet.
    Future.delayed(
      const Duration(milliseconds: ReeducationUiConfig.moduleEntryLoaderMs),
      () { if (mounted) setState(() => _loading = false); },
    );
    _refreshInBackground();
  }

  // Vérifie Firebase en arrière-plan à chaque ouverture de la page.
  // Si les données ont changé, redessine la liste des exercices.
  Future<void> _refreshInBackground() async {
    await KineCatalogService.instance.refresh();
    if (mounted) setState(() {});
  }

  void _safeBack() {
    if (_navigating) return;
    _navigating = true;
    Future.delayed(
      const Duration(milliseconds: ReeducationUiConfig.backNavigationDelayMs),
      () { _navigating = false; if (mounted) context.go('/reeducation/kine'); },
    );
  }

  void _safeGo(String path) {
    if (_navigating) return;
    _navigating = true;
    context.go(path);
    Future.delayed(const Duration(milliseconds: 300), () => _navigating = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoader();

    final exercises = KineCatalogService.instance.exercisesByZone(_zone);

    return HandiScaffold(
      title: _zone.label,
      onBack: _safeBack,
      backTooltip: 'Retour au module Kiné',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête de zone coloré ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              color: _zone.color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(_zone.icon, size: 44, color: Colors.white),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _zone.label,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${exercises.length} exercice${exercises.length > 1 ? "s" : ""}',
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Liste des exercices ────────────────────────────────────────────
          Expanded(
            child: exercises.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun exercice disponible\npour cette zone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      return ExerciseCard(
                        exercise: exercise,
                        onTap: () => _safeGo(
                          '/reeducation/kine/exercise/${exercise.id}',
                        ),
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
      backgroundColor: KineTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _zone.icon,
              size: 88,
              color: _zone.color.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 36),
            CircularProgressIndicator(color: _zone.color, strokeWidth: 3),
            const SizedBox(height: 28),
            Text(
              _zone.label,
              style: TextStyle(
                fontSize: 24,
                color: _zone.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
