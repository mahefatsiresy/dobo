import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/batch_repository.dart';
import '../../db/repositories/errors.dart';
import '../../db/repositories/providers.dart';
import '../../domain/config.dart';
import '../../domain/dates.dart';
import '../../domain/stock.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../common/date_field.dart';
import '../common/notice.dart';
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
  var _date = farmDate(DateTime.now().toUtc());
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
      if (mounted) context.go('/more/batches/${widget.batchId}');
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
    const config = DomainConfig.defaults;
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.transferTitle(summary.batch.code, source?.pond.code ?? '?'),
        ),
      ),
      body: Form(
        key: _form,
        child: FormBody(
          children: [
            if (blocked) Notice(l10n.isolatedSource, danger: true),
            if (source != null)
              Text(
                l10n.estimateIn(
                  formatCount(estimate, locale),
                  source.pond.code,
                ),
              ),
            gap,
            DropdownButtonFormField<String>(
              initialValue: _toPondId,
              decoration: InputDecoration(labelText: l10n.toPond),
              items: [
                for (final o in overviews)
                  if (o.pond.id != _fromPondId)
                    DropdownMenuItem(
                      value: o.pond.id,
                      child: Text(
                        '${o.pond.code} · ${l10n.pondStatus(o.status)}',
                      ),
                    ),
              ],
              validator: (v) => v == null ? l10n.fieldRequired : null,
              onChanged: blocked ? null : (v) => setState(() => _toPondId = v),
            ),
            if (target?.status == PondStatus.isolated)
              Notice(l10n.warnDestIsolated),
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
              Notice(l10n.warnAboveEstimate(formatCount(estimate, locale))),
            gap,
            NumberField(
              label: l10n.avgWeightOptional,
              controller: _weight,
              decimal: true,
              suffix: 'g',
              onChanged: refresh,
            ),
            if (destDensity != null && range != null) ...[
              gap,
              Text(
                l10n.destDensity(
                  target!.pond.code,
                  formatDecimal(destDensity, locale),
                  n(range.min),
                  n(range.max),
                ),
              ),
              if (destStatus == DensityStatus.below)
                Notice(l10n.warnDensityBelow)
              else if (destStatus == DensityStatus.above)
                Notice(l10n.warnDensityAbove),
            ],
            const SizedBox(height: 24),
            if (!blocked)
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: saving ? null : () => saveOnce(_save),
                child: Text(l10n.save),
              ),
          ],
        ),
      ),
    );
  }
}
