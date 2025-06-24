import 'package:go_router/go_router.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_screen.dart';
import 'screens/signalement_screen.dart';
import 'screens/map_screen.dart';
import 'screens/profil_screen.dart';
import 'screens/mes_signalement_screen.dart';
import 'screens/signets_screen.dart';
import 'navigation.dart';
import '../models/signalement.dart';
import 'utils/navigator_key.dart';

final GoRouter router = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/',
  routes: [
    // ShellRoute pour la BottomNavigationBar
    ShellRoute(
      builder: (context, state, child) {
        return RootScreen(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/signets',
          builder: (context, state) => const SignetsScreen(),
        ),
        GoRoute(
          path: '/add',
          builder: (context, state) => AddScreen(),
        ),
        GoRoute(
          path: '/edit',
          builder: (context, state) {
            final signalement = state.extra as Signalement;
            return AddScreen(signalementExist: signalement);
          },
        ),
        GoRoute(
          path: '/mes_signalements',
          builder: (context, state) => const MesSignalementsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),

    // Routes sans BottomNavigationBar
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => RegisterScreen(),
    ),
    GoRoute(
      path: '/signalement/:id',
      builder: (context, state) {
        final signalementId = state.pathParameters['id'];
        return SignalementScreen(signalementId: signalementId!);
      },
    ),
    GoRoute(
      path: '/map',
      builder: (context, state) {
        return MapScreen(
          isEditMode: false,  // par défaut (mode création)
          isViewMode: false,
        );
      },
    ),
    GoRoute(
      path: '/map/:mode',
      builder: (context, state) {
        final mode = state.pathParameters['mode'];
        final signalement = state.extra as Signalement?;

        return MapScreen(
          signalement: signalement,
          isViewMode: mode == 'view',
          isEditMode: mode == 'edit',
        );
      },
    ),
  ],
);
