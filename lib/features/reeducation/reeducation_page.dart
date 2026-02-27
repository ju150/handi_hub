import 'package:flutter/material.dart';
import '../../core/widgets/handi_scaffold.dart';

class ReeducationPage extends StatelessWidget {
  const ReeducationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HandiScaffold(
      title: 'Rééducation',
      body: Center(
        child: Text(
          'Section Rééducation\n(à venir)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, color: Colors.grey),
        ),
      ),
    );
  }
}
