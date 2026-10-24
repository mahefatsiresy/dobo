import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// A computed value that must not look exact (SPEC anti-goals).
class EstimatedLabel extends StatelessWidget {
  const EstimatedLabel({super.key, required this.value, this.style});

  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(value, style: style),
        const SizedBox(width: 4),
        Text(
          AppLocalizations.of(context).estimated,
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
