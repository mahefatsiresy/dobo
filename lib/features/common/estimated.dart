import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// A computed value that must not look exact (SPEC anti-goals): `≈ value`
/// on screen, read aloud as "value estimé". Reports and PDFs, which leave
/// the app, write the word instead (docs/design.md).
class EstimatedLabel extends StatelessWidget {
  const EstimatedLabel({super.key, required this.value, this.style});

  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text(
    '≈ $value',
    style: style,
    semanticsLabel: '$value ${AppLocalizations.of(context).estimated}',
  );
}
