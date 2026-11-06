import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/feed_repository.dart';
import '../../db/repositories/providers.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../common/date_field.dart';
import '../common/farm_today.dart';
import '../common/form_body.dart';
import '../common/number_field.dart';
import '../common/save_once.dart';

/// A feed delivery, which makes a lot (SPEC F11).
class FeedDeliveryScreen extends ConsumerStatefulWidget {
  const FeedDeliveryScreen({super.key});

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

  @override
  void dispose() {
    for (final c in [_weight, _pellet, _protein, _supplier, _label]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    setState(() => _madeMissing = _madeOn == null);
    if (!_form.currentState!.validate() || _madeOn == null) return;
    await ref
        .read(feedRepositoryProvider)
        .deliver(
          FeedDeliveryInput(
            date: _deliveredOn,
            phase: _phase!,
            weightG: (parseDecimal(_weight.text)! * 1000).round(),
            manufacturedOn: _madeOn!,
            pelletMm: parseDecimal(_pellet.text),
            proteinPct: parseDecimal(_protein.text),
            supplier: _text(_supplier),
            label: _text(_label),
          ),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedDeliveryTitle)),
      body: Form(
        key: _form,
        child: FormBody(
          children: [
            Text(
              l10n.feedPhase,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            FormField<Phase>(
              validator: (_) => _phase == null ? l10n.fieldRequired : null,
              builder: (state) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final p in Phase.values)
                        ChoiceChip(
                          label: Text(l10n.phase(p)),
                          selected: _phase == p,
                          onSelected: (_) => setState(() => _phase = p),
                        ),
                    ],
                  ),
                  if (state.hasError)
                    Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
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
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            gap,
            DateField(
              label: l10n.feedDeliveredOn,
              value: _deliveredOn,
              onChanged: (d) => setState(() => _deliveredOn = d),
            ),
            gap,
            NumberField(
              label: l10n.feedPellet,
              controller: _pellet,
              decimal: true,
              suffix: 'mm',
            ),
            gap,
            NumberField(
              label: l10n.feedProtein,
              controller: _protein,
              decimal: true,
              suffix: '%',
            ),
            gap,
            TextFormField(
              controller: _supplier,
              decoration: InputDecoration(labelText: l10n.feedSupplier),
              textCapitalization: TextCapitalization.words,
            ),
            gap,
            TextFormField(
              controller: _label,
              decoration: InputDecoration(labelText: l10n.feedLabel),
            ),
            const SizedBox(height: 24),
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
