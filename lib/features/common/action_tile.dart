import 'package:flutter/material.dart';

/// One action in a grid or a row of two: its icon above its label, at least
/// 56 dp tall. The label wraps rather than shrinks (docs/design.md).
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(56, 72),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center),
      ],
    ),
  );
}
