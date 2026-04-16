import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'kine_models.dart';

/// Service de persistance Firebase pour les relevés de sessions kiné.
///
/// Enregistre chaque session d'exercice terminée dans Firestore pour
/// permettre une consultation à distance (tablette, poste kiné, etc.).
///
/// ## Structure Firestore
/// ```
/// kine_records/
///   {deviceId}/
///     sessions/
///       {auto-id}/
///         exerciseId, exerciseTitle, zone, side, completedAt,
///         stepsCompleted, totalSteps, fullyCompleted, feedback (optionnel)
/// ```
///
/// ## Identification
/// Un ID unique est généré au premier lancement et stocké en SharedPreferences.
/// Aucune authentification requise pour la V1.
///
/// ## Gestion d'erreurs
/// Les opérations Firebase sont silencieuses en cas d'échec réseau :
/// l'application continue de fonctionner normalement.
///
/// Singleton : accéder via [KineFirebaseService.instance].
class KineFirebaseService {
  KineFirebaseService._();

  static final KineFirebaseService instance = KineFirebaseService._();

  static const String _deviceIdKey = 'kine_device_id';

  final _firestore = FirebaseFirestore.instance;
  String? _deviceId;

  // ── Initialisation ─────────────────────────────────────────────────────────

  /// Charge ou génère l'identifiant unique du périphérique.
  /// À appeler dans main.dart après l'initialisation Firebase.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _deviceId = prefs.getString(_deviceIdKey);

      if (_deviceId == null) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        _deviceId = 'device_${ts}_${ts % 999983}';
        await prefs.setString(_deviceIdKey, _deviceId!);
      }
    } catch (e) {
      _deviceId ??= 'device_fallback_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // ── Écriture ───────────────────────────────────────────────────────────────

  /// Enregistre une session d'exercice dans Firestore.
  ///
  /// Appelé automatiquement par [ExerciseEndPage] à la fin de chaque exercice.
  /// Retourne true si l'enregistrement a réussi, false en cas d'erreur.
  Future<bool> logSession({
    required Exercise exercise,
    required int stepsCompleted,
    required bool fullyCompleted,
    String? feedback, // 'great' | 'ok' | 'hard' | null
    String? success,  // 'yes' | 'partial' | 'no' | null
  }) async {
    if (_deviceId == null) await init();

    try {
      final data = {
        'exerciseId':     exercise.id,
        'exerciseTitle':  exercise.title,
        'zone':           exercise.zone.name,
        'side':           exercise.side.name,
        'completedAt':    DateTime.now().toIso8601String(),
        'stepsCompleted': stepsCompleted,
        'totalSteps':     exercise.steps.length,
        'fullyCompleted': fullyCompleted,
        if (feedback != null) 'feedback': feedback,
        if (success != null) 'success': success,
      };

      await _firestore
          .collection('kine_records')
          .doc(_deviceId)
          .collection('sessions')
          .add(data);

      return true;
    } catch (e) {
      debugPrint('[KineFirebaseService] Impossible d\'enregistrer la session : $e');
      return false;
    }
  }

  /// Identifiant du périphérique courant (utile pour débogage / profil).
  String? get deviceId => _deviceId;
}
