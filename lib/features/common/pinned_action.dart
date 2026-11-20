import 'package:flutter/material.dart';

/// A form's or page's one action, pinned at the bottom and riding above
/// the keyboard (docs/design.md §Step 7). A null [onPressed] disables it,
/// such as while saving.
class PinnedAction extends StatelessWidget {
  const PinnedAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        ),
      ),
    ),
  );
}
