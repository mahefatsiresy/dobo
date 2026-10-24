import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../db/repositories/batch_repository.dart';
import '../../domain/dates.dart';
import '../../l10n/app_localizations.dart';
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

  static String? _optional(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  void dispose() {
    for (final c in [code, strain, hatchery, certificate]) {
      c.dispose();
    }
  }
}

/// Form fields for [identity]; [onChanged] rebuilds the owning form.
List<Widget> batchIdentityFields(
  BuildContext context,
  BatchIdentity identity, {
  required VoidCallback onChanged,
}) {
  final l10n = AppLocalizations.of(context);
  const gap = SizedBox(height: 16);
  return [
    TextFormField(
      controller: identity.code,
      decoration: InputDecoration(
        labelText: l10n.batchCode,
        errorText: identity.codeError,
      ),
      textCapitalization: TextCapitalization.characters,
      validator: (v) => (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
    ),
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
    Text(l10n.monosex),
    const SizedBox(height: 8),
    SegmentedButton<int>(
      segments: [
        ButtonSegment(value: 1, label: Text(l10n.yes)),
        ButtonSegment(value: 0, label: Text(l10n.no)),
        ButtonSegment(value: -1, label: Text(l10n.unknown)),
      ],
      selected: {
        switch (identity.monosex) {
          true => 1,
          false => 0,
          null => -1,
        },
      },
      onSelectionChanged: (s) {
        identity.monosex = switch (s.single) {
          1 => true,
          0 => false,
          _ => null,
        };
        onChanged();
      },
      style: const ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(56, 56)),
      ),
    ),
    gap,
    DateField(
      label: l10n.plannedHarvest,
      value: identity.plannedHarvest,
      onChanged: (d) {
        identity.plannedHarvest = d;
        onChanged();
      },
      onCleared: () {
        identity.plannedHarvest = null;
        onChanged();
      },
    ),
  ];
}
