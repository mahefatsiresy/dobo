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
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.feedDiscardTitle)),
      body: Form(
        key: _form,
        child: FormBody(
          children: [
            NumberField(
              label: l10n.feedDiscardWeight,
              controller: _weight,
              decimal: true,
              suffix: 'kg',
              validator: (v) =>
                  (parseDecimal(v ?? '') ?? 0) <= 0 ? l10n.fieldRequired : null,
            ),
            gap,
            Text(
              l10n.feedDiscardReason,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            FormField<DiscardReason>(
              validator: (_) => _reason == null ? l10n.fieldRequired : null,
              builder: (state) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final r in DiscardReason.values)
                        ChoiceChip(
                          label: Text(l10n.discardReason(r)),
                          selected: _reason == r,
                          onSelected: (_) => setState(() => _reason = r),
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
            DateField(
              label: l10n.doneDate,
              value: _date,
              onChanged: (d) => setState(() => _date = d),
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
