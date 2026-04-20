import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../app/theme.dart';

class FavoriteContactCard extends StatelessWidget {
  const FavoriteContactCard({
    super.key,
    required this.name,
    required this.onTap,
    this.photo,
  });

  final String name;
  final Uint8List? photo;
  final VoidCallback onTap;

  String _initial() {
    if (name.isEmpty) return '?';
    if (RegExp(r'^\+?[\d\s\-]+$').hasMatch(name)) return '#';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HandiTheme.borderRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              photo != null
                  ? CircleAvatar(
                      radius: 34,
                      backgroundImage: MemoryImage(photo!),
                    )
                  : CircleAvatar(
                      radius: 34,
                      backgroundColor: HandiTheme.primary,
                      child: Text(
                        _initial(),
                        style: const TextStyle(
                          fontSize: 26,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              const SizedBox(height: 10),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: HandiTheme.textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
