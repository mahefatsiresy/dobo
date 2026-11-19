import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// [value] marked as an estimate on screen: `≈ value`.
String approx(String value) => '≈ $value';

/// A computed value that must not look exact (SPEC anti-goals): `≈ value`
/// on screen, read aloud as "value estimé". Reports and PDFs, which leave
/// the app, write the word instead (docs/design.md). [trailing] follows the
/// value unmarked, such as a measured average weight.
class EstimatedLabel extends StatelessWidget {
  const EstimatedLabel({
    super.key,
    required this.value,
    this.trailing = '',
    this.style,
  });

  final String value;
  final String trailing;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text(
    '${approx(value)}$trailing',
    style: style,
    semanticsLabel: '$value ${AppLocalizations.of(context).estimated}$trailing',
  );
}
