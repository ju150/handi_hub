import 'package:flutter/material.dart';

/// Thème visuel spécifique au module Kiné.
///
/// Palette teal / vert apaisante, distincte du bleu global de HandiHub,
/// pour créer une ambiance "soin" et "bienveillance".
///
/// Toutes les dimensions respectent l'accessibilité :
/// zones de tap ≥ 72 dp, textes ≥ 18 sp pour lecture à distance (stylet).
abstract final class KineTheme {
  KineTheme._();

  // ── Couleurs ────────────────────────────────────────────────────────────────

  /// Couleur principale du module : teal profond.
  static const Color primary = Color(0xFF00796B); // teal 700

  /// Arrière-plan global légèrement teinté teal.
  static const Color background = Color(0xFFEFF7F5);

  /// Couleur du grand bouton "Suivant" — vert profond, contraste maximal.
  static const Color nextButton = Color(0xFF1B5E20); // green 900

  /// Couleur du bouton "Démarrer".
  static const Color startButton = Color(0xFF00897B); // teal 600

  /// Vert de succès affiché sur l'écran de fin.
  static const Color success = Color(0xFF388E3C);

  /// Fond de la carte consigne (page intro).
  static const Color stepCardBackground = Color(0xFFE8F5E9);

  // ── Dimensions ──────────────────────────────────────────────────────────────

  /// Hauteur du grand bouton "Suivant" (confort stylet).
  static const double nextButtonHeight = 100.0;

  // ── Styles de texte ─────────────────────────────────────────────────────────

  /// Consigne d'étape : texte principal de la session, lu à distance.
  static const TextStyle stepInstruction = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w500,
    color: Color(0xFF1A1A1A),
    height: 1.6,
  );

  /// Compteur d'étapes affiché en teal au-dessus de la consigne.
  static const TextStyle stepCounter = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: Color(0xFF00796B),
    letterSpacing: 0.5,
  );

  /// Texte de l'objectif dans la page intro.
  static const TextStyle objective = TextStyle(
    fontSize: 20,
    color: Color(0xFF444444),
    height: 1.5,
  );

  // ── Styles de boutons ───────────────────────────────────────────────────────

  /// Style du bouton "Démarrer" (plein, teal).
  static ButtonStyle startButtonStyle() => FilledButton.styleFrom(
        backgroundColor: startButton,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      );
}
