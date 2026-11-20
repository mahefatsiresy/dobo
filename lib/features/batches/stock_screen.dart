import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/batch_repository.dart';
import '../../db/repositories/errors.dart';
import '../../db/repositories/providers.dart';
import '../../domain/config.dart';
import '../../domain/dates.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../common/date_field.dart';
import '../common/farm_today.dart';
import '../common/attention_band.dart';
import '../common/details_fold.dart';
import '../common/form_menu.dart';
import '../common/pinned_action.dart';
import '../common/pond_choice.dart';
import '../common/number_field.dart';
import '../ponds/pond_overview.dart';
import 'batch_identity_fields.dart';
import 'batch_providers.dart';
import 'stocking_warnings.dart';
import '../common/save_once.dart';
import '../common/form_body.dart';

/// Stocks a new batch into a pond (SPEC F2), or, with [stockingId], corrects
/// that stocking of [batchId] (identity fields hidden).
class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key, this.pondId, this.batchId, this.stockingId});

  final String? pondId;
  final String? batchId;
  final String? stockingId;

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> with SaveOnce {
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _codeKey = GlobalKey();
  final _identity = BatchIdentity();
  final _count = TextEditingController();
  final _weight = TextEditingController();
  String? _pondId;
  late var _date = ref.read(farmTodayProvider);
  bool? _acclimatised;
  var _loaded = false;

  bool get _correcting => widget.stockingId != null;

  @override
  void initState() {
    super.initState();
    _pondId = widget.pondId;
  }

  @override
  void dispose() {
    _scroll.dispose();
    _identity.dispose();
    _count.dispose();
    _weight.dispose();
    super.dispose();
  }

  int? get _countValue {
    final v = parseDecimal(_count.text);
    return v != null && v > 0 && v == v.roundToDouble() ? v.toInt() : null;
  }

  double? get _weightValue {
    final v = parseDecimal(_weight.text);
    return v != null && v > 0 ? v : null;
  }

  /// Fills the form once from what it edits; false while that is loading.
  bool _loadOnce() {
    if (_loaded) return true;
    if (_correcting) {
      final events = ref.watch(batchHistoryProvider(widget.batchId!)).value;
      final s = events
          ?.whereType<StockingEvent>()
          .map((e) => e.stocking)
          .where((s) => s.id == widget.stockingId)
          .firstOrNull;
      if (s == null) return false;
      _pondId = s.pondId;
      _date = farmDate(s.recordedAt);
      _count.text = '${s.count}';
      _weight.text = formatForInput(s.avgWeightMg / 1000);
      _acclimatised = s.acclimatised;
    } else {
      final summaries = ref.watch(batchSummariesProvider).value;
      if (summaries == null) return false;
      _identity.code.text = ref.read(batchRepositoryProvider).suggestBatchCode([
        for (final s in summaries) s.batch,
      ], _date);
    }
    return _loaded = true;
  }

  Future<void> _save() async {
    setState(() => _identity.codeError = null);
    if (!_form.currentState!.validate()) return;
    final repo = ref.read(batchRepositoryProvider);
    final avgWeightMg = (_weightValue! * 1000).round();
    if (_correcting) {
      await repo.correctStocking(
        widget.stockingId!,
        StockingCorrection(
          pondId: _pondId!,
          date: _date,
          count: _countValue!,
          avgWeightMg: avgWeightMg,
          acclimatised: _acclimatised,
        ),
      );
      if (!mounted) return;
      showDone(context, AppLocalizations.of(context).doneCorrected);
      context.go('/more/batches/${widget.batchId}');
      return;
    }
    final identity = _identity.input();
    try {
      final id = await repo.stockBatch(
        StockInput(
          code: identity.code,
          strain: identity.strain,
          hatchery: identity.hatchery,
          certificateNo: identity.certificateNo,
          monosex: identity.monosex,
          plannedHarvestOn: identity.plannedHarvestOn,
          pondId: _pondId!,
          date: _date,
          count: _countValue!,
          avgWeightMg: avgWeightMg,
          acclimatised: _acclimatised,
        ),
      );
      if (!mounted) return;
      showDone(context, AppLocalizations.of(context).doneStocked);
      context.go('/more/batches/$id');
    } on DuplicateCodeException {
      if (!mounted) return;
      setState(
        () => _identity.codeError = AppLocalizations.of(context).duplicateCode,
      );
      final code = _codeKey.currentContext;
      if (code != null && code.mounted) {
        await Scrollable.ensureVisible(code, alignment: 0.2);
      }
    }
  }

  Future<void> _delete(String pondCode) async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirmDelete(
      context,
      l10n.deleteStockingConfirm(
        formatDate(_date),
        formatCount(_countValue ?? 0, Localizations.localeOf(context)),
        pondCode,
      ),
    );
    if (!ok || !mounted) return;
    await ref.read(batchRepositoryProvider).deleteStocking(widget.stockingId!);
    if (!mounted) return;
    showDone(context, l10n.doneDeleted);
    context.go('/more/batches/${widget.batchId}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final overviews = ref.watch(pondOverviewsProvider).value;
    if (overviews == null || !_loadOnce()) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final config = ref.watch(domainConfigProvider);
    // Ready ponds first, then by code.
    final ponds = [...overviews]
      ..sort((a, b) {
        final ready =
            (b.status == PondStatus.ready ? 1 : 0) -
            (a.status == PondStatus.ready ? 1 : 0);
        return ready != 0 ? ready : a.pond.code.compareTo(b.pond.code);
      });
    final target = ponds.where((o) => o.pond.id == _pondId).firstOrNull;
    final count = _countValue;
    final warnings = target == null
        ? const <StockingWarning>{}
        : stockingWarnings(
            target: target,
            addedCount: count ?? 0,
            avgWeightG: _weightValue,
            config: config,
          );
    final density = target == null || count == null
        ? null
        : densityAfter(target, count);
    final range = target == null
        ? null
        : config.densityPerM2[target.pond.structure]!;
    String n(num v) => formatNumber(v.toDouble(), locale);
    void refresh([Object? _]) => setState(() {});
    String? requiredValue(String? _, Object? value) =>
        value == null ? l10n.fieldRequired : null;
    const gap = SizedBox(height: 16);
    List<Widget> bands(bool Function(StockingWarning) which) => [
      for (final w in warnings.where(which))
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: AttentionBand(
            severity: BandSeverity.warning,
            text: _warningText(l10n, w, target!, config, n),
          ),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_correcting ? l10n.correctionTitle : l10n.stockTitle),
        actions: [
          if (_correcting)
            FormMenu(
              entries: [
                FormMenuEntry(
                  label: l10n.delete,
                  icon: Icons.delete_outline,
                  onTap: () => _delete(target?.pond.code ?? '?'),
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: PinnedAction(
        icon: _correcting ? Icons.check : Icons.add,
        label: _correcting ? l10n.actionSaveCorrection : l10n.pondStock,
        onPressed: saving ? null : () => saveOnce(_save),
      ),
      body: Form(
        key: _form,
        child: FormBody(
          controller: _scroll,
          children: [
            if (widget.pondId != null && target != null)
              PondHeader(label: l10n.pickPond, pond: target.pond)
            else
              PondChoiceField(
                label: l10n.pickPond,
                requiredText: l10n.fieldRequired,
                options: [
                  for (final o in ponds)
                    PondOption(
                      pond: o.pond,
                      caption: o.status == PondStatus.ready
                          ? null
                          : l10n.pondStatus(o.status),
                    ),
                ],
                value: _pondId,
                onChanged: (v) => setState(() => _pondId = v),
              ),
            ...bands(_pondWarnings.contains),
            gap,
            DateField(
              label: l10n.stockDate,
              value: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
            gap,
            NumberField(
              label: l10n.stockCount,
              controller: _count,
              validator: (v) => requiredValue(v, _countValue),
              onChanged: refresh,
            ),
            gap,
            NumberField(
              label: l10n.avgWeight,
              controller: _weight,
              decimal: true,
              suffix: 'g',
              validator: (v) => requiredValue(v, _weightValue),
              onChanged: refresh,
            ),
            if (density != null && range != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.densityResult(
                  formatDecimal(density, locale),
                  n(range.min),
                  n(range.max),
                ),
              ),
            ],
            ...bands((w) => !_pondWarnings.contains(w)),
            gap,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.thermostat),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.acclimatiseReminder(
                      n(config.acclimatisationMinutes.min),
                      n(config.acclimatisationMinutes.max),
                    ),
                  ),
                ),
              ],
            ),
            CheckboxListTile(
              minTileHeight: 56,
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.acclimatised(
                  n(config.acclimatisationMinutes.min),
                  n(config.acclimatisationMinutes.max),
                ),
              ),
              value: _acclimatised ?? false,
              onChanged: (v) => setState(() => _acclimatised = v),
            ),
            if (!_correcting) ...[
              gap,
              KeyedSubtree(
                key: _codeKey,
                child: batchCodeField(context, _identity),
              ),
              DetailsFold(
                children: batchDetailFields(
                  context,
                  _identity,
                  onChanged: refresh,
                  withPlannedHarvest: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static const _pondWarnings = {
    StockingWarning.pondNotReady,
    StockingWarning.pondIsolated,
  };

  String _warningText(
    AppLocalizations l10n,
    StockingWarning w,
    PondOverview target,
    DomainConfig config,
    String Function(num) n,
  ) => switch (w) {
    StockingWarning.pondNotReady => l10n.warnPondNotReady(
      l10n.pondStatus(target.status),
    ),
    StockingWarning.pondIsolated => l10n.warnPondIsolated,
    StockingWarning.weightOutsideRange => l10n.warnWeightOutsideRange(
      n(config.stockingWeightG.min),
      n(config.stockingWeightG.max),
    ),
    StockingWarning.densityBelow => l10n.warnDensityBelow,
    StockingWarning.densityAbove => l10n.warnDensityAbove,
  };
}
