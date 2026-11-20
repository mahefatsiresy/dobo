import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// The style of a pickable button: filled ink once picked, outlined ink on
/// paper otherwise.
ButtonStyle pickStyle(BuildContext context, {required bool picked}) {
  final c = context.dobo;
  return OutlinedButton.styleFrom(
    minimumSize: const Size(56, 56),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    backgroundColor: picked ? c.ink : c.paper,
    foregroundColor: picked ? c.paper : c.ink,
    side: BorderSide(color: c.ink),
  );
}

/// A short fixed set of choices as 56 dp buttons that wrap; the picked one
/// is filled (docs/design.md §Step 7, the form standard).
class ChoiceButtons<T> extends StatelessWidget {
  const ChoiceButtons({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.leading,
  });

  final List<(T, String)> options;
  final T? value;
  final ValueChanged<T> onChanged;

  /// Before an option's label, such as a pond colour's swatch.
  final Widget Function(T value)? leading;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final (v, label) in options)
        OutlinedButton(
          style: pickStyle(context, picked: v == value),
          onPressed: () => onChanged(v),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!(v), const SizedBox(width: 8)],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          ),
        ),
    ],
  );
}

/// [ChoiceButtons] under a title, as a form field: with [requiredText] it
/// fails validation while nothing is picked and shows that text.
class ChoiceField<T> extends StatelessWidget {
  const ChoiceField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.requiredText,
    this.leading,
  });

  final String label;
  final List<(T, String)> options;
  final T? value;
  final ValueChanged<T> onChanged;
  final String? requiredText;
  final Widget Function(T value)? leading;

  @override
  Widget build(BuildContext context) => FormField<T>(
    validator: (_) =>
        requiredText != null && value == null ? requiredText : null,
    builder: (state) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ChoiceButtons<T>(
          options: options,
          value: value,
          leading: leading,
          onChanged: (v) {
            onChanged(v);
            state.didChange(v);
          },
        ),
        if (state.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              state.errorText!,
              style: TextStyle(color: context.dobo.danger),
            ),
          ),
      ],
    ),
  );
}
