import 'package:flutter/material.dart';

import '../../domain/types.dart';

/// Screen colour of each pond tag; also what the paper sheets print.
Color pondColourValue(PondColour c) => switch (c) {
  PondColour.blue => const Color(0xFF1565C0),
  PondColour.green => const Color(0xFF2E7D32),
  PondColour.yellow => const Color(0xFFFDD835),
  PondColour.orange => const Color(0xFFEF6C00),
  PondColour.red => const Color(0xFFC62828),
  PondColour.purple => const Color(0xFF6A1B9A),
  PondColour.brown => const Color(0xFF6D4C41),
  PondColour.black => const Color(0xFF212121),
};

/// The pond code on its colour, as painted on the stake.
class PondBadge extends StatelessWidget {
  const PondBadge({super.key, required this.code, required this.colour});

  final String code;
  final PondColour colour;

  @override
  Widget build(BuildContext context) {
    final background = pondColourValue(colour);
    final light = background.computeLuminance() > 0.4;
    return Container(
      constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      // Sized to the code (at least 56 dp), not to the space offered: as a
      // list row's leading widget it must not take the whole row.
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          code,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: light ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
