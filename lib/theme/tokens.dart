import 'package:flutter/material.dart';

/// The app's colours (docs/design.md §Colour). Colour means *which pond*
/// (the tags, in `pond_colour.dart`) or *how urgent*; everything else is ink
/// on paper.
@immutable
class DoboColors extends ThemeExtension<DoboColors> {
  const DoboColors({
    required this.paper,
    required this.ink,
    required this.inkMuted,
    required this.line,
    required this.shade,
    required this.danger,
    required this.dangerFill,
    required this.warning,
    required this.warningFill,
    required this.ok,
    required this.okFill,
    required this.series,
  });

  static const standard = DoboColors(
    paper: Color(0xFFFFFFFF),
    ink: Color(0xFF17262B),
    inkMuted: Color(0xFF4A5A5F),
    line: Color(0xFFC9D2D4),
    shade: Color(0xFFEEF2F2),
    danger: Color(0xFFA3151B),
    dangerFill: Color(0xFFFBE4E4),
    warning: Color(0xFF8A5300),
    warningFill: Color(0xFFFFF1C2),
    ok: Color(0xFF1E6B3A),
    okFill: Color(0xFFE2F1E6),
    series: [
      Color(0xFF17262B),
      Color(0xFF2A7F86),
      Color(0xFFB5651D),
      Color(0xFF7A5BA6),
    ],
  );

  /// Every surface.
  final Color paper;

  /// Text, main buttons and icons: a very dark pond-water slate.
  final Color ink;

  /// Secondary text (≥ 7:1 on paper).
  final Color inkMuted;

  /// Row rules and outlines.
  final Color line;

  /// Pressed rows and quiet fills.
  final Color shade;

  /// Danger band fill (white text on it) and danger text.
  final Color danger;

  /// Pale red behind a blocking notice.
  final Color dangerFill;

  /// Warning icon, edge and text.
  final Color warning;

  /// Warning band fill (ink text on it).
  final Color warningFill;

  /// Done ticks and saved confirmations.
  final Color ok;

  /// Pale green behind an OK check.
  final Color okFill;

  /// Chart lines, one per batch.
  final List<Color> series;

  @override
  DoboColors copyWith({
    Color? paper,
    Color? ink,
    Color? inkMuted,
    Color? line,
    Color? shade,
    Color? danger,
    Color? dangerFill,
    Color? warning,
    Color? warningFill,
    Color? ok,
    Color? okFill,
    List<Color>? series,
  }) => DoboColors(
    paper: paper ?? this.paper,
    ink: ink ?? this.ink,
    inkMuted: inkMuted ?? this.inkMuted,
    line: line ?? this.line,
    shade: shade ?? this.shade,
    danger: danger ?? this.danger,
    dangerFill: dangerFill ?? this.dangerFill,
    warning: warning ?? this.warning,
    warningFill: warningFill ?? this.warningFill,
    ok: ok ?? this.ok,
    okFill: okFill ?? this.okFill,
    series: series ?? this.series,
  );

  /// One light theme, nothing to animate between: snap at the midpoint.
  @override
  DoboColors lerp(DoboColors? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

extension DoboThemeX on BuildContext {
  /// The app's colours; the standard ones outside a Dobo theme.
  DoboColors get dobo =>
      Theme.of(this).extension<DoboColors>() ?? DoboColors.standard;
}
