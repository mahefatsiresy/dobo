import 'package:flutter/material.dart';

import '../../l10n/formatting.dart';

/// A date-only field: shows `dd/mm/yyyy`, opens the date picker on tap.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onCleared,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  /// When set, the field is optional and shows a clear button.
  final VoidCallback? onCleared;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: value ?? now,
        firstDate: DateTime(now.year - 5),
        lastDate: DateTime(now.year + 3),
      );
      if (picked != null) {
        onChanged(DateTime(picked.year, picked.month, picked.day));
      }
    },
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value != null && onCleared != null
              ? IconButton(icon: const Icon(Icons.clear), onPressed: onCleared)
              : const Icon(Icons.calendar_today),
        ),
        child: Text(value == null ? '' : formatDate(value!)),
      ),
    ),
  );
}
