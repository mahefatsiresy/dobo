import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/tokens.dart';
import '../common/attention_band.dart';
import '../common/pond_colour.dart';
import '../ponds/pond_attention.dart';
import '../ponds/pond_overview.dart';
import '../ponds/pond_row.dart';
import 'alert_providers.dart';
import 'alert_route.dart';
import 'alert_sections.dart';

/// What needs doing across the farm, most urgent first (SPEC F7,
/// docs/design.md §Step 4): danger, then what is to do, each in pond code
/// order; every band opens the screen that fixes it.
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final alerts = ref.watch(alertsProvider).value;
    final overviews = ref.watch(pondOverviewsProvider).value;
    final Widget body;
    if (alerts == null || overviews == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final s = alertSections(overviews, alerts);
      final byPond = {for (final o in overviews) o.pond.id: o};
      Widget band(SectionItem item, BandSeverity severity) {
        final pond = item.pond;
        final route = switch (item.lead) {
          LeadAlert(:final alert) => alertRoute(alert),
          _ => '/ponds/${pond!.id}',
        };
        final c = context.dobo;
        // A 2 dp gap: each band is its own row to tap.
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: AttentionBand(
            severity: severity,
            text: leadText(l10n, item.lead, byPond[pond?.id]),
            // The ponds list's slot: every row's icon lines up, and a long
            // code shrinks instead of squeezing the text.
            leading: pond == null
                ? null
                : SizedBox(
                    key: const ValueKey('codeSlot'),
                    width: 72,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: PondCode(
                        code: pond.code,
                        colour: pond.colour,
                        ink: severity == BandSeverity.danger ? c.paper : c.ink,
                      ),
                    ),
                  ),
            onTap: route == null ? null : () => context.push(route),
          ),
        );
      }

      body = s.danger.isEmpty && s.todo.isEmpty
          ? const _NothingOpen()
          : ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                if (s.danger.isNotEmpty) ...[
                  _Heading(l10n.alertsDanger),
                  for (final i in s.danger) band(i, BandSeverity.danger),
                ],
                if (s.todo.isNotEmpty) ...[
                  _Heading(l10n.alertsTodo),
                  for (final i in s.todo) band(i, BandSeverity.warning),
                ],
              ],
            );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabAlerts)),
      body: body,
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

/// Nothing to do: one line with a large tick.
class _NothingOpen extends StatelessWidget {
  const _NothingOpen();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.task_alt, color: context.dobo.ok, size: 48),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).alertsEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    ),
  );
}
