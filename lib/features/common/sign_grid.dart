import 'package:flutter/material.dart';

import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import 'choice_tile.dart';
import 'pictograms.dart';

/// Warning signs as pictogram tiles; tap to toggle.
class SignGrid extends StatelessWidget {
  const SignGrid({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final Set<WarningSign> options;
  final Set<WarningSign> selected;
  final ValueChanged<Set<WarningSign>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Two per row, whatever the phone's width.
    return LayoutBuilder(
      builder: (context, box) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in WarningSign.values)
            if (options.contains(s))
              ChoiceTile(
                key: ValueKey(s),
                icon: warningSignIcon(s),
                label: l10n.warningSign(s),
                width: (box.maxWidth - 8) / 2,
                selected: selected.contains(s),
                onTap: () => onChanged(
                  selected.contains(s)
                      ? ({...selected}..remove(s))
                      : {...selected, s},
                ),
              ),
        ],
      ),
    );
  }
}
