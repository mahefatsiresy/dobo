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
import '../../theme/tokens.dart';
import '../common/attention_band.dart';
import '../common/choice_buttons.dart';
import '../common/date_field.dart';
import '../common/farm_today.dart';
import '../common/form_body.dart';
import '../common/form_menu.dart';
import '../common/number_field.dart';
import '../common/pinned_action.dart';
import '../common/save_once.dart';
import '../ponds/pond_overview.dart';
import 'prep_providers.dart';

/// The steps a member records; `rest` is the wait after filling, which
/// ends with "ready to stock".
const _ticked = [
  PrepStep.drain,
  PrepStep.dry,
  PrepStep.treat,
  PrepStep.fertilise,
  PrepStep.fill,
];

/// Steps with a product and a dose: one tap can't record them.
const _withDose = {PrepStep.treat, PrepStep.fertilise};

/// A pond's preparation as the sequence it is (SPEC F10, DOMAIN §Pond
/// preparation, docs/design.md §Step 7b): done, next, to come.
class PrepScreen extends ConsumerStatefulWidget {
  const PrepScreen({super.key, required this.pondId});

  final String pondId;

  @override
  ConsumerState<PrepScreen> createState() => _PrepScreenState();
}

class _PrepScreenState extends ConsumerState<PrepScreen> with SaveOnce {
  /// Opens [step]'s page: [done] to correct, or a new record dated today
  /// with the handbook's [doseHint] under its empty dose.
  Future<void> _open(
    PrepStep step,
    PrepStepFact? done, {
    String? doseHint,
  }) async {
    final result = await Navigator.of(context).push<_StepResult>(
      MaterialPageRoute(
        builder: (context) => _StepPage(
          step: step,
          done: done,
          today: ref.read(farmTodayProvider),
          doseHint: doseHint,
          firstDate: ref
              .read(prepProgressProvider(widget.pondId))
              .value
              ?.cycleStart,
        ),
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
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    showDone(context, result.delete ? l10n.doneDeleted : l10n.prepStepDone);
  }

  /// "Fait aujourd'hui": one tap for a step without a product.
  Future<void> _doneToday(PrepStep step, String? doseHint) async {
    if (_withDose.contains(step)) {
      return _open(step, null, doseHint: doseHint);
    }
    await saveOnce(
      () => ref
          .read(prepRepositoryProvider)
          .record(widget.pondId, step, on: ref.read(farmTodayProvider)),
    );
    if (mounted) showDone(context, AppLocalizations.of(context).prepStepDone);
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.prepReadyConfirm),
            if (p.skipped.isNotEmpty) ...[
              const SizedBox(height: 12),
              AttentionBand(
                severity: BandSeverity.warning,
                text: l10n.prepSkipped(p.skipped.map(l10n.prepStep).join(', ')),
              ),
            ],
            if (restShort) ...[
              const SizedBox(height: 12),
              AttentionBand(
                severity: BandSeverity.warning,
                text: l10n.prepRestShort(formatDate(p.restUntil!)),
              ),
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
      if (mounted) {
        context.canPop()
            ? context.pop()
            : context.go('/ponds/${widget.pondId}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final text = Theme.of(context).textTheme;
    final c = context.dobo;
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
    // The handbook's range, shown beside the dose actually used: never
    // filled in for the member, who may have weighed nothing.
    String? doseFor(PrepStep step) => switch (step) {
      PrepStep.treat when doses != null => range(
        doses.limeKg.min,
        doses.limeKg.max,
      ),
      PrepStep.fertilise when doses != null => range(
        doses.manureKg.min,
        doses.manureKg.max,
      ),
      _ => null,
    };

    List<String> notes(PrepStep step) {
      final done = progress.done[step];
      return [
        if (step == PrepStep.treat && done == null)
          doses == null
              ? l10n.prepNoSurface
              : l10n.prepLimeDose(
                  range(doses.limeKg.min, doses.limeKg.max),
                  surface,
                ),
        if (step == PrepStep.fertilise && done == null && doses != null)
          l10n.prepManureDose(
            range(doses.manureKg.min, doses.manureKg.max),
            surface,
          ),
        if (step == PrepStep.drain && done != null)
          l10n.prepDryUntil(
            formatDate(progress.dryUntilMin!),
            formatDate(progress.dryUntilMax!),
          ),
        if (step == PrepStep.rest && progress.restUntil != null)
          l10n.prepRestUntil(formatDate(progress.restUntil!)),
        if (done?.doseG != null)
          [
            if (done!.product != null) l10n.prepProduct(done.product!),
            formatKg(done.doseG!, locale),
          ].join(', '),
      ];
    }

    Widget row(int number, PrepStep step) {
      final done = progress.done[step];
      final next = progress.next == step && _ticked.contains(step);
      final ticked = _ticked.contains(step);
      final (icon, colour) = switch ((done, next)) {
        (_?, _) => (Icons.check_circle, c.ok),
        (null, true) => (Icons.radio_button_checked, c.ink),
        _ => (Icons.radio_button_unchecked, c.inkMuted),
      };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: ValueKey('step-${step.name}'),
            onTap: ticked && !saving ? () => _open(step, done) : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(icon, color: colour),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 20,
                      child: Text('$number', style: text.titleMedium),
                    ),
                    Expanded(
                      child: Text(
                        l10n.prepStep(step),
                        style: next
                            ? text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              )
                            : text.bodyLarge,
                      ),
                    ),
                    if (done != null) ...[
                      const SizedBox(width: 8),
                      Text(formatDate(done.date), style: text.bodySmall),
                    ],
                    if (ticked) Icon(Icons.chevron_right, color: c.ink),
                  ],
                ),
              ),
            ),
          ),
          for (final line in notes(step))
            Padding(
              padding: const EdgeInsets.fromLTRB(84, 0, 16, 4),
              child: Text(line, style: text.bodySmall),
            ),
          if (next)
            Padding(
              padding: const EdgeInsets.fromLTRB(84, 4, 16, 8),
              child: OutlinedButton.icon(
                key: ValueKey('done-${step.name}'),
                onPressed: saving
                    ? null
                    : () => _doneToday(step, doseFor(step)),
                icon: const Icon(Icons.check),
                label: Text(l10n.prepDoneToday),
              ),
            ),
          Divider(height: 1, color: c.line),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.prepTitle(o.pond.code)),
            Text(l10n.pondStatus(o.status), style: text.bodySmall),
          ],
        ),
      ),
      bottomNavigationBar: progress.canMarkReady
          ? PinnedAction(
              icon: Icons.verified,
              label: l10n.prepMarkReady,
              onPressed: saving ? null : () => _markReady(progress),
            )
          : null,
      // Short, and built whole so every step is there to read.
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, step) in PrepStep.values.indexed) row(i + 1, step),
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

/// When a step was done and, for treat and fertilise, what was used; a
/// page that pops with what to save.
class _StepPage extends StatefulWidget {
  const _StepPage({
    required this.step,
    this.done,
    required this.today,
    this.doseHint,
    this.firstDate,
  });

  final PrepStep step;
  final PrepStepFact? done;
  final DateTime today;

  /// The handbook's range for this pond, under the dose field.
  final String? doseHint;

  /// The day after the pond last held fish: earlier steps belong to no
  /// cycle.
  final DateTime? firstDate;

  @override
  State<_StepPage> createState() => _StepPageState();
}

class _StepPageState extends State<_StepPage> {
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

  bool get _withDoseField => _withDose.contains(widget.step);

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirmDelete(
      context,
      l10n.prepDeleteConfirm(
        l10n.prepStep(widget.step),
        formatDate(widget.done!.date),
      ),
    );
    if (ok && mounted) {
      Navigator.pop(context, _StepResult(date: _date, delete: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.prepStep(widget.step)),
        actions: [
          if (widget.done != null)
            FormMenu(
              entries: [
                FormMenuEntry(
                  label: l10n.delete,
                  icon: Icons.delete_outline,
                  onTap: _delete,
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: PinnedAction(
        icon: Icons.check,
        label: l10n.prepSaveStep,
        onPressed: () {
          final kg = _withDoseField ? parseDecimal(_dose.text) : null;
          Navigator.pop(
            context,
            _StepResult(
              date: _date,
              product: _withDoseField ? _product : null,
              doseG: kg == null || kg <= 0 ? null : (kg * 1000).round(),
            ),
          );
        },
      ),
      body: FormBody(
        children: [
          DateField(
            label: l10n.doneDate,
            value: _date,
            firstDate: widget.firstDate,
            onChanged: (d) => setState(() => _date = d),
          ),
          if (widget.step == PrepStep.treat) ...[
            const SizedBox(height: 16),
            ChoiceField<PrepProduct>(
              label: l10n.prepProductLabel,
              options: [
                for (final p in [PrepProduct.quicklime, PrepProduct.chlorine])
                  (p, l10n.prepProduct(p)),
              ],
              value: _product,
              onChanged: (p) => setState(() => _product = p),
            ),
          ],
          if (_withDoseField) ...[
            const SizedBox(height: 16),
            NumberField(
              label: l10n.prepDoseUsed,
              controller: _dose,
              decimal: true,
              suffix: 'kg',
              hint: widget.doseHint,
            ),
          ],
        ],
      ),
    );
  }
}
