// Modèle partagé pour les trois modules simples de rééducation :
// respiration, relaxation, orthophonie.
//
// Remplace les trois paires de types quasi-identiques :
//   BreathStep / BreathExercise  (respiration)
//   RelaxStep  / RelaxExercise   (relaxation)
//   OrthoStep  / OrthoExercise   (orthophonie)

/// Une étape guidée au sein d'un [SimpleExercise].
class SimpleStep {
  /// Consigne affichée à l'écran.
  final String instruction;

  /// Durée suggérée en secondes (null = avancement manuel).
  final int? durationSeconds;

  const SimpleStep({required this.instruction, this.durationSeconds});

  factory SimpleStep.fromJson(Map<String, dynamic> json) => SimpleStep(
        instruction: json['instruction'] as String,
        durationSeconds: json['durationSeconds'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'instruction': instruction,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
      };
}

/// Exercice guidé complet pour un module simple de rééducation.
class SimpleExercise {
  /// Identifiant unique stable (préfixe propre au module, ex. "resp-").
  final String id;

  /// Titre court affiché dans la liste.
  final String title;

  /// Description ou objectif affiché sur la carte.
  final String description;

  /// Emoji représentant l'exercice (affiché comme icône).
  final String emoji;

  /// Couleur thématique de l'exercice (ARGB).
  final int colorValue;

  /// Liste des étapes guidées.
  final List<SimpleStep> steps;

  /// Durée totale indicative en minutes.
  final int durationMinutes;

  const SimpleExercise({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.colorValue,
    required this.steps,
    required this.durationMinutes,
  });

  factory SimpleExercise.fromJson(Map<String, dynamic> json) => SimpleExercise(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        emoji: json['emoji'] as String,
        colorValue: json['colorValue'] as int,
        durationMinutes: json['durationMinutes'] as int,
        steps: (json['steps'] as List)
            .map((s) => SimpleStep.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'emoji': emoji,
        'colorValue': colorValue,
        'durationMinutes': durationMinutes,
        'steps': steps.map((s) => s.toJson()).toList(),
      };
}
