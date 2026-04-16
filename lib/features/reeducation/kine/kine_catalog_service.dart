import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'kine_models.dart';

// =============================================================================
// KineCatalogService — source unique des exercices
// =============================================================================
//
// Comportement :
//   1. Au démarrage : charge depuis le cache local (SharedPreferences JSON).
//   2. En arrière-plan : vérifie la version Firebase (document kine).
//   3. Si nouvelle version → télécharge et met à jour le cache.
//   4. Si pas de connexion → fonctionne avec le cache existant.
//   5. Si aucun cache et pas de réseau → liste vide.
//
// Structure Firestore attendue :
//   reeducation_catalogs/
//     kine            → { version: 1, updatedAt: "...", module: "kine" }
//       exercises/
//         items       → { items: [ {...Exercise...}, ... ] }
//
// Singleton : accéder via [KineCatalogService.instance].
// =============================================================================

class KineCatalogService {
  KineCatalogService._();

  static final KineCatalogService instance = KineCatalogService._();

  // ── Données courantes (Firebase ou fallback local) ─────────────────────────

  List<Exercise> _exercises = [];

  List<Exercise> get exercises => _exercises;

  // ── Clés cache SharedPreferences ──────────────────────────────────────────

  static const _exercisesCacheKey = 'kine_catalog_exercises_v2';
  static const _versionCacheKey   = 'kine_catalog_version_v2';

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> init() async {
    await _loadFromCache();
    if (_exercises.isEmpty) {
      await _syncFromFirebase();
    } else {
      _syncFromFirebase();
    }
  }

  /// Vérifie si Firebase a une version plus récente et met à jour le cache.
  Future<void> refresh() => _syncFromFirebase();

  // ── Cache local ────────────────────────────────────────────────────────────

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final exercisesJson = prefs.getString(_exercisesCacheKey);

      if (exercisesJson != null) {
        final List decoded = jsonDecode(exercisesJson) as List;
        _exercises = decoded
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _exercises = [];
      debugPrint('[KineCatalogService] Cache invalide : $e');
    }
  }

  // ── Synchronisation Firebase ───────────────────────────────────────────────

  Future<void> _syncFromFirebase() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final prefs = await SharedPreferences.getInstance();

      // Vérifier si la version distante a changé.
      final moduleRef = firestore
          .collection('reeducation_catalogs')
          .doc('kine');
      final metaSnap = await moduleRef.get();

      if (!metaSnap.exists) return;

      final remoteVersion = metaSnap.data()?['version']?.toString();
      final localVersion  = prefs.getString(_versionCacheKey);

      if (remoteVersion == null || remoteVersion == localVersion) return;

      // Nouvelle version → télécharger les exercices.
      final exercisesSnap = await moduleRef
          .collection('exercises')
          .doc('items')
          .get();

      if (!exercisesSnap.exists) return;

      final rawExercises = exercisesSnap.data()?['items'] as List?;
      if (rawExercises == null) return;

      final newExercises = rawExercises
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList();

      // Mise à jour en mémoire.
      _exercises = newExercises;

      // Persistance du nouveau cache.
      await prefs.setString(
        _exercisesCacheKey,
        jsonEncode(newExercises.map((e) => e.toJson()).toList()),
      );
      await prefs.setString(_versionCacheKey, remoteVersion);

      debugPrint('[KineCatalogService] Catalogue mis à jour (v$remoteVersion)');
    } catch (e) {
      // Pas de connexion ou structure Firebase absente → silencieux.
      debugPrint('[KineCatalogService] Sync ignorée : $e');
    }
  }

  // ── Requêtes ───────────────────────────────────────────────────────────────

  Exercise? findExerciseById(String id) =>
      _exercises.where((e) => e.id == id).firstOrNull;

  List<Exercise> exercisesByZone(BodyZone zone) => _exercises
      .where((e) => e.zone == zone)
      .toList()
    ..sort((a, b) => a.difficulty.index.compareTo(b.difficulty.index));
}
