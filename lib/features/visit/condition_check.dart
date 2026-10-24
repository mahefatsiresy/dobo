import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/providers.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../common/form_body.dart';
import '../common/save_once.dart';
import '../ponds/pond_overview.dart';
import 'visit_checklist.dart';

/// A pond's five condition checks for the open visit: each OK, or a
/// problem with an optional note (SPEC F5).
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
      final note = _notes[category]!.text.trim();
      await repo.addObservation(
        pondId: widget.pondId,
        category: category,
        ok: ok,
        note: ok || note.isEmpty ? null : note,
      );
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                ok ? Colors.green.shade100 : Colors.red.shade100,
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
