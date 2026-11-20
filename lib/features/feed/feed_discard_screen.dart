import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../common/choice_buttons.dart';
import '../common/form_menu.dart';
import '../common/pinned_action.dart';
import '../../domain/dates.dart';
import 'feed_providers.dart';

/// Feed thrown away from a lot (DOMAIN §Feed stock).
class FeedDiscardScreen extends ConsumerStatefulWidget {
  const FeedDiscardScreen({super.key, required this.lotId});

  final String lotId;

  @override
  ConsumerState<FeedDiscardScreen> createState() => _FeedDiscardState();
}

class _FeedDiscardState extends ConsumerState<FeedDiscardScreen> with SaveOnce {
  final _form = GlobalKey<FormState>();
  final _weight = TextEditingController();
  DiscardReason? _reason;
  late var _date = ref.read(farmTodayProvider);

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    await ref
        .read(feedRepositoryProvider)
        .discard(
          widget.lotId,
          weightG: (parseDecimal(_weight.text)! * 1000).round(),
          reason: _reason!,
          on: _date,
        );
    if (!mounted) return;
    showDone(context, AppLocalizations.of(context).doneDiscarded);
    context.canPop() ? context.pop() : context.go('/more/feed');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(farmTodayProvider);
    final lot = ref
        .watch(feedStockProvider)
        .value
        ?.lots
        .where((b) => b.lot.id == widget.lotId)
        .firstOrNull
        ?.lot;
    const gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedDiscardTitle)),
      bottomNavigationBar: PinnedAction(
        icon: Icons.delete_sweep_outlined,
        label: l10n.actionDiscard,
        onPressed: saving ? null : () => saveOnce(_save),
      ),
      body: Form(
        key: _form,
        child: FormBody(
          children: [
            if (lot != null)
              Text(
                [
                  l10n.feedLotLine(
                    lot.label ?? l10n.feedLotUnnamed,
                    formatDate(lot.manufacturedOn),
                    '${daysBetween(lot.manufacturedOn, today)}',
                  ),
                  l10n.phase(lot.phase),
                ].join(', '),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            gap,
            DateField(
              label: l10n.doneDate,
              value: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
            gap,
            NumberField(
              label: l10n.feedDiscardWeight,
              controller: _weight,
              decimal: true,
              suffix: 'kg',
              validator: (v) =>
                  (parseDecimal(v ?? '') ?? 0) <= 0 ? l10n.fieldRequired : null,
            ),
            gap,
            ChoiceField<DiscardReason>(
              label: l10n.feedDiscardReason,
              options: [
                for (final r in DiscardReason.values)
                  (r, l10n.discardReason(r)),
              ],
              value: _reason,
              requiredText: l10n.fieldRequired,
              onChanged: (r) => setState(() => _reason = r),
            ),
          ],
        ),
      ),
    );
  }
}
