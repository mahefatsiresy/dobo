import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/providers.dart';
import '../../domain/pond.dart';
import '../../domain/prep.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../common/date_field.dart';
import '../common/farm_today.dart';
import '../common/notice.dart';
import '../common/number_field.dart';
import '../common/save_once.dart';
import '../ponds/pond_overview.dart';
import 'prep_providers.dart';

/// The steps a member ticks; `rest` ends with "ready to stock".
const _ticked = [
  PrepStep.drain,
  PrepStep.dry,
  PrepStep.treat,
  PrepStep.fertilise,
  PrepStep.fill,
];

/// A pond's preparation checklist (SPEC F10, DOMAIN §Pond preparation).
class PrepScreen extends ConsumerStatefulWidget {
  const PrepScreen({super.key, required this.pondId});

  final String pondId;

  @override
  ConsumerState<PrepScreen> createState() => _PrepScreenState();
}

class _PrepScreenState extends ConsumerState<PrepScreen> with SaveOnce {
  Future<void> _edit(PrepStep step, PrepStepFact? done) async {
    final result = await showDialog<_StepResult>(
      context: context,
      builder: (context) => _StepDialog(
        step: step,
        done: done,
        today: ref.read(farmTodayProvider),
        firstDate: ref
            .read(prepProgressProvider(widget.pondId))
            .value
            ?.cycleStart,
      ),
    );
    if (result == null) return;
    final repo = ref.read(prepRepositoryProvider);
    await saveOnce(() async {
      if (result.delete) {
        await repo.delete(done!.id);
      } else if (done != null) {
        await repo.correct(
          done.id,
          on: result.date,
          product: result.product,
          doseG: result.doseG,
        );
      } else {
        await repo.record(
          widget.pondId,
          step,
          on: result.date,
          product: result.product,
          doseG: result.doseG,
        );
      }
    });
  }

  Future<void> _markReady(PrepProgress p) async {
    final l10n = AppLocalizations.of(context);
    final today = ref.read(farmTodayProvider);
    final restShort = p.restUntil != null && p.restUntil!.isAfter(today);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.prepReadyConfirm),
            if (p.skipped.isNotEmpty) ...[
              const SizedBox(height: 12),
              Notice(l10n.prepSkipped(p.skipped.map(l10n.prepStep).join(', '))),
            ],
            if (restShort) ...[
              const SizedBox(height: 12),
              Notice(l10n.prepRestShort(formatDate(p.restUntil!))),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.prepMarkReady),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await saveOnce(() async {
      await ref
          .read(prepRepositoryProvider)
          .markReady(widget.pondId, on: today);
      if (mounted) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final o = ref
        .watch(pondOverviewsProvider)
        .value
        ?.where((o) => o.pond.id == widget.pondId)
        .firstOrNull;
    final progress = ref.watch(prepProgressProvider(widget.pondId)).value;
    if (o == null || progress == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final doses = prepDoses(o.surfaceM2, ref.watch(domainConfigProvider));
    String range(double min, double max) =>
        '${formatNumber(min, locale)}–${formatNumber(max, locale)} kg';
    final surface = o.surfaceM2 == null
        ? ''
        : '${formatNumber(o.surfaceM2!, locale)} m²';

    List<Widget> notes(PrepStep step) {
      final done = progress.done[step];
      return [
        if (step == PrepStep.treat)
          doses == null
              ? Text(l10n.prepNoSurface)
              : Text(
                  l10n.prepLimeDose(
                    range(doses.limeKg.min, doses.limeKg.max),
                    surface,
                  ),
                ),
        if (step == PrepStep.fertilise && doses != null)
          Text(
            l10n.prepManureDose(
              range(doses.manureKg.min, doses.manureKg.max),
              surface,
            ),
          ),
        if (step == PrepStep.drain && done != null)
          Text(
            l10n.prepDryUntil(
              formatDate(progress.dryUntilMin!),
              formatDate(progress.dryUntilMax!),
            ),
          ),
        if (step == PrepStep.fill && done != null)
          Text(l10n.prepRestUntil(formatDate(progress.restUntil!))),
        if (done?.doseG != null)
          Text(
            [
              if (done!.product != null) l10n.prepProduct(done.product!),
              formatKg(done.doseG!, locale),
            ].join(' · '),
          ),
      ];
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.prepTitle(o.pond.code))),
      // Short, and built whole so every step is there to read.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.pondStatus(o.status)),
            const SizedBox(height: 8),
            for (final step in _ticked)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            progress.done.containsKey(step)
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: progress.done.containsKey(step)
                                ? Colors.green.shade700
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.prepStep(step),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      ...notes(step),
                      const SizedBox(height: 8),
                      progress.done[step] == null
                          ? OutlinedButton.icon(
                              key: ValueKey('done-${step.name}'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(56),
                              ),
                              onPressed: saving
                                  ? null
                                  : () => _edit(step, null),
                              icon: const Icon(Icons.check),
                              label: Text(l10n.prepDone),
                            )
                          : TextButton(
                              key: ValueKey('edit-${step.name}'),
                              style: TextButton.styleFrom(
                                minimumSize: const Size.fromHeight(56),
                              ),
                              onPressed: saving
                                  ? null
                                  : () => _edit(step, progress.done[step]),
                              child: Text(
                                l10n.prepDoneOn(
                                  formatDate(progress.done[step]!.date),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: progress.canMarkReady && !saving
                  ? () => _markReady(progress)
                  : null,
              icon: const Icon(Icons.verified),
              label: Text(l10n.prepMarkReady),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepResult {
  const _StepResult({
    required this.date,
    this.product,
    this.doseG,
    this.delete = false,
  });

  final DateTime date;
  final PrepProduct? product;
  final int? doseG;
  final bool delete;
}

/// When a step was done and, for treat and fertilise, what was used.
class _StepDialog extends StatefulWidget {
  const _StepDialog({
    required this.step,
    this.done,
    required this.today,
    this.firstDate,
  });

  final PrepStep step;
  final PrepStepFact? done;
  final DateTime today;

  /// The day after the pond last held fish: earlier steps belong to no
  /// cycle.
  final DateTime? firstDate;

  @override
  State<_StepDialog> createState() => _StepDialogState();
}

class _StepDialogState extends State<_StepDialog> {
  late DateTime _date = widget.done?.date ?? widget.today;
  late PrepProduct? _product =
      widget.done?.product ??
      (widget.step == PrepStep.fertilise ? PrepProduct.manure : null);
  late final _dose = TextEditingController(
    text: widget.done?.doseG == null
        ? ''
        : formatForInput(widget.done!.doseG! / 1000),
  );

  @override
  void dispose() {
    _dose.dispose();
    super.dispose();
  }

  bool get _withDose =>
      widget.step == PrepStep.treat || widget.step == PrepStep.fertilise;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.prepStep(widget.step)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DateField(
              label: l10n.doneDate,
              value: _date,
              firstDate: widget.firstDate,
              onChanged: (d) => setState(() => _date = d),
            ),
            if (widget.step == PrepStep.treat) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final p in [PrepProduct.quicklime, PrepProduct.chlorine])
                    ChoiceChip(
                      label: Text(l10n.prepProduct(p)),
                      selected: _product == p,
                      onSelected: (on) =>
                          setState(() => _product = on ? p : null),
                    ),
                ],
              ),
            ],
            if (_withDose) ...[
              const SizedBox(height: 12),
              NumberField(
                label: l10n.prepDoseUsed,
                controller: _dose,
                decimal: true,
                suffix: 'kg',
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (widget.done != null)
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _StepResult(date: _date, delete: true)),
            child: Text(l10n.delete),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final kg = _withDose ? parseDecimal(_dose.text) : null;
            Navigator.pop(
              context,
              _StepResult(
                date: _date,
                product: _withDose ? _product : null,
                doseG: kg == null || kg <= 0 ? null : (kg * 1000).round(),
              ),
            );
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
