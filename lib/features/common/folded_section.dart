import 'package:flutter/material.dart';

/// A section shown as one line, its title and a summary, that opens on a
/// tap without animation. Its content is built only once opened, so a page
/// of charts stays quick on a low-end phone (docs/design.md §Step 2).
class FoldedSection extends StatelessWidget {
  const FoldedSection({
    super.key,
    required this.title,
    required this.summary,
    required this.builder,
  });

  final String title;
  final String summary;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ExpansionTile(
      expansionAnimationStyle: AnimationStyle.noAnimation,
      minTileHeight: 56,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(title, style: text.titleMedium),
      subtitle: Text(summary, style: text.bodySmall),
      children: [Builder(builder: builder)],
    );
  }
}
