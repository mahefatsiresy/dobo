import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'db/repositories/providers.dart';
import 'features/more/more_screen.dart';
import 'features/people/people_screen.dart';
import 'features/people/person_form_screen.dart';
import 'features/ponds/pond_detail_screen.dart';
import 'features/ponds/pond_form_screen.dart';
import 'features/ponds/ponds_screen.dart';
import 'features/setup/setup_screen.dart';
import 'features/shell/member_shell.dart';
import 'l10n/app_localizations.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final at = state.matchedLocation;
      if (!session.hasValue) return at == '/' ? null : '/';
      if (session.value == null) return at == '/setup' ? null : '/setup';
      if (at == '/' || at == '/setup') return '/ponds';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/setup', builder: (context, state) => const SetupScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MemberShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ponds',
                builder: (context, state) => const PondsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const PondFormScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        PondDetailScreen(pondId: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) =>
                            PondFormScreen(pondId: state.pathParameters['id']),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MoreScreen(),
                routes: [
                  GoRoute(
                    path: 'batches',
                    builder: (context, state) => PlaceholderTab(
                      title: AppLocalizations.of(context).moreBatches,
                    ),
                  ),
                  GoRoute(
                    path: 'people',
                    builder: (context, state) => const PeopleScreen(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (context, state) => const PersonFormScreen(),
                      ),
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => PersonFormScreen(
                          personId: state.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.listen(sessionProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});
