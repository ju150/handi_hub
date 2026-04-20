import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/hub/hub_page.dart';

// ── Imports du module Jeux ────────────────────────────────────────────────────
import '../features/games/games_page.dart';
import '../features/games/games_scores_page.dart';
import '../features/games/games_favoris_page.dart';
import '../features/games/jeux/touche_cible/touche_cible_home_page.dart';
import '../features/games/jeux/touche_cible/touche_cible_play_page.dart';
import '../features/games/jeux/memory/memory_home_page.dart';
import '../features/games/jeux/memory/memory_play_page.dart';
import '../features/games/jeux/color_match/color_match_home_page.dart';
import '../features/games/jeux/color_match/color_match_play_page.dart';
import '../features/games/jeux/candy_crush/candy_crush_home_page.dart';
import '../features/games/jeux/candy_crush/candy_crush_page.dart';

import '../features/lecture/lecture_page.dart';
import '../features/lecture/epub_viewer_page.dart';
import '../features/lecture/discover_page.dart';
import '../features/lecture/finished_page.dart';
import '../features/lecture/lecture_data.dart';
import '../features/discussion/discussion_page.dart';
import '../features/discussion/pages/discussions_list_page.dart';
import '../features/discussion/pages/conversation_page.dart';
import '../features/discussion/pages/new_message_page.dart';
import '../features/discussion/pages/favorites_config_page.dart';
import '../features/discussion/pages/discussion_settings_page.dart';
import '../features/reeducation/reeducation_page.dart';

// ── Imports partagés — modules simples (Respiration, Relaxation, Orthophonie) ──
import '../features/reeducation/shared/simple_module_page.dart';
import '../features/reeducation/shared/simple_session_page.dart';
import '../features/reeducation/respiration/respiration_catalog_service.dart';
import '../features/reeducation/relaxation/relaxation_catalog_service.dart';
import '../features/reeducation/orthophonie/orthophonie_catalog_service.dart';

// ── Imports du module Kiné ────────────────────────────────────────────────────
import '../features/reeducation/kine/pages/kine_home_page.dart';
import '../features/reeducation/kine/pages/kine_zone_page.dart';
import '../features/reeducation/kine/pages/exercise_intro_page.dart';
import '../features/reeducation/kine/pages/exercise_session_page.dart';
import '../features/reeducation/kine/pages/exercise_end_page.dart';

/// Centralise toutes les routes de l'application.
///
/// Routes du module Jeux :
///   /games                          → GamesPage (hub)
///   /games/touche-cible             → ToucheCibleHomePage
///   /games/touche-cible/play        → ToucheCiblePlayPage  (?level=0|1|2)
///   /games/memory                   → MemoryHomePage
///   /games/memory/play              → MemoryPlayPage        (?level=0|1|2)
///   /games/color-match              → ColorMatchHomePage
///   /games/color-match/play         → ColorMatchPlayPage    (?level=0|1|2)
///   /games/scores                   → GamesScoresPage
///   /games/favoris                  → GamesFavorisPage
///
/// Routes du module Kiné :
///   /reeducation/kine                              → KineHomePage
///   /reeducation/kine/zone/:zoneId                 → KineZonePage
///   /reeducation/kine/exercise/:exerciseId         → ExerciseIntroPage
///   /reeducation/kine/exercise/:exerciseId/session → ExerciseSessionPage
///   /reeducation/kine/exercise/:exerciseId/fin     → ExerciseEndPage
class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',

    routes: [
      // ── Accueil ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        builder: (_, __) => const HubPage(),
      ),

      // ── Module Jeux ───────────────────────────────────────────────────────
      GoRoute(
        path: '/games',
        builder: (_, __) => const GamesPage(),
        routes: [
          // Touche la Cible
          GoRoute(
            path: 'touche-cible',
            builder: (_, __) => const ToucheCibleHomePage(),
            routes: [
              GoRoute(
                path: 'play',
                builder: (_, state) => ToucheCiblePlayPage(
                  level: int.tryParse(
                          state.uri.queryParameters['level'] ?? '0') ??
                      0,
                ),
              ),
            ],
          ),

          // Memory
          GoRoute(
            path: 'memory',
            builder: (_, __) => const MemoryHomePage(),
            routes: [
              GoRoute(
                path: 'play',
                builder: (_, state) => MemoryPlayPage(
                  level: int.tryParse(
                          state.uri.queryParameters['level'] ?? '0') ??
                      0,
                ),
              ),
            ],
          ),

          // Match Coloré
          GoRoute(
            path: 'color-match',
            builder: (_, __) => const ColorMatchHomePage(),
            routes: [
              GoRoute(
                path: 'play',
                builder: (_, state) => ColorMatchPlayPage(
                  level: int.tryParse(
                          state.uri.queryParameters['level'] ?? '0') ??
                      0,
                ),
              ),
            ],
          ),

          // Candy Crush adapté
          GoRoute(
            path: 'candy-crush',
            builder: (_, __) => const CandyCrushHomePage(),
            routes: [
              GoRoute(
                path: 'play',
                builder: (_, __) => const CandyCrushPage(),
              ),
            ],
          ),

          // Scores & favoris transversaux
          GoRoute(
            path: 'scores',
            builder: (_, __) => const GamesScoresPage(),
          ),
          GoRoute(
            path: 'favoris',
            builder: (_, __) => const GamesFavorisPage(),
          ),
        ],
      ),

      // ── Lecture ───────────────────────────────────────────────────────────
      GoRoute(
        path: '/lecture',
        builder: (_, __) => const LecturePage(),
        routes: [
          GoRoute(
            path: 'epub/:id',
            builder: (_, state) => EpubViewerPage(
              book: state.extra as BookEntry,
            ),
          ),
          GoRoute(
            path: 'decouvrir',
            builder: (_, state) => DiscoverPage(
              books: state.extra as List<BookEntry>,
            ),
          ),
          GoRoute(
            path: 'termines',
            builder: (_, state) => FinishedPage(
              books: state.extra as List<BookEntry>,
            ),
          ),
        ],
      ),

      // ── Discussion ────────────────────────────────────────────────────────
      GoRoute(
        path: '/discussion',
        builder: (_, __) => const DiscussionPage(),
        routes: [
          GoRoute(
            path: 'conversations',
            builder: (_, __) => const DiscussionsListPage(),
          ),
          GoRoute(
            path: 'conversation/:threadId',
            builder: (_, state) {
              final tid = state.pathParameters['threadId']!;
              return ConversationPage(
                threadId: tid == 'new' ? '' : tid,
                address: state.extra as String? ?? '',
              );
            },
          ),
          GoRoute(
            path: 'settings',
            builder: (_, __) => const DiscussionSettingsPage(),
          ),
          GoRoute(
            path: 'new',
            builder: (_, state) => NewMessagePage(
              initialAddress: state.extra as String?,
            ),
          ),
          GoRoute(
            path: 'favorites-config',
            builder: (_, __) => const FavoritesConfigPage(),
          ),
        ],
      ),

      // ── Rééducation — hub des sous-modules ────────────────────────────────
      GoRoute(
        path: '/reeducation',
        builder: (_, __) => const ReeducationPage(),
      ),

      // ── Module Respiration ────────────────────────────────────────────────
      GoRoute(
        path: '/reeducation/respiration',
        builder: (_, __) => SimpleModulePage(
          title: 'Respiration',
          emoji: '🌬️',
          description: 'Exercices de respiration guidée pour calmer, oxygéner '
              'et réguler le système nerveux.',
          infoCardBgColor: const Color(0xFFE3F2FD),
          infoCardBorderColor: const Color(0xFF90CAF9),
          infoCardTextColor: const Color(0xFF1565C0),
          service: RespirationCatalogService.instance,
          sessionRoute: '/reeducation/respiration/session',
        ),
        routes: [
          GoRoute(
            path: 'session/:exerciseId',
            builder: (_, state) => SimpleSessionPage(
              exerciseId: state.pathParameters['exerciseId']!,
              service: RespirationCatalogService.instance,
              backRoute: '/reeducation/respiration',
              bgColor: const Color(0xFFF0F7FF),
              endDialogTitle: 'Exercice terminé 🎉',
              endDialogBody: 'Prenez le temps de savourer cette sensation de calme.',
            ),
          ),
        ],
      ),

      // ── Module Orthophonie ────────────────────────────────────────────────
      GoRoute(
        path: '/reeducation/orthophonie',
        builder: (_, __) => SimpleModulePage(
          title: 'Orthophonie',
          emoji: '🗣️',
          description: 'Exercices d\'articulation, de mémoire verbale et de fluence '
              'pour entretenir le langage.',
          infoCardBgColor: const Color(0xFFF3E5F5),
          infoCardBorderColor: const Color(0xFFCE93D8),
          infoCardTextColor: const Color(0xFF6A1B9A),
          service: OrthophonieCatalogService.instance,
          sessionRoute: '/reeducation/orthophonie/session',
        ),
        routes: [
          GoRoute(
            path: 'session/:exerciseId',
            builder: (_, state) => SimpleSessionPage(
              exerciseId: state.pathParameters['exerciseId']!,
              service: OrthophonieCatalogService.instance,
              backRoute: '/reeducation/orthophonie',
              bgColor: const Color(0xFFF8F0FF),
              endDialogTitle: 'Exercice terminé 🎉',
            ),
          ),
        ],
      ),

      // ── Module Relaxation ─────────────────────────────────────────────────
      GoRoute(
        path: '/reeducation/relaxation',
        builder: (_, __) => SimpleModulePage(
          title: 'Relaxation',
          emoji: '🧘',
          description: 'Exercices de détente, visualisation et pleine conscience '
              'pour réduire le stress et libérer les tensions.',
          infoCardBgColor: const Color(0xFFE8F5E9),
          infoCardBorderColor: const Color(0xFFA5D6A7),
          infoCardTextColor: const Color(0xFF2E7D32),
          service: RelaxationCatalogService.instance,
          sessionRoute: '/reeducation/relaxation/session',
        ),
        routes: [
          GoRoute(
            path: 'session/:exerciseId',
            builder: (_, state) => SimpleSessionPage(
              exerciseId: state.pathParameters['exerciseId']!,
              service: RelaxationCatalogService.instance,
              backRoute: '/reeducation/relaxation',
              bgColor: const Color(0xFFF1F8F1),
              endDialogTitle: 'Exercice terminé 🌿',
              endDialogBody: 'Profitez de cet instant de calme.',
            ),
          ),
        ],
      ),

      // ── Module Kiné ───────────────────────────────────────────────────────
      GoRoute(
        path: '/reeducation/kine',
        builder: (_, __) => const KineHomePage(),

        routes: [
          // ── Zone anatomique ──────────────────────────────────────────────
          GoRoute(
            path: 'zone/:zoneId',
            builder: (_, state) => KineZonePage(
              zoneId: state.pathParameters['zoneId']!,
            ),
          ),

          // ── Exercice individuel ──────────────────────────────────────────
          GoRoute(
            path: 'exercise/:exerciseId',
            builder: (_, state) => ExerciseIntroPage(
              exerciseId: state.pathParameters['exerciseId']!,
            ),
            routes: [
              GoRoute(
                path: 'session',
                builder: (_, state) => ExerciseSessionPage(
                  exerciseId: state.pathParameters['exerciseId']!,
                ),
              ),
              GoRoute(
                path: 'fin',
                builder: (_, state) {
                  final params = state.uri.queryParameters;
                  final steps  = int.tryParse(params['steps'] ?? '') ?? 0;
                  final total  = int.tryParse(params['total'] ?? '') ?? 0;
                  final full   = params['full'] == '1';
                  return ExerciseEndPage(
                    exerciseId:     state.pathParameters['exerciseId']!,
                    stepsCompleted: steps,
                    totalSteps:     total,
                    fullyCompleted: full,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
