import 'package:flutter/material.dart';
import '../models/game_entry.dart';
import '../theme/games_theme.dart';

// ─── Catalogue des jeux ───────────────────────────────────────────────────────

final List<GameEntry> allGames = [
  const GameEntry(
    id:               'briser-mots',
    title:            'Briser des Mots',
    description:      'Ton jeu de lettres préféré !\nForme des mots, explose les lettres et bats ton record.',
    shortDescription: 'Jeu de lettres',
    icon:             Icons.military_tech_rounded,
    color:            GamesTheme.briserMotsColor,
    lightColor:       GamesTheme.briserMotsLight,
    type:             GameType.external,
    // TODO: remplacer par le vrai URL scheme ou package Android de Briser des Mots
    externalUrl: null,
  ),
  const GameEntry(
    id:               'touche-cible',
    title:            'Touche la Cible',
    description:      'Des cibles colorées apparaissent à l\'écran — touche-les avant qu\'elles ne disparaissent !',
    shortDescription: 'Réflexes',
    icon:             Icons.my_location_rounded,
    color:            GamesTheme.toucheCibleColor,
    lightColor:       GamesTheme.toucheCibleLight,
    type:             GameType.internal,
    scoreUnit:        'cibles',
  ),
  const GameEntry(
    id:               'memory',
    title:            'Memory',
    description:      'Retrouve les paires de cartes identiques. Entraîne ta mémoire avec des niveaux progressifs.',
    shortDescription: 'Mémoire',
    icon:             Icons.grid_view_rounded,
    color:            GamesTheme.memoryColor,
    lightColor:       GamesTheme.memoryLight,
    type:             GameType.internal,
    scoreUnit:        'paires',
  ),
  const GameEntry(
    id:               'color-match',
    title:            'Match Coloré',
    description:      'Touche un groupe de couleurs identiques pour le faire exploser et marquer des points !',
    shortDescription: 'Couleurs',
    icon:             Icons.bubble_chart_rounded,
    color:            GamesTheme.colorMatchColor,
    lightColor:       GamesTheme.colorMatchLight,
    type:             GameType.internal,
  ),
  const GameEntry(
    id:               'candy-crush',
    title:            'Candy Crush adapté',
    description:      'Aligne des bonbons colorés pour faire exploser les rangées et progresser de niveau en niveau !',
    shortDescription: 'Bonbons',
    icon:             Icons.diamond_rounded,
    color:            GamesTheme.candyCrushColor,
    lightColor:       GamesTheme.candyCrushLight,
    type:             GameType.internal,
  ),
];

GameEntry? getGameById(String id) {
  try {
    return allGames.firstWhere((g) => g.id == id);
  } catch (_) {
    return null;
  }
}

// ─── Config niveaux : Touche la Cible ─────────────────────────────────────────
// targetSize    : diamètre des cibles en dp
// targetDuration: secondes avant qu'une cible disparaisse
// maxTargets    : nombre de cibles simultanées à l'écran
// gameDuration  : durée totale de la partie en secondes

const List<Map<String, dynamic>> toucheCibleLevelConfig = [
  {
    'label':          'Facile',
    'targetSize':     150.0,
    'targetDuration': 6,
    'maxTargets':     1,
    'gameDuration':   60,
  },
  {
    'label':          'Normal',
    'targetSize':     120.0,
    'targetDuration': 4,
    'maxTargets':     2,
    'gameDuration':   60,
  },
  {
    'label':          'Rapide',
    'targetSize':     100.0,
    'targetDuration': 3,
    'maxTargets':     3,
    'gameDuration':   90,
  },
];

// ─── Config niveaux : Memory ──────────────────────────────────────────────────
// cols / rows : grille de cartes
// pairs       : nombre de paires à trouver (= cols*rows/2)

const List<Map<String, dynamic>> memoryLevelConfig = [
  {'label': 'Facile',   'cols': 3, 'rows': 2, 'pairs': 3,  'symbolSet': 0},
  {'label': 'Normal',   'cols': 4, 'rows': 3, 'pairs': 6,  'symbolSet': 1},
  {'label': 'Difficile','cols': 4, 'rows': 4, 'pairs': 8,  'symbolSet': 2},
];

// Symboles emoji par set (index = symbolSet dans memoryLevelConfig)
const List<List<String>> memorySymbolSets = [
  ['🍎', '🍊', '🍋'],
  ['🐶', '🐱', '🐸', '🦋', '🐢', '🦜'],
  ['⭐', '🌈', '🎈', '🎮', '🏆', '🎵', '🌸', '💎'],
];

// ─── Config niveaux : Color Match ─────────────────────────────────────────────
// cols / rows   : grille
// numColors     : nombre de couleurs différentes utilisées
// targetScore   : score à atteindre pour remporter la partie

const List<Map<String, dynamic>> colorMatchLevelConfig = [
  {'label': 'Facile',  'cols': 5, 'rows': 6, 'numColors': 3, 'targetScore': 50},
  {'label': 'Normal',  'cols': 6, 'rows': 7, 'numColors': 4, 'targetScore': 100},
  {'label': 'Expert',  'cols': 7, 'rows': 8, 'numColors': 5, 'targetScore': 200},
];
