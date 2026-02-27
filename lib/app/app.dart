import 'package:flutter/material.dart';
import 'router.dart';
import 'theme.dart';

class HandiHubApp extends StatelessWidget {
  const HandiHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HandiHub',
      theme: HandiTheme.theme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
