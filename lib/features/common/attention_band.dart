import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

enum BandSeverity { danger, warning }

/// Something that needs a person, as a full-width band with an icon and
/// words (docs/design.md: severity is a shape, not just a colour).
class AttentionBand extends StatelessWidget {
  const AttentionBand({
    super.key,
    required this.severity,
    required this.text,
    this.onTap,
  });

  final BandSeverity severity;
  final String text;

  /// Opens what resolves it; the band then ends with a chevron.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.dobo;
    final danger = severity == BandSeverity.danger;
    final ink = danger ? c.paper : c.ink;
    final band = Container(
      // Something to tap is a full 56 dp target.
      constraints: BoxConstraints(minHeight: onTap == null ? 40 : 56),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: danger ? c.danger : c.warningFill,
        border: danger
            ? null
            : Border(left: BorderSide(color: c.warning, width: 4)),
      ),
      child: Row(
        children: [
          Icon(
            danger ? Icons.error : Icons.warning_amber,
            color: danger ? c.paper : c.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: ink, fontWeight: FontWeight.w600),
            ),
          ),
          if (onTap != null) Icon(Icons.chevron_right, color: ink),
        ],
      ),
    );
    return onTap == null
        ? band
        : Material(
            type: MaterialType.transparency,
            child: InkWell(onTap: onTap, child: band),
          );
  }
}
