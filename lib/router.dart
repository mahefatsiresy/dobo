import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/common/farm_today.dart';

import 'db/repositories/providers.dart';
import 'features/sales/customers_screen.dart';
import 'features/sales/harvest_screen.dart';
import 'features/sales/sale_screen.dart';
import 'features/sales/sales_screen.dart';
import 'features/feed/feed_delivery_screen.dart';
import 'features/feed/feed_discard_screen.dart';
import 'features/feed/feed_stock_screen.dart';
import 'features/prep/prep_screen.dart';
import 'features/alerts/alerts_screen.dart';
import 'features/batches/batch_detail_screen.dart';
import 'features/batches/batches_screen.dart';
import 'features/batches/stock_screen.dart';
import 'features/batches/transfer_screen.dart';
import 'features/daily_log/daily_log_screen.dart';
import 'features/daily_log/duplicate_logs_screen.dart';
import 'features/daily_log/worker_home_screen.dart';
import 'features/health/report_problem_screen.dart';
import 'features/health/treatment_screen.dart';
import 'features/more/more_screen.dart';
import 'features/people/people_screen.dart';
import 'features/people/person_form_screen.dart';
import 'features/ponds/pond_detail_screen.dart';
import 'features/ponds/pond_form_screen.dart';
import 'features/ponds/ponds_screen.dart';
import 'features/readings/sample_screen.dart';
import 'features/reports/report_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/readings/water_reading_screen.dart';
import 'features/setup/setup_screen.dart';
import 'features/account/account_screen.dart';
import 'features/account/login_screen.dart';
import 'features/account/welcome_screen.dart';
import 'features/sync/sync_screen.dart';
import 'features/admin/admin_screen.dart';
import 'features/admin/groups_screen.dart';
import 'features/admin/member_form_screen.dart';
import 'features/admin/members_screen.dart';
import 'features/admin/settings_screen.dart';
import 'sync/providers.dart';
import 'features/exports/exports_screen.dart';
import 'features/paper/paper_sheet_screen.dart';
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
      final s = session.value;
      final signingIn = at == '/welcome/login';
      if (s == null) {
        // A build with no server sets the phone up offline, as before M4.
        if (ref.read(authGatewayProvider) == null) {
          return at == '/welcome/local' ? null : '/welcome/local';
        }
        return at.startsWith('/welcome') && at != '/welcome/local'
            ? null
            : '/welcome';
      }
      // The worker's whole app is the worker home and the daily log.
      if (s.isWorker) {
        return at == '/worker' || at.startsWith('/log/') || signingIn
            ? null
            : '/worker';
      }
      if (at == '/' || at == '/welcome' || at == '/welcome/local') {
        return '/ponds';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
        routes: [
          GoRoute(
            path: 'login',
            builder: (context, state) => LoginScreen(
              worker: state.uri.queryParameters['worker'] == '1',
              takeover: state.uri.queryParameters['takeover'] == '1',
            ),
          ),
          GoRoute(
            path: 'local',
            builder: (context, state) => const SetupScreen(),
          ),
        ],
      ),
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
            // The app's clock, so a test or the demo farm logs its own day.
            date: date == null
                ? ref.read(farmTodayProvider)
                : DateTime.parse(date),
            showLot: state.uri.queryParameters['lot'] == '1',
          );
        },
      ),
      GoRoute(
        path: '/water/:pondId',
        builder: (context, state) => WaterReadingScreen(
          pondId: state.pathParameters['pondId']!,
          readingId: state.uri.queryParameters['readingId'],
        ),
      ),
      GoRoute(
        path: '/sample/:pondId',
        builder: (context, state) => SampleScreen(
          pondId: state.pathParameters['pondId']!,
          batchId: state.uri.queryParameters['batchId']!,
          sampleId: state.uri.queryParameters['sampleId'],
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
                        path: 'duplicates',
                        builder: (context, state) => DuplicateLogsScreen(
                          pondId: state.pathParameters['id']!,
                          date: DateTime.parse(
                            state.uri.queryParameters['date']!,
                          ),
                        ),
                      ),
                      GoRoute(
                        path: 'treatment',
                        builder: (context, state) => TreatmentScreen(
                          pondId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'prep',
                        builder: (context, state) =>
                            PrepScreen(pondId: state.pathParameters['id']!),
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
                path: '/alerts',
                builder: (context, state) => const AlertsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportsScreen(),
                routes: [
                  GoRoute(
                    path: 'draft/:visitId',
                    builder: (context, state) => ReportScreen.draft(
                      visitId: state.pathParameters['visitId']!,
                    ),
                  ),
                  GoRoute(
                    path: ':reportId',
                    builder: (context, state) => ReportScreen.published(
                      reportId: state.pathParameters['reportId']!,
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
                            path: 'harvest',
                            builder: (context, state) => HarvestScreen(
                              batchId: state.pathParameters['id']!,
                            ),
                          ),
                          GoRoute(
                            path: 'harvests/:harvestId/edit',
                            builder: (context, state) => HarvestScreen(
                              batchId: state.pathParameters['id']!,
                              harvestId: state.pathParameters['harvestId'],
                            ),
                          ),
                          GoRoute(
                            path: 'sell',
                            builder: (context, state) => SaleScreen(
                              batchId: state.pathParameters['id']!,
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
                    path: 'sales',
                    builder: (context, state) => const SalesScreen(),
                    routes: [
                      GoRoute(
                        path: 'customers',
                        builder: (context, state) => const CustomersScreen(),
                        routes: [
                          GoRoute(
                            path: 'new',
                            builder: (context, state) =>
                                const CustomerFormScreen(),
                          ),
                          GoRoute(
                            path: ':customerId',
                            builder: (context, state) => CustomerFormScreen(
                              customerId: state.pathParameters['customerId'],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'feed',
                    builder: (context, state) => const FeedStockScreen(),
                    routes: [
                      GoRoute(
                        path: 'deliver',
                        builder: (context, state) => const FeedDeliveryScreen(),
                      ),
                      GoRoute(
                        path: ':lotId',
                        builder: (context, state) => FeedDeliveryScreen(
                          lotId: state.pathParameters['lotId']!,
                        ),
                      ),
                      GoRoute(
                        path: ':lotId/discard',
                        builder: (context, state) => FeedDiscardScreen(
                          lotId: state.pathParameters['lotId']!,
                        ),
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
                    path: 'paper',
                    builder: (context, state) => const PaperSheetScreen(),
                  ),
                  GoRoute(
                    path: 'exports',
                    builder: (context, state) {
                      DateTime? day(String key) {
                        final v = state.uri.queryParameters[key];
                        return v == null ? null : DateTime.parse(v);
                      }

                      return ExportsScreen(from: day('from'), to: day('to'));
                    },
                  ),
                  GoRoute(
                    path: 'account',
                    builder: (context, state) => const AccountScreen(),
                  ),
                  GoRoute(
                    path: 'sync',
                    builder: (context, state) => const SyncScreen(),
                  ),
                  GoRoute(
                    path: 'admin',
                    builder: (context, state) => const AdminScreen(),
                    routes: [
                      GoRoute(
                        path: 'members',
                        builder: (context, state) => const MembersScreen(),
                        routes: [
                          GoRoute(
                            path: 'new',
                            builder: (context, state) =>
                                const MemberFormScreen(),
                          ),
                          GoRoute(
                            path: ':id',
                            builder: (context, state) => MemberFormScreen(
                              memberId: state.pathParameters['id'],
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'groups',
                        builder: (context, state) => const GroupsScreen(),
                      ),
                      GoRoute(
                        path: 'settings',
                        builder: (context, state) => const SettingsScreen(),
                      ),
                    ],
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
