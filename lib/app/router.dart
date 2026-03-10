import 'package:go_router/go_router.dart';
import '../features/hub/hub_page.dart';
import '../features/games/games_page.dart';
import '../features/lecture/lecture_page.dart';
import '../features/lecture/epub_viewer_page.dart';
import '../features/lecture/discover_page.dart';
import '../features/lecture/finished_page.dart';
import '../features/lecture/lecture_data.dart';
import '../features/discussion/discussion_page.dart';
import '../features/reeducation/reeducation_page.dart';

/// Centralise toutes les routes de l'application.
///
/// Cette classe contient l'instance unique de GoRouter utilisée dans main.dart
/// pour gérer la navigation entre les différentes pages.
class AppRouter {
  static final router = GoRouter(
    // Route affichée au lancement de l'application
    initialLocation: '/',

    // Liste de toutes les routes disponibles
    routes: [
      // Page d'accueil principale
      GoRoute(
        path: '/',
        builder: (_, __) => const HubPage(),
      ),

      // Page des jeux
      GoRoute(
        path: '/games',
        builder: (_, __) => const GamesPage(),
      ),

      // Section lecture
      GoRoute(
        path: '/lecture',
        builder: (_, __) => const LecturePage(),

        // Sous-routes de /lecture
        routes: [
          // Lecteur EPUB pour un livre donné
          // Exemple d'URL : /lecture/epub/le_petit_prince
          GoRoute(
            path: 'epub/:id',
            builder: (_, state) => EpubViewerPage(
              // On récupère ici l'objet BookEntry transmis via extra
              book: state.extra as BookEntry,
            ),
          ),

          // Page "Découvrir"
          // Reçoit une liste de livres via state.extra
          GoRoute(
            path: 'decouvrir',
            builder: (_, state) => DiscoverPage(
              books: state.extra as List<BookEntry>,
            ),
          ),

          // Page des livres terminés
          // Reçoit aussi une liste de livres via state.extra
          GoRoute(
            path: 'termines',
            builder: (_, state) => FinishedPage(
              books: state.extra as List<BookEntry>,
            ),
          ),
        ],
      ),

      // Page discussion
      GoRoute(
        path: '/discussion',
        builder: (_, __) => const DiscussionPage(),
      ),

      // Page rééducation
      GoRoute(
        path: '/reeducation',
        builder: (_, __) => const ReeducationPage(),
      ),
    ],
  );
}