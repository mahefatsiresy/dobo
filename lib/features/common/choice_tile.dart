import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// A large tappable tile: pictogram above a short label, highlighted when
/// selected. Worker screens are built from these.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.swatch,
    this.width = 104,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  /// A colour shown instead of an icon.
  final Color? swatch;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.dobo;
    // Picked: ink with paper text, unmistakable in sunlight.
    final ink = selected ? c.paper : c.ink;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: width,
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected ? c.ink : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? c.ink : c.line,
              width: selected ? 3 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (swatch != null)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: swatch,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black26),
                  ),
                  child: selected ? const Icon(Icons.check) : null,
                )
              else if (icon != null)
                Icon(icon, size: 36, color: ink),
              const SizedBox(height: 4),
              // Never cut: a label someone can't finish is worse than a
              // long one (docs/design.md §Step 3).
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(color: ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
