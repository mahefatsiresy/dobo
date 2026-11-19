import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../db/repositories/providers.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../common/form_body.dart';
import '../common/save_once.dart';
import '../ponds/pond_overview.dart';
import 'visit_checklist.dart';
import 'visit_providers.dart';
import '../../theme/tokens.dart';

/// A pond's five condition checks for the open visit: all in order in one
/// tap, or each OK or a problem with an optional note (SPEC F5).
class ConditionCheckScreen extends ConsumerStatefulWidget {
  const ConditionCheckScreen({super.key, required this.pondId});

  final String pondId;

  @override
  ConsumerState<ConditionCheckScreen> createState() =>
      _ConditionCheckScreenState();
}

class _ConditionCheckScreenState extends ConsumerState<ConditionCheckScreen>
    with SaveOnce {
  final _ok = <ObservationCategory, bool>{};

  /// This visit's earlier answer per category, if any: a changed answer
  /// supersedes it (corrections are new records).
  Map<ObservationCategory, Observation>? _earlier;
  final _notes = {
    for (final c in conditionCategories) c: TextEditingController(),
  };

  @override
  void dispose() {
    for (final c in _notes.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(observationRepositoryProvider);
    for (final MapEntry(key: category, value: ok) in _ok.entries) {
      final text = _notes[category]!.text.trim();
      final note = ok || text.isEmpty ? null : text;
      final before = _earlier?[category];
      if (before == null) {
        await repo.addObservation(
          pondId: widget.pondId,
          category: category,
          ok: ok,
          note: note,
        );
      } else if (before.ok != ok || before.note != note) {
        await repo.correctObservation(
          before.id,
          pondId: widget.pondId,
          category: category,
          ok: ok,
          note: note,
        );
      }
    }
    if (mounted) context.pop();
  }

  /// Fills the screen once from this visit's earlier answers.
  void _loadEarlier(List<Observation> observations) {
    _earlier = {
      for (final o in observations)
        if (o.pondId == widget.pondId && o.ok != null) o.category: o,
    };
    for (final MapEntry(key: c, value: o) in _earlier!.entries) {
      _ok[c] = o.ok!;
      _notes[c]?.text = o.note ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_earlier == null) {
      final visitId = ref.watch(openVisitProvider).value?.id;
      final observations = visitId == null
          ? const <Observation>[]
          : ref.watch(visitObservationsProvider(visitId)).value;
      if (observations == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      _loadEarlier(observations);
    }
    final code =
        ref
            .watch(pondOverviewsProvider)
            .value
            ?.where((o) => o.pond.id == widget.pondId)
            .firstOrNull
            ?.pond
            .code ??
        '';
    Widget choice(ObservationCategory c, bool ok) {
      final selected = _ok[c] == ok;
      final label = Text(ok ? l10n.conditionOk : l10n.conditionProblem);
      final style = ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(96, 56)),
        backgroundColor: selected
            ? WidgetStatePropertyAll(
                ok ? context.dobo.okFill : context.dobo.dangerFill,
              )
            : null,
      );
      return OutlinedButton(
        key: ValueKey('${ok ? 'ok' : 'problem'}-${c.name}'),
        style: style,
        onPressed: () => setState(() => _ok[c] = ok),
        child: label,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.conditionsOf(code))),
      body: FormBody(
        children: [
          // The usual case, in one tap (docs/design.md §Step 5).
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: saving
                ? null
                : () => saveOnce(() {
                    setState(() {
                      for (final c in conditionCategories) {
                        _ok[c] = true;
                      }
                    });
                    return _save();
                  }),
            icon: const Icon(Icons.check),
            label: Text(l10n.conditionsAllOk),
          ),
          const SizedBox(height: 24),
          for (final c in conditionCategories) ...[
            Text(
              l10n.observationCategory(c),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                choice(c, true),
                const SizedBox(width: 8),
                choice(c, false),
              ],
            ),
            if (_ok[c] == false)
              TextField(
                controller: _notes[c],
                decoration: InputDecoration(labelText: l10n.noteLabel),
              ),
            const SizedBox(height: 16),
          ],
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: saving ? null : () => saveOnce(_save),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
