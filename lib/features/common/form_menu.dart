import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/tokens.dart';

class FormMenuEntry {
  const FormMenuEntry({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

/// The ⋮ of a form or page: what is rarely done, such as Supprimer on a
/// correction (docs/design.md §Step 7).
class FormMenu extends StatelessWidget {
  const FormMenu({super.key, required this.entries});

  final List<FormMenuEntry> entries;

  @override
  Widget build(BuildContext context) => PopupMenuButton<int>(
    icon: const Icon(Icons.more_vert),
    iconSize: 24,
    padding: const EdgeInsets.all(16),
    onSelected: (i) => entries[i].onTap(),
    itemBuilder: (context) => [
      for (final (i, e) in entries.indexed)
        PopupMenuItem(
          value: i,
          height: 56,
          child: Row(
            children: [
              Icon(e.icon),
              const SizedBox(width: 12),
              Flexible(child: Text(e.label)),
            ],
          ),
        ),
    ],
  );
}

/// Asks before a deletion, naming the record and what changes; true when
/// confirmed.
Future<bool> confirmDelete(BuildContext context, String message) async {
  final l10n = AppLocalizations.of(context);
  final danger = context.dobo.danger;
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: danger),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.delete),
            ),
          ],
        ),
      ) ==
      true;
}

/// Says a form's action was done, in the action's own verb ("Transféré").
/// Call it with the context of a screen that stays, or before popping.
/// The member shell shows snackbars in its outer Scaffold, under which the
/// next page's [PinnedAction] sits: it floats clear of that bar (80 dp) so
/// it never covers the next thing to tap.
void showDone(BuildContext context, String text) {
  final c = context.dobo;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 88),
      duration: const Duration(seconds: 3),
      content: Row(
        children: [
          Icon(Icons.check_circle, color: c.okFill),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}
