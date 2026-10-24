import 'package:flutter/material.dart';

import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import 'choice_tile.dart';
import 'pictograms.dart';

/// Feed left 15–20 min after feeding: none, some, lots. With "none", an
/// optional "ate fast" lets the next ration rise (DOMAIN §Feeding).
class LeftoverPicker extends StatelessWidget {
  const LeftoverPicker({
    super.key,
    this.value,
    this.ateFast = false,
    required this.onChanged,
  });

  final Leftover? value;
  final bool ateFast;
  final void Function(Leftover? leftover, bool ateFast) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final l in Leftover.values)
          ChoiceTile(
            key: ValueKey(l),
            icon: leftoverIcon(l),
            label: l10n.leftover(l),
            selected: l == value,
            onTap: () => onChanged(l == value ? null : l, false),
          ),
        if (value == Leftover.none)
          ChoiceTile(
            key: const ValueKey('ateFast'),
            icon: Icons.bolt,
            label: l10n.ateFast,
            selected: ateFast,
            onTap: () => onChanged(Leftover.none, !ateFast),
          ),
      ],
    );
  }
}
