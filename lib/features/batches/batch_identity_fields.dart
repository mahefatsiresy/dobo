import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../db/repositories/batch_repository.dart';
import '../../domain/dates.dart';
import '../../l10n/app_localizations.dart';
import '../common/choice_buttons.dart';
import '../common/date_field.dart';

/// The identity fields of a batch, shared by the stock form and the batch
/// edit form.
class BatchIdentity {
  final code = TextEditingController();
  final strain = TextEditingController();
  final hatchery = TextEditingController();
  final certificate = TextEditingController();
  bool? monosex;
  DateTime? plannedHarvest;
  String? codeError;

  void load(Batch b) {
    code.text = b.code;
    strain.text = b.strain ?? '';
    hatchery.text = b.hatchery ?? '';
    certificate.text = b.certificateNo ?? '';
    monosex = b.monosex;
    plannedHarvest = b.plannedHarvestOn == null
        ? null
        : farmDate(b.plannedHarvestOn!);
  }

  BatchInput input() => BatchInput(
    code: code.text,
    strain: _optional(strain),
    hatchery: _optional(hatchery),
    certificateNo: _optional(certificate),
    monosex: monosex,
    plannedHarvestOn: plannedHarvest,
  );

  /// True when a detail field (see [batchDetailFields]) holds something,
  /// so a form being corrected opens its fold.
  bool get hasDetails =>
      [strain, hatchery, certificate].any((c) => c.text.trim().isNotEmpty) ||
      monosex != null;

  static String? _optional(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  void dispose() {
    for (final c in [code, strain, hatchery, certificate]) {
      c.dispose();
    }
  }
}

/// The batch code field, always shown.
Widget batchCodeField(BuildContext context, BatchIdentity identity) {
  final l10n = AppLocalizations.of(context);
  return TextFormField(
    controller: identity.code,
    decoration: InputDecoration(
      labelText: l10n.batchCode,
      errorText: identity.codeError,
    ),
    textCapitalization: TextCapitalization.characters,
    validator: (v) => (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
  );
}

/// The planned harvest date, optional: it drives the fasting alert.
Widget plannedHarvestField(
  BuildContext context,
  BatchIdentity identity, {
  required VoidCallback onChanged,
}) => DateField(
  label: AppLocalizations.of(context).plannedHarvest,
  value: identity.plannedHarvest,
  onChanged: (d) {
    identity.plannedHarvest = d;
    onChanged();
  },
  onCleared: () {
    identity.plannedHarvest = null;
    onChanged();
  },
);

/// Where the fish came from: the fields a form folds under "Plus de
/// détails" (docs/design.md §Step 7), with the planned harvest when
/// [withPlannedHarvest].
List<Widget> batchDetailFields(
  BuildContext context,
  BatchIdentity identity, {
  required VoidCallback onChanged,
  bool withPlannedHarvest = false,
}) {
  final l10n = AppLocalizations.of(context);
  const gap = SizedBox(height: 16);
  return [
    gap,
    TextFormField(
      controller: identity.strain,
      decoration: InputDecoration(labelText: l10n.strain),
    ),
    gap,
    TextFormField(
      controller: identity.hatchery,
      decoration: InputDecoration(labelText: l10n.hatchery),
    ),
    gap,
    TextFormField(
      controller: identity.certificate,
      decoration: InputDecoration(labelText: l10n.certificate),
    ),
    gap,
    ChoiceField<bool?>(
      label: l10n.monosex,
      options: [(true, l10n.yes), (false, l10n.no), (null, l10n.unknown)],
      value: identity.monosex,
      onChanged: (v) {
        identity.monosex = v;
        onChanged();
      },
    ),
    if (withPlannedHarvest) ...[
      gap,
      plannedHarvestField(context, identity, onChanged: onChanged),
    ],
  ];
}
