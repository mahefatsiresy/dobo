import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../db/repositories/errors.dart';
import '../../db/repositories/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../admin/members_screen.dart';
import '../common/save_once.dart';
import '../people/people_providers.dart';

final _logsForDayProvider = StreamProvider.autoDispose
    .family<List<DailyLog>, (String, DateTime)>(
      (ref, key) => ref
          .watch(dailyLogRepositoryProvider)
          .watchCurrentForDay(key.$1, key.$2),
    );

/// Two phones logged the same pond-day: the member sees every field of each
/// and keeps one; the others get a tombstone (SPEC §7).
class DuplicateLogsScreen extends ConsumerStatefulWidget {
  const DuplicateLogsScreen({
    super.key,
    required this.pondId,
    required this.date,
  });

  final String pondId;

  /// Farm date.
  final DateTime date;

  @override
  ConsumerState<DuplicateLogsScreen> createState() =>
      _DuplicateLogsScreenState();
}

class _DuplicateLogsScreenState extends ConsumerState<DuplicateLogsScreen>
    with SaveOnce {
  Future<void> _keep(DailyLog keep, List<DailyLog> all) => saveOnce(() async {
    try {
      await ref.read(dailyLogRepositoryProvider).keepOnly(keep.id, [
        for (final l in all)
          if (l.id != keep.id) l.id,
      ]);
    } on StaleEventException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).staleRecord)),
        );
      }
    }
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final logs = ref
        .watch(_logsForDayProvider((widget.pondId, widget.date)))
        .value;
    final members = {
      for (final m in ref.watch(membersProvider).value ?? const <Member>[])
        m.id: m.name,
    };
    final people = {
      for (final p in ref.watch(peopleProvider).value ?? const <Person>[])
        p.id: p.name,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.alertDuplicateLog(formatDate(widget.date))),
      ),
      body: logs == null
          ? const Center(child: CircularProgressIndicator())
          : logs.length < 2
          ? Center(child: Text(l10n.duplicateResolved))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final log in logs)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${l10n.feedGiven} : '
                            '${formatKg(log.feedGivenG, locale)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text('${l10n.deaths} : ${log.deaths}'),
                          if (log.feedings != null)
                            Text('${l10n.feedings} : ${log.feedings}'),
                          if (log.leftover != null)
                            Text(
                              '${l10n.leftovers} : '
                              '${l10n.leftover(log.leftover!)}'
                              '${log.ateFast ? ' · ${l10n.ateFast}' : ''}',
                            ),
                          if (log.waterColour != null)
                            Text(
                              '${l10n.waterColourLabel} : '
                              '${l10n.waterColour(log.waterColour!)}',
                            ),
                          if (log.note != null && log.note!.isNotEmpty)
                            Text('${l10n.noteLabel} : ${log.note}'),
                          if (log.warningSigns.isNotEmpty ||
                              log.deathSigns.isNotEmpty)
                            Text(
                              {
                                ...log.warningSigns,
                                ...log.deathSigns,
                              }.map(l10n.warningSign).join(', '),
                            ),
                          Text(
                            l10n.duplicateEnteredBy(
                              members[log.enteredBy] ??
                                  l10n.duplicateOtherPhone,
                            ),
                          ),
                          if (log.observedBy != null)
                            Text(
                              l10n.duplicateObservedBy(
                                people[log.observedBy] ?? '?',
                              ),
                            ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                            ),
                            onPressed: saving ? null : () => _keep(log, logs),
                            icon: const Icon(Icons.check),
                            label: Text(l10n.duplicateKeep),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
