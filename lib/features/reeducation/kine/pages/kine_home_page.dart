import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/handi_scaffold.dart';
import '../../../../app/theme.dart';
import '../kine_models.dart';
import '../kine_theme.dart';
import '../../reeducation_ui_config.dart';

/// Page d'accueil du module Kiné.
///
/// Affiche les 6 zones anatomiques en grille 2×3 qui occupe tout l'espace
/// disponible sans scroll. Un écran de chargement de 1,5 s est affiché à
/// l'ouverture pour éviter une transition trop brutale.
class KineHomePage extends StatefulWidget {
  const KineHomePage({super.key});

  @override
  State<KineHomePage> createState() => _KineHomePageState();
}

class _KineHomePageState extends State<KineHomePage> {
  bool _loading = true;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(
      const Duration(milliseconds: ReeducationUiConfig.moduleEntryLoaderMs),
      () { if (mounted) setState(() => _loading = false); },
    );
  }

  void _safeBack() {
    if (_navigating) return;
    _navigating = true;
    Future.delayed(
      const Duration(milliseconds: ReeducationUiConfig.backNavigationDelayMs),
      () { _navigating = false; if (mounted) context.go('/reeducation'); },
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

    return HandiScaffold(
      title: 'Kiné',
      onBack: _safeBack,
      backTooltip: 'Retour à Rééducation',
      body: Column(
        children: [
          // ── Grille des 6 zones anatomiques — remplit tout l'espace ──────────
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const cols = 2;
                const rows = 3;
                const spacing = 14.0;
                final itemWidth = (constraints.maxWidth - spacing) / cols;
                final itemHeight = (constraints.maxHeight - spacing * 2) / rows;
                final aspectRatio = itemWidth / itemHeight;

                return GridView.count(
                  crossAxisCount: cols,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: aspectRatio,
                  physics: const NeverScrollableScrollPhysics(),
                  children: BodyZone.values.map((zone) {
                    return _ZoneCard(
                      zone: zone,
                      onTap: () => _safeGo('/reeducation/kine/zone/${zone.name}'),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // ── Badge "Kiné assisté — bientôt disponible" (V2) ────────────────
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: HandiTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCCCCCC)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_rounded, size: 18, color: Color(0xFF999999)),
                  SizedBox(width: 8),
                  Text(
                    'Kiné assisté — bientôt disponible',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF999999),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
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
              Icons.accessibility_new_rounded,
              size: 88,
              color: KineTheme.primary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 36),
            const CircularProgressIndicator(
              color: KineTheme.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 28),
            const Text(
              'Chargement du module Kiné…',
              style: TextStyle(
                fontSize: 22,
                color: KineTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Carte de zone anatomique
// ─────────────────────────────────────────────────────────────────────────────

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({required this.zone, required this.onTap});

  final BodyZone zone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [zone.color, zone.color.withValues(alpha: 0.80)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(zone.icon, size: 52, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  zone.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
