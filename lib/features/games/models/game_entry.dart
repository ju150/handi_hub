import 'package:flutter/material.dart';

enum GameType { external, internal }

class GameEntry {
  final String id;
  final String title;
  final String description;
  final String shortDescription;
  final IconData icon;
  final Color color;
  final Color lightColor;
  final GameType type;
  final bool available;

  /// URL ou scheme Android pour les jeux externes.
  final String? externalUrl;

  /// Unité d'affichage du meilleur score : 'pts', 'paires', 'cibles'.
  final String scoreUnit;

  const GameEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.shortDescription,
    required this.icon,
    required this.color,
    required this.lightColor,
    required this.type,
    this.available = true,
    this.externalUrl,
    this.scoreUnit = 'pts',
  });
}
