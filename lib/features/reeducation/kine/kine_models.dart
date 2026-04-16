import 'package:flutter/material.dart';

// =============================================================================
// Modèles du module Kinésithérapie
// =============================================================================

// ─────────────────────────────────────────────────────────────────────────────
// BodyZone
// ─────────────────────────────────────────────────────────────────────────────

enum BodyZone {
  rightArm,
  leftArm,
  hands,
  face,
  trunk,
  legs;

  String get label => switch (this) {
        BodyZone.rightArm => 'Bras droit',
        BodyZone.leftArm  => 'Bras gauche',
        BodyZone.hands    => 'Mains',
        BodyZone.face     => 'Visage',
        BodyZone.trunk    => 'Tronc / Posture',
        BodyZone.legs     => 'Jambes',
      };

  /// Icônes cohérentes par zone — distinguables visuellement.
  /// - Bras droit  : sports_handball (bras actif levé)
  /// - Bras gauche : sign_language (bras/main levé — clairement différent du handball)
  /// - Mains       : pan_tool (paume ouverte)
  /// - Visage      : face
  /// - Tronc       : self_improvement (silhouette assise, torse droit)
  /// - Jambes      : airline_seat_legroom_extra (jambes en position assise — parfait fauteuil)
  IconData get icon => switch (this) {
        BodyZone.rightArm => Icons.sports_handball,
        BodyZone.leftArm  => Icons.sign_language,
        BodyZone.hands    => Icons.pan_tool,
        BodyZone.face     => Icons.face,
        BodyZone.trunk    => Icons.self_improvement,
        BodyZone.legs     => Icons.airline_seat_legroom_extra,
      };

  Color get color => switch (this) {
        BodyZone.rightArm => const Color(0xFF1565C0),
        BodyZone.leftArm  => const Color(0xFF6A1B9A),
        BodyZone.hands    => const Color(0xFF00838F),
        BodyZone.face     => const Color(0xFFBF360C),
        BodyZone.trunk    => const Color(0xFF2E7D32),
        BodyZone.legs     => const Color(0xFF283593),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Enums de classification
// ─────────────────────────────────────────────────────────────────────────────

enum ExerciseSide {
  right,
  left,
  bilateral;

  String get label => switch (this) {
        ExerciseSide.right     => 'Côté droit',
        ExerciseSide.left      => 'Côté gauche',
        ExerciseSide.bilateral => 'Les deux côtés',
      };
}

enum DifficultyLevel {
  veryEasy,
  easy,
  medium;

  String get label => switch (this) {
        DifficultyLevel.veryEasy => 'Très facile',
        DifficultyLevel.easy     => 'Facile',
        DifficultyLevel.medium   => 'Moyen',
      };
}

enum ExerciseMode {
  autonomous,
  assisted,
}

// ─────────────────────────────────────────────────────────────────────────────
// ExerciseStep
// ─────────────────────────────────────────────────────────────────────────────

class ExerciseStep {
  final String instruction;
  final int? durationSeconds;

  const ExerciseStep({
    required this.instruction,
    this.durationSeconds,
  });

  Map<String, dynamic> toMap() => {
        'instruction': instruction,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
      };

  factory ExerciseStep.fromJson(Map<String, dynamic> json) => ExerciseStep(
        instruction: json['instruction'] as String,
        durationSeconds: json['durationSeconds'] as int?,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Exercise
// ─────────────────────────────────────────────────────────────────────────────

/// ⚠️ L'[id] est stable entre les versions : persisté dans Firestore (relevés).
/// Ne jamais le modifier.
class Exercise {
  final String id;
  final String title;
  final BodyZone zone;
  final String? subZone;
  final ExerciseSide side;
  final String position;
  final DifficultyLevel difficulty;
  final String objective;
  final int? durationSeconds;
  final int? repetitions;
  final List<ExerciseStep> steps;
  final ExerciseMode mode;

  Exercise({
    required this.id,
    required this.title,
    required this.zone,
    this.subZone,
    required this.side,
    this.position = 'Assise',
    required this.difficulty,
    required this.objective,
    this.durationSeconds,
    this.repetitions,
    required this.steps,
    this.mode = ExerciseMode.autonomous,
  });

  String get durationLabel {
    if (repetitions != null) return '$repetitions rép.';
    if (durationSeconds != null) {
      final min = durationSeconds! ~/ 60;
      final sec = durationSeconds! % 60;
      if (min > 0) return '${min}min${sec > 0 ? " ${sec}s" : ""}';
      return '${durationSeconds}s';
    }
    return '';
  }

  Map<String, dynamic> toFirestoreLog() => {
        'exerciseId': id,
        'title': title,
        'zone': zone.name,
        'side': side.name,
        'difficulty': difficulty.name,
        'totalSteps': steps.length,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'zone': zone.name,
        if (subZone != null) 'subZone': subZone,
        'side': side.name,
        'position': position,
        'difficulty': difficulty.name,
        'objective': objective,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
        if (repetitions != null) 'repetitions': repetitions,
        'steps': steps.map((s) => s.toMap()).toList(),
        'mode': mode.name,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String,
        title: json['title'] as String,
        zone: BodyZone.values.firstWhere(
          (z) => z.name == json['zone'],
          orElse: () => BodyZone.rightArm,
        ),
        subZone: json['subZone'] as String?,
        side: ExerciseSide.values.firstWhere(
          (s) => s.name == json['side'],
          orElse: () => ExerciseSide.bilateral,
        ),
        position: json['position'] as String? ?? 'Assise',
        difficulty: DifficultyLevel.values.firstWhere(
          (d) => d.name == json['difficulty'],
          orElse: () => DifficultyLevel.easy,
        ),
        objective: json['objective'] as String,
        durationSeconds: json['durationSeconds'] as int?,
        repetitions: json['repetitions'] as int?,
        steps: (json['steps'] as List)
            .map((s) => ExerciseStep.fromJson(s as Map<String, dynamic>))
            .toList(),
        mode: ExerciseMode.values.firstWhere(
          (m) => m.name == (json['mode'] ?? 'autonomous'),
          orElse: () => ExerciseMode.autonomous,
        ),
      );
}

