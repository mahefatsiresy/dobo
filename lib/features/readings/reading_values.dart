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
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final c = context.dobo;
    final r = reading;
    final issues = {
      for (final i in waterIssues(
        temperatureC: r.temperatureC,
        ph: r.ph,
        oxygenMgL: r.oxygenMgL,
        colour: r.colour,
        config: ref.watch(domainConfigProvider),
      ))
        i.param: i.severity,
    };
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
        if (r.temperatureC != null)
          part('${n(r.temperatureC!)} °C', WaterParam.temperature),
        if (r.ph != null) part('pH ${n(r.ph!)}', WaterParam.ph),
        if (r.oxygenMgL != null)
          part('O₂ ${n(r.oxygenMgL!)} mg/L', WaterParam.oxygen),
        if (r.colour != null)
          part(l10n.waterColour(r.colour!), WaterParam.colour),
      ],
    );
  }
}
