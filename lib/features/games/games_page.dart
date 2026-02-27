import 'package:flutter/material.dart';
import '../../core/widgets/handi_scaffold.dart';

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HandiScaffold(
      title: 'Jeux',
      body: Center(
        child: Text(
          'Section Jeux\n(à venir)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, color: Colors.grey),
        ),
      ),
    );
  }
}
