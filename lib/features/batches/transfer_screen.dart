import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/batch_repository.dart';
import '../../db/repositories/errors.dart';
import '../../db/repositories/providers.dart';
import '../../domain/dates.dart';
import '../../domain/stock.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../common/date_field.dart';
import '../common/farm_today.dart';
import '../common/attention_band.dart';
import '../common/details_fold.dart';
import '../common/estimated.dart';
import '../common/form_menu.dart';
import '../common/pinned_action.dart';
import '../common/pond_choice.dart';
import '../common/number_field.dart';
import '../ponds/pond_overview.dart';
import 'batch_providers.dart';
import 'stocking_warnings.dart';
import '../common/save_once.dart';
import '../common/form_body.dart';

/// Moves fish of [batchId] out of [fromPondId] (SPEC F2), or, with
/// [transferId], corrects that move.
class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({
    super.key,
    required this.batchId,
    this.fromPondId,
    this.transferId,
  });

  final String batchId;
  final String? fromPondId;
  final String? transferId;

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> with SaveOnce {
  final _form = GlobalKey<FormState>();
  final _count = TextEditingController();
  final _weight = TextEditingController();
  String? _fromPondId;
  String? _toPondId;
  late var _date = ref.read(farmTodayProvider);
  var _loaded = false;
  var _refusedIsolated = false;

  bool get _correcting => widget.transferId != null;

  @override
  void dispose() {
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

  bool _loadOnce() {
    if (_loaded) return true;
    if (_correcting) {
      final t = ref
          .watch(batchHistoryProvider(widget.batchId))
          .value
          ?.whereType<TransferEvent>()
          .map((e) => e.transfer)
          .where((t) => t.id == widget.transferId)
          .firstOrNull;
      if (t == null) return false;
      _fromPondId = t.fromPondId;
      _toPondId = t.toPondId;
      _date = farmDate(t.recordedAt);
      _count.text = '${t.count}';
      if (t.avgWeightMg != null) {
        _weight.text = formatForInput(t.avgWeightMg! / 1000);
      }
    } else {
      _fromPondId = widget.fromPondId;
    }
    return _loaded = true;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final input = TransferInput(
      batchId: widget.batchId,
      fromPondId: _fromPondId!,
      toPondId: _toPondId!,
      date: _date,
      count: _countValue!,
      avgWeightMg: _weightValue == null ? null : (_weightValue! * 1000).round(),
    );
    final repo = ref.read(batchRepositoryProvider);
    try {
      if (_correcting) {
        await repo.correctTransfer(widget.transferId!, input);
      } else {
        await repo.transfer(input);
      }
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      showDone(
        context,
        _correcting ? l10n.doneCorrected : l10n.doneTransferred,
      );
      context.go('/more/batches/${widget.batchId}');
    } on PondIsolatedException {
      setState(() => _refusedIsolated = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final overviews = ref.watch(pondOverviewsProvider).value;
    final summary = ref
        .watch(batchSummariesProvider)
        .value
        ?.where((s) => s.batch.id == widget.batchId)
        .firstOrNull;
    if (overviews == null || summary == null || !_loadOnce()) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final config = ref.watch(domainConfigProvider);
    String n(num v) => formatNumber(v.toDouble(), locale);
    final source = overviews.where((o) => o.pond.id == _fromPondId).firstOrNull;
    final target = overviews.where((o) => o.pond.id == _toPondId).firstOrNull;
    final estimate =
        source?.batches
            .where((b) => b.batch.id == widget.batchId)
            .fold(0, (n, b) => n + b.placement.live.count) ??
        0;
    final count = _countValue;
    final blocked =
        !_correcting &&
        (_refusedIsolated || source?.status == PondStatus.isolated);
    final destDensity = target == null || count == null
        ? null
        : densityAfter(target, count);
    final destStatus = target == null
        ? null
        : densityStatus(
            density: destDensity,
            structure: target.pond.structure,
            config: config,
          );
    final range = target == null
        ? null
        : config.densityPerM2[target.pond.structure]!;
    void refresh([Object? _]) => setState(() {});
    const gap = SizedBox(height: 16);
    Widget band(String text, {bool danger = false}) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AttentionBand(
        severity: danger ? BandSeverity.danger : BandSeverity.warning,
        text: text,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.transferTitle(summary.batch.code, source?.pond.code ?? '?'),
        ),
        actions: [
          if (_correcting)
            FormMenu(
              entries: [
                FormMenuEntry(
                  label: l10n.delete,
                  icon: Icons.delete_outline,
                  onTap: () => _delete(
                    source?.pond.code ?? '?',
                    target?.pond.code ?? '?',
                  ),
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: blocked
          ? null
          : PinnedAction(
              icon: _correcting ? Icons.check : Icons.swap_horiz,
              label: _correcting
                  ? l10n.actionSaveCorrection
                  : l10n.pondTransfer,
              onPressed: saving ? null : () => saveOnce(_save),
            ),
      body: Form(
        key: _form,
        child: FormBody(
          children: [
            if (blocked) band(l10n.isolatedSource, danger: true),
            if (source != null)
              PondHeader(
                label: l10n.transferFrom,
                pond: source.pond,
                trailing: EstimatedLabel(
                  value: l10n.pondFishCount(formatCount(estimate, locale)),
                ),
              ),
            gap,
            PondChoiceField(
              label: l10n.toPond,
              requiredText: l10n.fieldRequired,
              options: [
                for (final o in [
                  ...overviews,
                ]..sort((a, b) => a.pond.code.compareTo(b.pond.code)))
                  if (o.pond.id != _fromPondId)
                    PondOption(
                      pond: o.pond,
                      caption: l10n.pondStatus(o.status),
                    ),
              ],
              value: _toPondId,
              onChanged: (v) {
                if (!blocked) setState(() => _toPondId = v);
              },
            ),
            if (target?.status == PondStatus.isolated)
              band(l10n.warnDestIsolated),
            gap,
            DateField(
              label: l10n.transferDate,
              value: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
            gap,
            NumberField(
              label: l10n.transferCount,
              controller: _count,
              validator: (_) => _countValue == null ? l10n.fieldRequired : null,
              onChanged: refresh,
            ),
            if (!_correcting && count != null && count > estimate)
              band(l10n.warnAboveEstimate(formatCount(estimate, locale))),
            if (destDensity != null && range != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.destDensity(
                  target!.pond.code,
                  formatDecimal(destDensity, locale),
                  n(range.min),
                  n(range.max),
                ),
              ),
              if (destStatus == DensityStatus.below)
                band(l10n.warnDensityBelow)
              else if (destStatus == DensityStatus.above)
                band(l10n.warnDensityAbove),
            ],
            DetailsFold(
              initiallyOpen: _weight.text.isNotEmpty,
              children: [
                gap,
                NumberField(
                  label: l10n.avgWeightOptional,
                  controller: _weight,
                  decimal: true,
                  suffix: 'g',
                  onChanged: refresh,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(String from, String to) async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirmDelete(
      context,
      l10n.deleteTransferConfirm(
        formatDate(_date),
        formatCount(_countValue ?? 0, Localizations.localeOf(context)),
        from,
        to,
      ),
    );
    if (!ok || !mounted) return;
    await ref.read(batchRepositoryProvider).deleteTransfer(widget.transferId!);
    if (!mounted) return;
    showDone(context, l10n.doneDeleted);
    context.go('/more/batches/${widget.batchId}');
  }
}
