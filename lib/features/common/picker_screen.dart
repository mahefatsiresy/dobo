import 'package:flutter/material.dart';

/// A page of pictograms to pick from, with a large done button pinned at
/// the bottom (docs/design.md §Step 3). Done returns what is picked; back
/// returns nothing, so the screen that opened it keeps what it had.
class PickerScreen<T> extends StatefulWidget {
  const PickerScreen({
    super.key,
    required this.title,
    required this.doneLabel,
    required this.initial,
    required this.builder,
  });

  final String title;
  final String doneLabel;
  final T initial;
  final Widget Function(
    BuildContext context,
    T value,
    ValueChanged<T> onChanged,
  )
  builder;

  @override
  State<PickerScreen<T>> createState() => _PickerScreenState<T>();
}

class _PickerScreenState<T> extends State<PickerScreen<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: widget.builder(context, _value, (v) => setState(() => _value = v)),
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: () => Navigator.of(context).pop(_value),
          icon: const Icon(Icons.check),
          label: Text(widget.doneLabel),
        ),
      ),
    ),
  );
}
