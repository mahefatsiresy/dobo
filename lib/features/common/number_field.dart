import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A number entered on the numeric keypad; read it with `parseDecimal`.
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.label,
    required this.controller,
    this.decimal = false,
    this.suffix,
    this.validator,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final bool decimal;
  final String? suffix;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 56),
    child: TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimal ? RegExp(r'[\d.,\s]') : RegExp(r'[\d\s]'),
        ),
      ],
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      validator: validator,
      onChanged: onChanged,
    ),
  );
}
