import 'package:flutter/material.dart';

/// A soft warning (amber) or a blocking problem (red), shown under a form.
class Notice extends StatelessWidget {
  const Notice(this.text, {super.key, this.danger = false});

  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colour = danger ? Colors.red.shade800 : Colors.amber.shade900;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(danger ? Icons.block : Icons.warning_amber, color: colour),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: colour)),
          ),
        ],
      ),
    );
  }
}
