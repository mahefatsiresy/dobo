import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'console_providers.dart';
import 'console_shell.dart';
import 'pages/association_page.dart';
import 'pages/found_page.dart';
import 'pages/groups_page.dart';
import 'pages/members_page.dart';
import 'pages/people_page.dart';
import 'pages/sign_in_page.dart';

/// Pages anyone may open; the others are for a signed-in admin.
const _public = {'/connexion', '/fonder'};

/// The console's pages (SPEC F16; M9 plan Decision 12). Hash URLs
/// (`/#/membres`), so the static host needs no rewrite rule.
final consoleRouterProvider = Provider<GoRouter>((ref) {
  final session = ValueNotifier(0);
  ref.listen(consoleSessionProvider, (_, _) => session.value++);
  final router = GoRouter(
    initialLocation: '/membres',
    refreshListenable: session,
    redirect: (context, state) {
      final s = ref.read(consoleSessionProvider);
      final at = state.matchedLocation;
      if (s.isLoading && !s.hasValue) {
        return at == '/' || _public.contains(at) ? null : '/';
      }
      final me = s.value;
      if (me == null) return _public.contains(at) ? null : '/connexion';
      return at == '/' || _public.contains(at) ? '/membres' : null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/fonder', builder: (context, state) => const FoundPage()),
      GoRoute(
        path: '/connexion',
        builder: (context, state) => const SignInPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => ConsoleShell(child: child),
        routes: [
          GoRoute(
            path: '/association',
            builder: (context, state) => const AssociationPage(),
          ),
          GoRoute(
            path: '/groupes',
            builder: (context, state) => const GroupsPage(),
          ),
          GoRoute(
            path: '/membres',
            builder: (context, state) => const MembersPage(),
          ),
          GoRoute(
            path: '/personnes',
            builder: (context, state) => const PeoplePage(),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    session.dispose();
  });
  return router;
});
