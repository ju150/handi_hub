import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.init();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase non configuré : mode dégradé local uniquement
  }
  runApp(const HandiHubApp());
}
