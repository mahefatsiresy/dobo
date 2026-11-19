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

/// Black or white, whichever reads on the pond's colour.
Color pondInk(PondColour c) =>
    pondColourValue(c).computeLuminance() > 0.4 ? Colors.black : Colors.white;

/// The pond code on its colour, as painted on the stake: a 56 dp square for
/// alert rows and page headers.
class PondTag extends StatelessWidget {
  const PondTag({super.key, required this.code, required this.colour});

  final String code;
  final PondColour colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: pondColourValue(colour),
        borderRadius: BorderRadius.circular(4),
      ),
      // Sized to the code (at least 56 dp), not to the space offered: as a
      // list row's leading widget it must not take the whole row.
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          code,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(color: pondInk(colour), fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// The pond code in ink beside a small swatch of its colour, for member
/// lists: the colour recalls the stake without competing with the
/// severity bands (docs/design.md). Worker screens and paper sheets keep
/// the full colour.
class PondCode extends StatelessWidget {
  const PondCode({
    super.key,
    required this.code,
    required this.colour,
    this.ink,
  });

  final String code;

  /// Null when the pond isn't known on this phone: the code shows alone.
  final PondColour? colour;

  /// The text colour when drawn on a coloured band; the swatch then gets
  /// an outline in it, so a red pond's swatch still shows on a red band.
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (colour case final colour?) ...[
          Container(
            key: const ValueKey('pondSwatch'),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: pondColourValue(colour),
              borderRadius: BorderRadius.circular(2),
              border: ink == null ? null : Border.all(color: ink!),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          code,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700, color: ink),
        ),
      ],
    );
  }
}
