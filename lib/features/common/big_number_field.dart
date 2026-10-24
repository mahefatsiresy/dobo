import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The number a worker records, large, on the numeric keypad. [hint] shows
/// the number to aim for (the suggested ration) above it.
class BigNumberField extends StatelessWidget {
  const BigNumberField({
    super.key,
    required this.label,
    required this.controller,
    this.decimal = false,
    this.suffix,
    this.hint,
    this.validator,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final bool decimal;
  final String? suffix;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hint != null)
          Text(
            hint!,
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: decimal),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                decimal ? RegExp(r'[\d.,\s]') : RegExp(r'[\d\s]'),
              ),
            ],
            style: theme.textTheme.headlineMedium,
            decoration: InputDecoration(
              labelText: label,
              suffixText: suffix,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
            ),
            validator: validator,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
