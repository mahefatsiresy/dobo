import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/feed_repository.dart';
import '../../db/repositories/providers.dart';
import '../../domain/dates.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../common/choice_buttons.dart';
import '../common/date_field.dart';
import '../common/details_fold.dart';
import '../common/farm_today.dart';
import '../common/form_body.dart';
import '../common/form_menu.dart';
import '../common/number_field.dart';
import '../common/pinned_action.dart';
import '../common/save_once.dart';
import '../../theme/tokens.dart';

/// A feed delivery, which makes a lot (SPEC F11); with [lotId], that lot's
/// delivery to correct, discard from or delete.
class FeedDeliveryScreen extends ConsumerStatefulWidget {
  const FeedDeliveryScreen({super.key, this.lotId});

  final String? lotId;

  @override
  ConsumerState<FeedDeliveryScreen> createState() => _FeedDeliveryState();
}

class _FeedDeliveryState extends ConsumerState<FeedDeliveryScreen>
    with SaveOnce {
  final _form = GlobalKey<FormState>();
  final _weight = TextEditingController();
  final _pellet = TextEditingController();
  final _protein = TextEditingController();
  final _supplier = TextEditingController();
  final _label = TextEditingController();
  Phase? _phase;
  DateTime? _madeOn;
  var _madeMissing = false;
  late var _deliveredOn = ref.read(farmTodayProvider);

  /// False while the lot being corrected loads.
  late var _loaded = widget.lotId == null;
  var _hasDetails = false;

  bool get _correcting => widget.lotId != null;

  @override
  void initState() {
    super.initState();
    if (_correcting) _load();
  }

  Future<void> _load() async {
    final d = await ref.read(feedRepositoryProvider).delivery(widget.lotId!);
    if (!mounted) return;
    if (d == null) {
      _leave();
      return;
    }
    setState(() {
      _phase = d.phase;
      _weight.text = formatForInput(d.weightG / 1000);
      _madeOn = farmDate(d.manufacturedOn);
      _deliveredOn = farmDate(d.recordedAt);
      if (d.pelletMm != null) _pellet.text = formatForInput(d.pelletMm!);
      if (d.proteinPct != null) _protein.text = formatForInput(d.proteinPct!);
      _supplier.text = d.supplier ?? '';
      _label.text = d.label ?? '';
      _hasDetails = [
        _pellet,
        _protein,
        _supplier,
        _label,
      ].any((c) => c.text.isNotEmpty);
      _loaded = true;
    });
  }

  @override
  void dispose() {
    for (final c in [_weight, _pellet, _protein, _supplier, _label]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  void _leave() => context.canPop() ? context.pop() : context.go('/more/feed');

  Future<void> _save() async {
    setState(() => _madeMissing = _madeOn == null);
    if (!_form.currentState!.validate() || _madeOn == null) return;
    final input = FeedDeliveryInput(
      date: _deliveredOn,
      phase: _phase!,
      weightG: (parseDecimal(_weight.text)! * 1000).round(),
      manufacturedOn: _madeOn!,
      pelletMm: parseDecimal(_pellet.text),
      proteinPct: parseDecimal(_protein.text),
      supplier: _text(_supplier),
      label: _text(_label),
    );
    final repo = ref.read(feedRepositoryProvider);
    _correcting
        ? await repo.correctDelivery(widget.lotId!, input)
        : await repo.deliver(input);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    showDone(context, _correcting ? l10n.doneCorrected : l10n.doneDelivered);
    _leave();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final kg = formatKg(
      ((parseDecimal(_weight.text) ?? 0) * 1000).round(),
      Localizations.localeOf(context),
    );
    final ok = await confirmDelete(
      context,
      l10n.deleteDeliveryConfirm(formatDate(_deliveredOn), kg),
    );
    if (!ok || !mounted) return;
    await ref.read(feedRepositoryProvider).deleteDelivery(widget.lotId!);
    if (!mounted) return;
    showDone(context, l10n.doneDeleted);
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    const gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _correcting ? l10n.correctionTitle : l10n.feedDeliveryTitle,
        ),
        actions: [
          if (_correcting)
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
        label: _correcting
            ? l10n.actionSaveCorrection
            : l10n.actionSaveDelivery,
        onPressed: saving ? null : () => saveOnce(_save),
      ),
      body: Form(
        key: _form,
        child: FormBody(
          children: [
            DateField(
              label: l10n.feedDeliveredOn,
              value: _deliveredOn,
              onChanged: (d) => setState(() => _deliveredOn = d),
            ),
            gap,
            NumberField(
              label: l10n.feedWeight,
              controller: _weight,
              decimal: true,
              suffix: 'kg',
              validator: (v) =>
                  (parseDecimal(v ?? '') ?? 0) <= 0 ? l10n.fieldRequired : null,
            ),
            gap,
            ChoiceField<Phase>(
              label: l10n.feedPhase,
              options: [for (final p in Phase.values) (p, l10n.phase(p))],
              value: _phase,
              requiredText: l10n.fieldRequired,
              onChanged: (p) => setState(() => _phase = p),
            ),
            gap,
            DateField(
              label: l10n.feedMadeOn,
              value: _madeOn,
              onChanged: (d) => setState(() {
                _madeOn = d;
                _madeMissing = false;
              }),
            ),
            if (_madeMissing)
              Text(
                l10n.fieldRequired,
                style: TextStyle(color: context.dobo.danger),
              ),
            if (_correcting) ...[
              gap,
              OutlinedButton.icon(
                onPressed: () =>
                    context.push('/more/feed/${widget.lotId}/discard'),
                icon: const Icon(Icons.delete_sweep_outlined),
                label: Text(l10n.feedDiscardPart),
              ),
            ],
            DetailsFold(
              initiallyOpen: _hasDetails,
              children: [
                gap,
                TextFormField(
                  controller: _label,
                  decoration: InputDecoration(labelText: l10n.feedLabel),
                ),
                gap,
                TextFormField(
                  controller: _supplier,
                  decoration: InputDecoration(labelText: l10n.feedSupplier),
                  textCapitalization: TextCapitalization.words,
                ),
                gap,
                NumberField(
                  label: l10n.feedProtein,
                  controller: _protein,
                  decimal: true,
                  suffix: '%',
                ),
                gap,
                NumberField(
                  label: l10n.feedPellet,
                  controller: _pellet,
                  decimal: true,
                  suffix: 'mm',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
