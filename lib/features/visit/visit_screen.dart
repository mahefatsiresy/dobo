import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../db/repositories/providers.dart';
import '../../domain/dates.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../../theme/tokens.dart';
import '../admin/members_screen.dart' show membersProvider;
import '../common/choice_buttons.dart';
import '../common/pond_choice.dart';
import '../common/folded_section.dart';
import '../common/save_once.dart';
import '../ponds/pond_overview.dart';
import 'visit_checklist.dart';
import 'visit_pond_group.dart';
import 'visit_providers.dart';

/// The Visit tab (SPEC F5, docs/design.md §Step 5). Before a visit: what
/// one today would cover. During it: the ponds in code order, each with
/// its band and its checks, as the member walks the dike; "Terminer" is
/// pinned, and the summary is written in the report draft.
class VisitScreen extends ConsumerStatefulWidget {
  const VisitScreen({super.key});

  @override
  ConsumerState<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends ConsumerState<VisitScreen> with SaveOnce {
  Future<void> _end(Visit visit, VisitChecklist? checklist) async {
    final l10n = AppLocalizations.of(context);
    final left = checklist?.open ?? const [];
    final items = [
      for (final (pond, check) in left)
        switch (check) {
          WaterCheck() => l10n.leftWater(pond.code),
          SampleCheck(:final batch) => l10n.leftSample(batch.code),
          InspectionCheck() => l10n.leftInspection(pond.code),
        },
    ];
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        // A long list in Malagasy at large text must not cut the question.
        scrollable: true,
        content: Text(
          items.isEmpty
              ? l10n.endVisitConfirm
              : l10n.endVisitLeft(
                  items.length,
                  items.join(l10n.reportListSeparator),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.endVisit),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(visitRepositoryProvider).end(visit.id);
    // The report is reviewed and published straight away (SPEC F8).
    if (mounted) context.go('/reports/draft/${visit.id}');
  }

  Future<void> _addObservation() async {
    final result = await showDialog<(String?, ObservationCategory, String)>(
      context: context,
      builder: (context) => const _ObservationDialog(),
    );
    if (result == null || result.$3.isEmpty) return;
    await ref
        .read(observationRepositoryProvider)
        .addObservation(
          pondId: result.$1,
          category: result.$2,
          note: result.$3,
        );
  }

  /// The main action, pinned under the thumb.
  Widget _pinned(IconData icon, String label, VoidCallback? onPressed) =>
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final open = ref.watch(openVisitProvider);
    if (!open.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final visit = open.value;
    if (visit == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.tabVisit)),
        bottomNavigationBar: _pinned(
          Icons.play_arrow,
          l10n.startVisit,
          saving
              ? null
              : () => saveOnce(() => ref.read(visitRepositoryProvider).start()),
        ),
        body: _start(l10n),
      );
    }
    final checklist = ref.watch(checklistProvider(visit.id));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabVisit)),
      bottomNavigationBar: _pinned(
        Icons.flag,
        l10n.endVisit,
        () => _end(visit, checklist),
      ),
      body: _checklist(l10n, visit, checklist),
    );
  }

  Widget _start(AppLocalizations l10n) {
    final preview = ref.watch(visitPreviewProvider);
    if (preview == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final text = Theme.of(context).textTheme;
    int count<T extends VisitCheck>() =>
        [for (final p in preview.ponds) ...p.checks.whereType<T>()].length;
    final water = count<WaterCheck>(),
        samples = count<SampleCheck>(),
        inspections = count<InspectionCheck>();
    final lines = [
      if (water > 0) (Icons.water_drop, l10n.visitWaterCount(water)),
      if (samples > 0) (Icons.scale, l10n.visitSampleCount(samples)),
      if (inspections > 0)
        (Icons.fact_check, l10n.visitInspectCount(inspections)),
    ];
    final last = (ref.watch(visitsProvider).value ?? const <Visit>[])
        .where((v) => v.endedAt != null)
        .firstOrNull;
    final member = last == null
        ? null
        : (ref.watch(membersProvider).value ?? const <Member>[])
              .where((m) => m.id == last.enteredBy)
              .firstOrNull;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.visitTodayHeading, style: text.titleMedium),
        const SizedBox(height: 8),
        for (final (icon, line) in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 12),
                Expanded(child: Text(line, style: text.bodyLarge)),
              ],
            ),
          ),
        if (last != null && member != null) ...[
          const SizedBox(height: 16),
          Text(
            l10n.visitLast(formatDate(last.startedAt), member.name),
            style: text.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _checklist(
    AppLocalizations l10n,
    Visit visit,
    VisitChecklist? checklist,
  ) {
    final text = Theme.of(context).textTheme;
    final c = context.dobo;
    // Farm time (CLAUDE.md §Time), whatever zone the phone is set to.
    final farm = visit.startedAt.toUtc().add(farmUtcOffset);
    final started = TimeOfDay(hour: farm.hour, minute: farm.minute);
    final bio = [
      l10n.bioDisinfect,
      l10n.bioToolsPerPond,
      l10n.bioFootbath,
      l10n.bioAnimals,
      l10n.bioPredators,
      l10n.bioProtection,
      l10n.bioNotAlone,
    ];
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.visitOpenSince(started.format(context)),
                  style: text.titleMedium,
                ),
              ),
              if (checklist != null) ...[
                // Green only once something is done (colour means something).
                if (checklist.done > 0) ...[
                  Icon(Icons.check_circle, color: c.ok),
                  const SizedBox(width: 4),
                ],
                Text(
                  l10n.visitProgress(checklist.done, checklist.total),
                  style: text.titleMedium,
                ),
              ],
            ],
          ),
        ),
        if (checklist == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          for (final p in checklist.ponds) ...[
            const Divider(height: 1),
            VisitPondGroup(visit: p),
          ],
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(l10n.sectionObservations, style: text.titleMedium),
          ),
          for (final o in checklist.farmObservations)
            ObservationLine(observation: o),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(minimumSize: const Size(56, 56)),
              onPressed: _addObservation,
              icon: const Icon(Icons.add),
              label: Text(l10n.addObservation),
            ),
          ),
        ),
        const Divider(height: 1),
        FoldedSection(
          title: l10n.sectionBiosecurity,
          summary: l10n.bioReminders(bio.length),
          builder: (context) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                for (final item in bio)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined),
                        const SizedBox(width: 12),
                        Expanded(child: Text(item, style: text.bodyLarge)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A free observation, about one pond or none. The dialog owns its
/// controller: the closing dialog is still rebuilt (the keyboard going
/// away) after showDialog has returned.
class _ObservationDialog extends ConsumerStatefulWidget {
  const _ObservationDialog();

  @override
  ConsumerState<_ObservationDialog> createState() => _ObservationDialogState();
}

class _ObservationDialogState extends ConsumerState<_ObservationDialog> {
  final _text = TextEditingController();
  var _category = ObservationCategory.other;
  String? _pondId;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ponds = [
      for (final o
          in ref.watch(pondOverviewsProvider).value ?? const <PondOverview>[])
        o.pond,
    ]..sort((a, b) => a.code.compareTo(b.code));
    return AlertDialog(
      title: Text(l10n.addObservation),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ponds.isNotEmpty) ...[
              Text(
                l10n.observationPond,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              PondChoice(
                options: [for (final p in ponds) PondOption(pond: p)],
                value: _pondId,
                allowNone: true,
                onChanged: (v) => setState(() => _pondId = v),
              ),
              const SizedBox(height: 16),
            ],
            ChoiceField<ObservationCategory>(
              label: l10n.category,
              options: [
                for (final c in ObservationCategory.values)
                  (c, l10n.observationCategory(c)),
              ],
              value: _category,
              onChanged: (c) => setState(() => _category = c),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _text,
              decoration: InputDecoration(labelText: l10n.observationText),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, (_pondId, _category, _text.text.trim())),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
