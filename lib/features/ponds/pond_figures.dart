import 'package:flutter/material.dart';

import '../../domain/stock.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../common/estimated.dart';
import 'pond_overview.dart';
import '../../theme/tokens.dart';

/// Fish, biomass and density of a pond, each marked as estimated.
class PondFigures extends StatelessWidget {
  const PondFigures({super.key, required this.overview});

  final PondOverview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final o = overview;
    if (o.liveCount == 0 && !o.inconsistent) return Text(l10n.pondNoFish);
    final status = o.densityStatus;
    final outOfRange = status != null && status != DensityStatus.within;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row(
          l10n,
          l10n.pondFish,
          EstimatedLabel(value: formatCount(o.liveCount, locale)),
        ),
        if (o.inconsistent)
          Text(
            l10n.inconsistent,
            style: TextStyle(
              color: context.dobo.danger,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (o.biomassG != null)
          _row(
            l10n,
            l10n.pondBiomass,
            EstimatedLabel(value: formatKg(o.biomassG!, locale)),
          ),
        if (o.density != null)
          _row(
            l10n,
            l10n.pondDensity,
            Text(
              '${l10n.densityValue(formatDecimal(o.density!, locale))}'
              '${status == null ? '' : ' · ${l10n.densityStatus(status)}'}',
              style: outOfRange ? TextStyle(color: context.dobo.danger) : null,
            ),
          ),
      ],
    );
  }

  Widget _row(AppLocalizations l10n, String label, Widget value) => Wrap(
    spacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [Text(l10n.labelColon(label)), value],
  );
}
