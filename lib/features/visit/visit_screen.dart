import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../db/repositories/providers.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../common/pond_colour.dart';
import '../common/save_once.dart';
import '../photos/photo_strip.dart';
import 'visit_providers.dart';
import '../../theme/tokens.dart';

/// The Visit tab (SPEC F5): start a visit, then walk its checklist; past
/// visits below. The report itself comes in M6.
class VisitScreen extends ConsumerStatefulWidget {
  const VisitScreen({super.key});

  @override
  ConsumerState<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends ConsumerState<VisitScreen> with SaveOnce {
  final _summary = TextEditingController();
  final _summaryFocus = FocusNode();
  String? _summaryOf;
  final _biosecurity = <int>{};

  @override
  void initState() {
    super.initState();
    _summaryFocus.addListener(() {
      if (!_summaryFocus.hasFocus) _saveSummary();
    });
  }

  @override
  void dispose() {
    _summary.dispose();
    _summaryFocus.dispose();
    super.dispose();
  }

  Future<void> _saveSummary() async {
    final id = _summaryOf;
    if (id == null) return;
    final text = _summary.text.trim();
    await ref
        .read(visitRepositoryProvider)
        .setSummary(id, text.isEmpty ? null : text);
  }

  Future<void> _end(Visit visit) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.endVisitConfirm),
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
    await _saveSummary();
    await ref.read(visitRepositoryProvider).end(visit.id);
    setState(() {
      _summaryOf = null;
      _summary.clear();
      _biosecurity.clear();
    });
    // The report is reviewed and published straight away (SPEC F8).
    if (mounted) context.go('/reports/draft/${visit.id}');
  }

  Future<void> _addObservation() async {
    final result = await showDialog<(ObservationCategory, String)>(
      context: context,
      builder: (context) => const _ObservationDialog(),
    );
    if (result == null || result.$2.isEmpty) return;
    await ref
        .read(observationRepositoryProvider)
        .addObservation(category: result.$1, note: result.$2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final open = ref.watch(openVisitProvider);
    if (!open.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final visit = open.value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabVisit)),
      body: visit == null ? _start(l10n) : _checklist(l10n, visit),
    );
  }

  Widget _start(AppLocalizations l10n) {
    final visits = ref.watch(visitsProvider).value ?? const [];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
          onPressed: saving
              ? null
              : () => saveOnce(() => ref.read(visitRepositoryProvider).start()),
          icon: const Icon(Icons.play_arrow),
          label: Text(l10n.startVisit),
        ),
        const SizedBox(height: 24),
        Text(l10n.pastVisits, style: Theme.of(context).textTheme.titleMedium),
        if (visits.isEmpty) Text(l10n.noVisits),
        for (final v in visits)
          ListTile(
            minTileHeight: 56,
            leading: const Icon(Icons.event),
            title: Text(
              l10n.visitLine(
                formatDate(v.startedAt),
                v.endedAt == null ? l10n.visitOngoing : l10n.visitEnded,
              ),
            ),
            subtitle: v.summary == null
                ? null
                : Text(
                    v.summary!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
      ],
    );
  }

  Widget _checklist(AppLocalizations l10n, Visit visit) {
    if (_summaryOf != visit.id) {
      _summaryOf = visit.id;
      _summary.text = visit.summary ?? '';
    }
    final checklist = ref.watch(checklistProvider(visit.id));
    final observations =
        ref.watch(visitObservationsProvider(visit.id)).value ?? const [];
    final theme = Theme.of(context);
    final started = TimeOfDay.fromDateTime(visit.startedAt.toLocal());
    Widget section(String title, List<Widget> items) => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          if (items.isEmpty)
            ListTile(
              minTileHeight: 56,
              leading: Icon(Icons.check_circle, color: context.dobo.ok),
              title: Text(l10n.allDone),
            )
          else
            ...items,
        ],
      ),
    );
    Widget todo(Key key, Pond pond, String title, VoidCallback onTap) =>
        ListTile(
          key: key,
          minTileHeight: 56,
          leading: PondTag(code: pond.code, colour: pond.colour),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        );

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
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.visitOpenSince(started.format(context)),
          style: theme.textTheme.titleLarge,
        ),
        if (checklist == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          section(l10n.sectionWater, [
            for (final p in checklist.waterDue)
              todo(
                ValueKey('water-${p.code}'),
                p,
                l10n.waterReading,
                () => context.push('/water/${p.id}'),
              ),
          ]),
          section(l10n.sectionSamples, [
            for (final (b, p) in checklist.samplesDue)
              todo(
                ValueKey('sample-${b.code}-${p.code}'),
                p,
                l10n.sampleOfIn(b.code, p.code),
                () => context.push('/sample/${p.id}?batchId=${b.id}'),
              ),
          ]),
          section(l10n.sectionConditions, [
            for (final p in checklist.conditionsDue)
              todo(
                ValueKey('conditions-${p.code}'),
                p,
                l10n.conditionsOf(p.code),
                () => context.push('/visit/conditions/${p.id}'),
              ),
          ]),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            l10n.sectionBiosecurity,
            style: theme.textTheme.titleMedium,
          ),
        ),
        for (final (i, item) in bio.indexed)
          CheckboxListTile(
            minTileHeight: 56,
            contentPadding: EdgeInsets.zero,
            title: Text(item),
            value: _biosecurity.contains(i),
            onChanged: (v) => setState(
              () => v! ? _biosecurity.add(i) : _biosecurity.remove(i),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            l10n.sectionObservations,
            style: theme.textTheme.titleMedium,
          ),
        ),
        for (final o in observations)
          if (o.ok == null) ...[
            ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.notes),
              title: Text(l10n.observationCategory(o.category)),
              subtitle: o.note == null ? null : Text(o.note!),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 56),
              child: PhotoStrip(owner: PhotoOwner.observation, ownerId: o.id),
            ),
          ],
        TextButton.icon(
          style: TextButton.styleFrom(minimumSize: const Size(56, 56)),
          onPressed: _addObservation,
          icon: const Icon(Icons.add),
          label: Text(l10n.addObservation),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _summary,
          focusNode: _summaryFocus,
          decoration: InputDecoration(labelText: l10n.summary),
          maxLines: 4,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: () => _end(visit),
          icon: const Icon(Icons.flag),
          label: Text(l10n.endVisit),
        ),
      ],
    );
  }
}

/// A free observation. The dialog owns its controller: the closing dialog
/// is still rebuilt (the keyboard going away) after showDialog has returned.
class _ObservationDialog extends StatefulWidget {
  const _ObservationDialog();

  @override
  State<_ObservationDialog> createState() => _ObservationDialogState();
}

class _ObservationDialogState extends State<_ObservationDialog> {
  final _text = TextEditingController();
  var _category = ObservationCategory.other;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.addObservation),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<ObservationCategory>(
            initialValue: _category,
            decoration: InputDecoration(labelText: l10n.category),
            items: [
              for (final c in ObservationCategory.values)
                DropdownMenuItem(
                  value: c,
                  child: Text(l10n.observationCategory(c)),
                ),
            ],
            onChanged: (c) => setState(() => _category = c!),
          ),
          TextField(
            controller: _text,
            decoration: InputDecoration(labelText: l10n.observationText),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, (_category, _text.text.trim())),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
