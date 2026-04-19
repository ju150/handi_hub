import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';

class ExternalGameLauncher {
  static const String briserDesMotsPackage = 'com.fingerlab.words.block';

  static Future<void> launchBriserDesMots() async {
    if (!Platform.isAndroid) return;

    const intent = AndroidIntent(
      action: 'android.intent.action.MAIN',
      category: 'android.intent.category.LAUNCHER',
      package: briserDesMotsPackage,
    );

    await intent.launch();
  }
}
