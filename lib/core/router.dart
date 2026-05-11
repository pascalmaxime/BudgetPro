import 'package:go_router/go_router.dart';
import '../presentation/shell/shell_page.dart';
import '../presentation/dashboard/dashboard_page.dart';
import '../presentation/comptes/comptes_page.dart';
import '../presentation/abonnements/abonnements_page.dart';
import '../presentation/historique/historique_page.dart';
import '../presentation/ia/ia_page.dart';
import '../presentation/settings/settings_page.dart';

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (context, _, child) => ShellPage(child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (context, _) => const DashboardPage()),
        GoRoute(path: '/comptes', builder: (context, _) => const ComptesPage()),
        GoRoute(path: '/abonnements', builder: (context, _) => const AbonnementsPage()),
        GoRoute(path: '/historique', builder: (context, _) => const HistoriquePage()),
        GoRoute(path: '/ia', builder: (context, _) => const IaPage()),
        GoRoute(path: '/settings', builder: (context, _) => const SettingsPage()),
      ],
    ),
  ],
);
