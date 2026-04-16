import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'simple_exercise.dart';

// =============================================================================
// SimpleCatalogService — service générique pour les modules simples
// =============================================================================
//
// Utilisé par les modules Respiration, Relaxation et Orthophonie.
// Chaque module crée son instance via son propre fichier de service.
//
// Comportement :
//   1. Charge depuis le cache local (SharedPreferences JSON).
//   2. Si pas de cache : récupère depuis Firebase (bloquant, première ouverture).
//   3. Si cache présent : affiche immédiatement + vérifie Firebase en arrière-plan.
//   4. Si nouvelle version distante → met à jour le cache.
//
// Structure Firestore attendue :
//   reeducation_catalogs/{moduleName}
//     → { version: "1", updatedAt: "...", module: "{moduleName}" }
//       exercises/items
//         → { items: [ {...SimpleExercise...}, … ] }
// =============================================================================

class SimpleCatalogService {
  SimpleCatalogService(String moduleName)
      : _moduleName = moduleName;

  final String _moduleName;

  List<SimpleExercise> _exercises = [];

  /// Liste courante des exercices (cache local ou Firebase).
  List<SimpleExercise> get exercises => _exercises;

  // ── Clés cache (dérivées du nom du module) ─────────────────────────────────

  String get _cacheKey   => '${_moduleName}_catalog_exercises_v1';
  String get _versionKey => '${_moduleName}_catalog_version_v1';

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> init() async {
    await _loadFromCache();
    if (_exercises.isEmpty) {
      await _syncFromFirebase(); // première ouverture : on attend Firebase
    } else {
      _syncFromFirebase(); // cache dispo : sync en arrière-plan
    }
  }

  /// Vérifie si Firebase a une version plus récente et met à jour le cache.
  /// À appeler depuis initState() des pages pour détecter les modifications
  /// sans relancer l'app.
  Future<void> refresh() => _syncFromFirebase();

  // ── Cache local ────────────────────────────────────────────────────────────

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cacheKey);
      if (json != null) {
        final List decoded = jsonDecode(json) as List;
        _exercises = decoded
            .map((e) => SimpleExercise.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _exercises = [];
      debugPrint('[$_moduleName CatalogService] Cache invalide : $e');
    }
  }

  // ── Synchronisation Firebase ───────────────────────────────────────────────

  Future<void> _syncFromFirebase() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final prefs = await SharedPreferences.getInstance();

      final moduleRef = firestore
          .collection('reeducation_catalogs')
          .doc(_moduleName);
      final metaSnap = await moduleRef.get();
      if (!metaSnap.exists) return;

      final remoteVersion = metaSnap.data()?['version']?.toString();
      final localVersion  = prefs.getString(_versionKey);
      if (remoteVersion == null || remoteVersion == localVersion) return;

      final snap = await moduleRef
          .collection('exercises')
          .doc('items')
          .get();
      if (!snap.exists) return;

      final raw = snap.data()?['items'] as List?;
      if (raw == null) return;

      final newExercises = raw
          .map((e) => SimpleExercise.fromJson(e as Map<String, dynamic>))
          .toList();

      _exercises = newExercises;
      await prefs.setString(
          _cacheKey,
          jsonEncode(newExercises.map((e) => e.toJson()).toList()));
      await prefs.setString(_versionKey, remoteVersion);

      debugPrint('[$_moduleName CatalogService] Catalogue mis à jour (v$remoteVersion)');
    } catch (e) {
      debugPrint('[$_moduleName CatalogService] Sync ignorée : $e');
    }
  }

  // ── Requête ────────────────────────────────────────────────────────────────

  /// Retourne l'exercice correspondant à [id], ou null s'il n'existe pas.
  SimpleExercise? findById(String id) =>
      _exercises.where((e) => e.id == id).firstOrNull;
}
