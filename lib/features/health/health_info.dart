import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// The common diseases of DOMAIN §Health, as information only: the app
/// never diagnoses or suggests a treatment.
class HealthInfoCard extends StatelessWidget {
  const HealthInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget disease(String name, String signs) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$name : ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: signs),
          ],
        ),
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.healthInfoTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            disease(l10n.diseaseStrepto, l10n.diseaseStreptoSigns),
            disease(l10n.diseaseAeromonas, l10n.diseaseAeromonasSigns),
            disease(l10n.diseaseParasites, l10n.diseaseParasitesSigns),
          ],
        ),
      ),
    );
  }
}
