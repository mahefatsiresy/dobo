import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/providers.dart';
import '../../db/repositories/reading_repository.dart';
import '../../domain/config.dart';
import '../../domain/stock.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../common/date_field.dart';
import '../common/form_body.dart';
import '../common/notice.dart';
import '../common/number_field.dart';
import '../common/save_once.dart';
import '../ponds/pond_overview.dart';

/// Weighing a sample of a batch in a pond (DOMAIN §Sampling).
class SampleScreen extends ConsumerStatefulWidget {
  const SampleScreen({super.key, required this.pondId, required this.batchId});

  final String pondId;
  final String batchId;

  @override
  ConsumerState<SampleScreen> createState() => _SampleScreenState();
}

class _SampleScreenState extends ConsumerState<SampleScreen> with SaveOnce {
  final _form = GlobalKey<FormState>();
  final _count = TextEditingController();
  final _weight = TextEditingController();
  var _date = farmToday();

  @override
  void dispose() {
    _count.dispose();
    _weight.dispose();
    super.dispose();
  }

  int? get _fish {
    final v = parseDecimal(_count.text);
    return v != null && v > 0 && v == v.roundToDouble() ? v.toInt() : null;
  }

  int? get _grams {
    final v = parseDecimal(_weight.text);
    return v != null && v > 0 ? (v * 1000).round() : null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    await ref
        .read(readingRepositoryProvider)
        .addSample(
          SampleInput(
            batchId: widget.batchId,
            pondId: widget.pondId,
            date: _date,
            fishCount: _fish!,
            totalWeightG: _grams!,
          ),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    const config = DomainConfig.defaults;
    final fish = _fish, grams = _grams;
    final result = fish == null || grams == null
        ? null
        : sampleResult(fishCount: fish, totalWeightG: grams, config: config);
    void refresh(String _) => setState(() {});
    const gap = SizedBox(height: 16);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sampling)),
      body: Form(
        key: _form,
        child: FormBody(
          children: [
            DateField(
              label: l10n.sampleDate,
              value: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
            gap,
            NumberField(
              label: l10n.sampleFish,
              controller: _count,
              validator: (_) => _fish == null ? l10n.fieldRequired : null,
              onChanged: refresh,
            ),
            gap,
            NumberField(
              label: l10n.sampleWeight,
              controller: _weight,
              decimal: true,
              suffix: 'kg',
              validator: (_) => _grams == null ? l10n.fieldRequired : null,
              onChanged: refresh,
            ),
            if (result != null) ...[
              gap,
              Text(
                l10n.sampleAverage(formatGrams(result.avgWeightG, locale)),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (result.smallSample)
                Notice(
                  l10n.smallSample(
                    formatNumber(config.sampleMinFish.toDouble(), locale),
                  ),
                ),
            ],
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
