import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/health_repository.dart';
import '../../db/repositories/providers.dart';
import '../../l10n/app_localizations.dart';
import '../common/date_field.dart';
import '../common/form_body.dart';
import '../common/save_once.dart';
import '../ponds/pond_overview.dart';

/// A treatment given on someone's advice (SPEC F9). Product and dose are
/// typed in: the app never suggests one.
class TreatmentScreen extends ConsumerStatefulWidget {
  const TreatmentScreen({super.key, required this.pondId});

  final String pondId;

  @override
  ConsumerState<TreatmentScreen> createState() => _TreatmentScreenState();
}

class _TreatmentScreenState extends ConsumerState<TreatmentScreen>
    with SaveOnce {
  final _form = GlobalKey<FormState>();
  final _product = TextEditingController();
  final _dose = TextEditingController();
  final _advisedBy = TextEditingController();
  String? _batchId;
  var _date = farmToday();

  @override
  void dispose() {
    for (final c in [_product, _dose, _advisedBy]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final advisedBy = _advisedBy.text.trim();
    await ref
        .read(healthRepositoryProvider)
        .addTreatment(
          TreatmentInput(
            pondId: widget.pondId,
            batchId: _batchId,
            date: _date,
            product: _product.text,
            dose: _dose.text,
            advisedBy: advisedBy.isEmpty ? null : advisedBy,
          ),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final batches =
        ref
            .watch(pondOverviewsProvider)
            .value
            ?.where((o) => o.pond.id == widget.pondId)
            .firstOrNull
            ?.batches ??
        const [];
    String? required(String? v) =>
        (v ?? '').trim().isEmpty ? l10n.fieldRequired : null;
    const gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.treatment)),
      body: Form(
        key: _form,
        child: FormBody(
          children: [
            DropdownButtonFormField<String?>(
              initialValue: _batchId,
              decoration: InputDecoration(labelText: l10n.batchOptional),
              items: [
                DropdownMenuItem(child: Text(l10n.notSpecified)),
                for (final b in batches)
                  DropdownMenuItem(
                    value: b.batch.id,
                    child: Text(b.batch.code),
                  ),
              ],
              onChanged: (v) => setState(() => _batchId = v),
            ),
            gap,
            TextFormField(
              controller: _product,
              decoration: InputDecoration(labelText: l10n.product),
              validator: required,
            ),
            gap,
            TextFormField(
              controller: _dose,
              decoration: InputDecoration(labelText: l10n.dose),
              validator: required,
            ),
            gap,
            DateField(
              label: l10n.treatmentDate,
              value: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
            gap,
            TextFormField(
              controller: _advisedBy,
              decoration: InputDecoration(labelText: l10n.advisedBy),
              textCapitalization: TextCapitalization.words,
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
