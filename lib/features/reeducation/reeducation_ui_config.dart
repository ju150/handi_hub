/// Configuration centralisée des durées d'interface pour les 4 modules de rééducation.
///
/// Modifier ici pour ajuster tous les loaders et protections en un seul endroit.
/// Toutes les durées sont exprimées en millisecondes.
class ReeducationUiConfig {
  /// Loader affiché avant le démarrage d'un exercice (transition "Préparez-vous").
  static const int exerciseLaunchLoaderMs = 1200;

  /// Cooldown après un clic sur "Suivant" (protection anti-double-tap stylet).
  static const int nextButtonCooldownMs = 900;

  /// Délai de protection sur le bouton Retour (évite le multi-tap accidentel).
  static const int backNavigationDelayMs = 700;

  /// Loader affiché à l'entrée d'un module ou d'une page de liste.
  static const int moduleEntryLoaderMs = 900;
}
