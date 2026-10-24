import 'package:flutter/widgets.dart';

import '../../domain/config.dart';
import '../../domain/water.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';

/// The DOMAIN target of a water parameter, as shown beside a value out of
/// range.
String waterTarget(
  AppLocalizations l10n,
  WaterParam param,
  DomainConfig config,
  Locale locale,
) {
  String n(double v) => formatNumber(v, locale);
  return switch (param) {
    WaterParam.temperature => l10n.targetRange(
      n(config.temperatureC.min),
      n(config.temperatureC.max),
      '°C',
    ),
    WaterParam.ph => l10n.targetRange(n(config.ph.min), n(config.ph.max), ''),
    WaterParam.oxygen => l10n.targetMin(n(config.minOxygenMgL), 'mg/L'),
    WaterParam.colour => l10n.renewWater,
  };
}
