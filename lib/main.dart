import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'core/services/firebase_service.dart';
import 'core/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Barre de navigation Android en bleu foncé → séparation visuelle claire
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Color(0xFF0D47A1),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await StorageService.instance.init();
  try {
    await Firebase.initializeApp();
    FirebaseService.isInitialized = true;
    debugPrint('✅ Firebase initialisé');
  } catch (e) {
    debugPrint('❌ Firebase init échoué : $e');
  }
  runApp(const HandiHubApp());
}
