import 'package:flutter/material.dart';
import '../../core/widgets/handi_scaffold.dart';

class DiscussionPage extends StatelessWidget {
  const DiscussionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HandiScaffold(
      title: 'Discussion',
      body: Center(
        child: Text(
          'Section Discussion\n(à venir)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, color: Colors.grey),
        ),
      ),
    );
  }
}
