import 'package:flutter/material.dart';

/// Thème visuel du module Jeux.
///
/// Palette volontairement festive, colorée et contrastée — à rebours du look
/// "médical" des autres modules. Grosses cibles, grands espaces, couleurs vives.
abstract class GamesTheme {
  GamesTheme._();

  // ─── Fond & surface ───────────────────────────────────────────────────────
  static const Color background = Color(0xFFFFFDE7); // jaune très clair
  static const Color surface    = Color(0xFFFFFFFF);

  // ─── Texte ────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF6D4C41);
  static const Color textOnDark    = Color(0xFFFFFFFF);

  // ─── Couleurs par jeu ─────────────────────────────────────────────────────
  static const Color briserMotsColor = Color(0xFF4A148C);  // violet profond
  static const Color briserMotsLight = Color(0xFF7B1FA2);
  static const Color toucheCibleColor = Color(0xFFB71C1C); // rouge intense
  static const Color toucheCibleLight = Color(0xFFE53935);
  static const Color memoryColor      = Color(0xFF0D47A1); // bleu profond
  static const Color memoryLight      = Color(0xFF1976D2);
  static const Color colorMatchColor  = Color(0xFF1B5E20); // vert forêt
  static const Color colorMatchLight  = Color(0xFF388E3C);

  static const Color candyCrushColor = Color(0xFFAD1457); // rose profond
  static const Color candyCrushLight = Color(0xFFE91E63);

  // ─── Boutons d'action ─────────────────────────────────────────────────────
  static const Color favorisColor = Color(0xFFF57F17);  // ambre
  static const Color scoresColor  = Color(0xFF6A1B9A);  // violet

  // ─── Palette Candy (Color Match) ──────────────────────────────────────────
  static const List<Color> candyColors = [
    Color(0xFFEF5350), // rouge
    Color(0xFFFDD835), // jaune
    Color(0xFF66BB6A), // vert
    Color(0xFF42A5F5), // bleu
    Color(0xFFCE93D8), // lilas
    Color(0xFFFF8A65), // saumon
  ];

  // ─── Couleurs cibles (Touche la Cible) ────────────────────────────────────
  static const List<Color> targetColors = [
    Color(0xFFE53935),
    Color(0xFFFF8F00),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
    Color(0xFFE91E63),
  ];

  // ─── Dimensions ───────────────────────────────────────────────────────────
  static const double cardRadius        = 24.0;
  static const double featuredCardRadius = 28.0;
  static const double buttonHeight      = 80.0;
  static const double smallButtonHeight = 64.0;
  static const double iconSize          = 52.0;
  static const double padding           = 20.0;
  static const double cardSpacing       = 16.0;
  static const double titleFontSize     = 26.0;
  static const double cardTitleFontSize = 22.0;
  static const double bodyFontSize      = 18.0;

  // ─── Durées d'animation ───────────────────────────────────────────────────
  static const Duration flipDuration    = Duration(milliseconds: 400);
  static const Duration feedbackDelay   = Duration(milliseconds: 700);

  // ─── Helpers de décoration ────────────────────────────────────────────────

  static BoxDecoration cardDecoration(Color base, {Color? light}) =>
      BoxDecoration(
        gradient: LinearGradient(
          colors: [base, light ?? _lighten(base, 0.25)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: base.withValues(alpha: 0.40),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      );

  static BoxDecoration featuredCardDecoration(Color base, Color light) =>
      BoxDecoration(
        gradient: LinearGradient(
          colors: [base, light],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(featuredCardRadius),
        boxShadow: [
          BoxShadow(
            color: base.withValues(alpha: 0.50),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}
