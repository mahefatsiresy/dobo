import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'db/repositories/providers.dart';
import 'features/batches/batch_detail_screen.dart';
import 'features/batches/batches_screen.dart';
import 'features/batches/stock_screen.dart';
import 'features/batches/transfer_screen.dart';
import 'features/daily_log/daily_log_screen.dart';
import 'features/daily_log/worker_home_screen.dart';
import 'features/health/report_problem_screen.dart';
import 'features/health/treatment_screen.dart';
import 'features/more/more_screen.dart';
import 'features/people/people_screen.dart';
import 'features/people/person_form_screen.dart';
import 'features/ponds/pond_detail_screen.dart';
import 'features/ponds/pond_form_screen.dart';
import 'features/ponds/pond_overview.dart';
import 'features/ponds/ponds_screen.dart';
import 'features/readings/sample_screen.dart';
import 'features/readings/water_reading_screen.dart';
import 'features/setup/setup_screen.dart';
import 'features/transcription/transcription_screen.dart';
import 'features/visit/condition_check.dart';
import 'features/visit/visit_screen.dart';
import 'features/shell/member_shell.dart';

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
      GoRoute(
        path: '/worker',
        builder: (context, state) => const WorkerHomeScreen(),
      ),
      GoRoute(
        path: '/log/:pondId',
        builder: (context, state) {
          final date = state.uri.queryParameters['date'];
          return DailyLogScreen(
            pondId: state.pathParameters['pondId']!,
            date: date == null ? farmToday() : DateTime.parse(date),
          );
        },
      ),
      GoRoute(
        path: '/water/:pondId',
        builder: (context, state) =>
            WaterReadingScreen(pondId: state.pathParameters['pondId']!),
      ),
      GoRoute(
        path: '/sample/:pondId',
        builder: (context, state) => SampleScreen(
          pondId: state.pathParameters['pondId']!,
          batchId: state.uri.queryParameters['batchId']!,
        ),
      ),
      GoRoute(
        path: '/transfer',
        builder: (context, state) => TransferScreen(
          batchId: state.uri.queryParameters['batchId']!,
          fromPondId: state.uri.queryParameters['fromPondId'],
        ),
      ),
      GoRoute(
        path: '/stock',
        builder: (context, state) =>
            StockScreen(pondId: state.uri.queryParameters['pondId']),
      ),
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
                      GoRoute(
                        path: 'problem',
                        builder: (context, state) => ReportProblemScreen(
                          pondId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'treatment',
                        builder: (context, state) => TreatmentScreen(
                          pondId: state.pathParameters['id']!,
                        ),
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
                path: '/visit',
                builder: (context, state) => const VisitScreen(),
                routes: [
                  GoRoute(
                    path: 'conditions/:pondId',
                    builder: (context, state) => ConditionCheckScreen(
                      pondId: state.pathParameters['pondId']!,
                    ),
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
                    builder: (context, state) => const BatchesScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => BatchDetailScreen(
                          batchId: state.pathParameters['id']!,
                        ),
                        routes: [
                          GoRoute(
                            path: 'edit',
                            builder: (context, state) => BatchFormScreen(
                              batchId: state.pathParameters['id']!,
                            ),
                          ),
                          GoRoute(
                            path: 'transfers/:transferId/edit',
                            builder: (context, state) => TransferScreen(
                              batchId: state.pathParameters['id']!,
                              transferId: state.pathParameters['transferId'],
                            ),
                          ),
                          GoRoute(
                            path: 'stockings/:stockingId/edit',
                            builder: (context, state) => StockScreen(
                              batchId: state.pathParameters['id'],
                              stockingId: state.pathParameters['stockingId'],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'transcription',
                    builder: (context, state) {
                      final week = state.uri.queryParameters['week'];
                      return TranscriptionScreen(
                        week: week == null ? null : DateTime.parse(week),
                      );
                    },
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
