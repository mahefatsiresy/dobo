import 'package:flutter/material.dart';

/// The fields of a form, all built at once. A lazy list disposes the fields
/// scrolled out of view, and `Form.validate` only checks fields that exist:
/// a required field at the top was skipped when Save at the bottom was
/// tapped.
class FormBody extends StatelessWidget {
  const FormBody({super.key, required this.children, this.controller});

  final List<Widget> children;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    controller: controller,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}
