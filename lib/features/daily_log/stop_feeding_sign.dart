import 'package:flutter/material.dart';

import '../../domain/alerts/worker_advice.dart';
import '../../l10n/app_localizations.dart';

/// "Don't feed" for the worker: a crossed-out fork and knife (not the "no appetite" pictogram's bowl) on a white disc, and one
/// pictogram per reason (DOMAIN §Feeding). It advises, never blocks.
class StopFeedingSign extends StatelessWidget {
  const StopFeedingSign({super.key, required this.reasons});

  final Set<StopFeedingReason> reasons;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final red = Colors.red.shade800;
    Widget reason(IconData icon, String label) => Semantics(
      label: label,
      child: ExcludeSemantics(
        child: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white,
          child: Icon(icon, color: red, size: 22),
        ),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: l10n.workerStopFeeding,
          child: ExcludeSemantics(
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: Icon(Icons.no_meals, color: red, size: 40),
            ),
          ),
        ),
        const SizedBox(width: 4),
        for (final r in StopFeedingReason.values)
          if (reasons.contains(r))
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: switch (r) {
                StopFeedingReason.preHarvestFast => reason(
                  Icons.event,
                  l10n.workerReasonFast,
                ),
                StopFeedingReason.lowOxygen => reason(
                  Icons.air,
                  l10n.workerReasonOxygen,
                ),
                StopFeedingReason.distress => reason(
                  Icons.waves,
                  l10n.workerReasonDistress,
                ),
              },
            ),
      ],
    );
  }
}
