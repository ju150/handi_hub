import 'package:go_router/go_router.dart';
import '../features/hub/hub_page.dart';
import '../features/games/games_page.dart';
import '../features/lecture/lecture_page.dart';
import '../features/lecture/pdf_viewer_page.dart';
import '../features/discussion/discussion_page.dart';
import '../features/reeducation/reeducation_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HubPage()),
      GoRoute(path: '/games', builder: (_, __) => const GamesPage()),
      GoRoute(
        path: '/lecture',
        builder: (_, __) => const LecturePage(),
        routes: [
          GoRoute(
            path: 'pdf/:id',
            builder: (_, state) =>
                PdfViewerPage(bookId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(path: '/discussion', builder: (_, __) => const DiscussionPage()),
      GoRoute(path: '/reeducation', builder: (_, __) => const ReeducationPage()),
    ],
  );
}
