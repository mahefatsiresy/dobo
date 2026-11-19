import 'package:flutter/material.dart';

import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import 'choice_tile.dart';
import 'pictograms.dart';

/// The five water colours; tapping the chosen one clears it (optional).
class ColourSwatches extends StatelessWidget {
  const ColourSwatches({super.key, this.value, required this.onChanged});

  final WaterColour? value;
  final ValueChanged<WaterColour?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Two per row, whatever the phone's width.
    return LayoutBuilder(
      builder: (context, box) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final c in WaterColour.values)
            ChoiceTile(
              key: ValueKey(c),
              swatch: waterColourValue(c),
              label: l10n.waterColour(c),
              selected: c == value,
              width: (box.maxWidth - 8) / 2,
              onTap: () => onChanged(c == value ? null : c),
            ),
        ],
      ),
    );
  }
}
