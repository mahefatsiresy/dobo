import 'package:flutter/material.dart';

/// A button that opens a picker, showing under its title what was picked;
/// just the title while nothing is.
class OptionButton extends StatelessWidget {
  const OptionButton({
    super.key,
    required this.title,
    this.picked,
    required this.onTap,
  });

  final String title;
  final Widget? picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(56, 72),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, textAlign: TextAlign.center),
        if (picked != null) ...[const SizedBox(height: 4), picked!],
      ],
    ),
  );
}
