import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'core/services/firebase_service.dart';
import 'core/services/storage_service.dart';
import 'features/games/services/games_storage_service.dart';
import 'features/reeducation/kine/kine_firebase_service.dart';
import 'features/reeducation/kine/kine_catalog_service.dart';
import 'features/reeducation/respiration/respiration_catalog_service.dart';
import 'features/reeducation/relaxation/relaxation_catalog_service.dart';
import 'features/reeducation/orthophonie/orthophonie_catalog_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Color(0xFF0D47A1),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await StorageService.instance.init();
  await GamesStorageService.instance.init();
  try {
    await Firebase.initializeApp();
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    );
    FirebaseService.isInitialized = true;
    await KineFirebaseService.instance.init();
    // Charge les catalogues depuis le cache, puis sync Firebase en arrière-plan.
    await KineCatalogService.instance.init();
    await RespirationCatalogService.instance.init();
    await RelaxationCatalogService.instance.init();
    await OrthophonieCatalogService.instance.init();
    debugPrint('✅ Firebase initialisé');
  } catch (e) {
    debugPrint('❌ Firebase init échoué : $e');
  }
  runApp(const HandiHubApp());
}
