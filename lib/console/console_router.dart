import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'console_shell.dart';

/// The console's pages (SPEC F16; M9 plan Decision 12). Hash URLs
/// (`/#/membres`), so the static host needs no rewrite rule.
final consoleRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/membres',
    routes: [
      GoRoute(
        path: '/fonder',
        builder: (context, state) => const _Placeholder('fonder'),
      ),
      GoRoute(
        path: '/connexion',
        builder: (context, state) => const _Placeholder('connexion'),
      ),
      ShellRoute(
        builder: (context, state, child) => ConsoleShell(child: child),
        routes: [
          for (final path in ['/association', '/groupes', '/membres', '/personnes'])
            GoRoute(
              path: path,
              builder: (context, state) => _Placeholder(path),
            ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.name);

  final String name;

  @override
  Widget build(BuildContext context) => Center(child: Text(name));
}
