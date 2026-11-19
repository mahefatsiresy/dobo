import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../db/repositories/providers.dart';
import '../../domain/types.dart';
import '../../domain/water.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../../theme/tokens.dart';

/// A reading's temperature, pH, oxygen and colour, wrapping as needed; a
/// value out of its target in danger or warning colour with its icon
/// (docs/design.md: severity is a shape). [leading] comes first, such as
/// the reading's date.
class ReadingValues extends ConsumerWidget {
  const ReadingValues({super.key, required this.reading, this.leading});

  final WaterReading reading;
  final Widget? leading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = reading;
    return WaterValues(
      temperatureC: r.temperatureC,
      ph: r.ph,
      oxygenMgL: r.oxygenMgL,
      colour: r.colour,
      issues: {
        for (final i in waterIssues(
          temperatureC: r.temperatureC,
          ph: r.ph,
          oxygenMgL: r.oxygenMgL,
          colour: r.colour,
          config: ref.watch(domainConfigProvider),
        ))
          i.param: i.severity,
      },
      leading: leading,
    );
  }
}

/// Water values whose issues are already known, such as a report's frozen
/// reading: the same line as [ReadingValues].
class WaterValues extends StatelessWidget {
  const WaterValues({
    super.key,
    this.temperatureC,
    this.ph,
    this.oxygenMgL,
    this.colour,
    this.issues = const {},
    this.leading,
  });

  final double? temperatureC;
  final double? ph;
  final double? oxygenMgL;
  final WaterColour? colour;
  final Map<WaterParam, Severity> issues;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final c = context.dobo;
    String n(double v) => formatNumber(v, locale);
    Widget part(String text, WaterParam param) {
      final severity = issues[param];
      if (severity == null) return Text(text);
      final colour = severity == Severity.danger ? c.danger : c.warning;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            severity == Severity.danger ? Icons.error : Icons.warning_amber,
            size: 18,
            color: colour,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: colour, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ?leading,
        if (temperatureC != null)
          part('${n(temperatureC!)} °C', WaterParam.temperature),
        if (ph != null) part('pH ${n(ph!)}', WaterParam.ph),
        if (oxygenMgL != null)
          part('O₂ ${n(oxygenMgL!)} mg/L', WaterParam.oxygen),
        if (colour != null) part(l10n.waterColour(colour!), WaterParam.colour),
      ],
    );
  }
}
