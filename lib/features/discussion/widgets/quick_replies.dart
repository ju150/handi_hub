import 'package:flutter/material.dart';
import '../../../app/theme.dart';

const _kReplies = [
  'Bonjour',
  'Tout va bien',
  "Peux-tu m'appeler ?",
  'Merci',
  'Je réponds plus tard',
  "J'ai besoin d'aide",
];

class QuickReplies extends StatelessWidget {
  const QuickReplies({super.key, required this.onSelect});

  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      color: const Color(0xFFF0F4FF),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _kReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final reply = _kReplies[i];
          return OutlinedButton(
            onPressed: () => onSelect(reply),
            style: OutlinedButton.styleFrom(
              foregroundColor: HandiTheme.primary,
              side: const BorderSide(color: HandiTheme.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              minimumSize: const Size(0, 52),
            ),
            child: Text(
              reply,
              style: const TextStyle(fontSize: HandiTheme.fontSize),
            ),
          );
        },
      ),
    );
  }
}
