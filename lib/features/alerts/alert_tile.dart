import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../domain/alerts/alert.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../common/pond_colour.dart';
import '../../theme/tokens.dart';

/// One alert: severity icon, the pond's badge and one line of text.
class AlertTile extends StatelessWidget {
  const AlertTile({
    super.key,
    required this.alert,
    required this.pond,
    required this.batchCode,
    this.onTap,
  });

  final Alert alert;
  final Pond? pond;
  final String? batchCode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final danger = alert.severity == Severity.danger;
    final p = pond;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Icon(
                danger ? Icons.error : Icons.warning,
                color: danger ? context.dobo.danger : context.dobo.warning,
                size: 32,
              ),
              const SizedBox(width: 8),
              if (p != null) ...[
                PondBadge(code: p.code, colour: p.colour),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  AppLocalizations.of(context)
                      .alertText(alert, batchCode: batchCode),
                  style: danger
                      ? TextStyle(
                          color: context.dobo.danger,
                          fontWeight: FontWeight.bold,
                        )
                      : null,
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
