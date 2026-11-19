import 'package:flutter/material.dart';

import '../../domain/types.dart';
import '../../theme/tokens.dart';
import 'attention_band.dart';
import 'pond_colour.dart';

/// An [AttentionBand] that names its pond: the code in the ponds list's
/// 72 dp slot, so every band's icon lines up and a long code shrinks
/// rather than squeezing the text. No slot for a farm-wide item; no swatch
/// when the pond's colour isn't known.
class CodedBand extends StatelessWidget {
  const CodedBand({
    super.key,
    required this.severity,
    required this.text,
    this.code,
    this.colour,
    this.onTap,
  });

  final BandSeverity severity;
  final String text;
  final String? code;
  final PondColour? colour;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dobo;
    return AttentionBand(
      severity: severity,
      text: text,
      onTap: onTap,
      leading: code == null
          ? null
          : SizedBox(
              key: const ValueKey('codeSlot'),
              width: 72,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: PondCode(
                  code: code!,
                  colour: colour,
                  ink: severity == BandSeverity.danger ? c.paper : c.ink,
                ),
              ),
            ),
    );
  }
}
