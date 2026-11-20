import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../theme/tokens.dart';
import 'choice_buttons.dart';
import 'pond_colour.dart';

/// A pond a form may pick, with an optional line under its code (its
/// status, the fish it holds).
class PondOption {
  const PondOption({required this.pond, this.caption});

  final Pond pond;
  final String? caption;
}

/// The ponds a form may pick, as buttons with their code and swatch
/// (docs/design.md §Step 7). A lone option is picked by itself unless
/// [allowNone], which also lets a second tap unpick.
class PondChoice extends StatefulWidget {
  const PondChoice({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.allowNone = false,
  });

  final List<PondOption> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool allowNone;

  @override
  State<PondChoice> createState() => _PondChoiceState();
}

class _PondChoiceState extends State<PondChoice> {
  @override
  void initState() {
    super.initState();
    if (!widget.allowNone &&
        widget.value == null &&
        widget.options.length == 1) {
      final id = widget.options.single.pond.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged(id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.dobo;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in widget.options)
          Builder(
            builder: (context) {
              final picked = o.pond.id == widget.value;
              final ink = picked ? c.paper : c.ink;
              return OutlinedButton(
                key: ValueKey('pond-${o.pond.id}'),
                style: pickStyle(context, picked: picked),
                onPressed: () => widget.onChanged(
                  picked && widget.allowNone ? null : o.pond.id,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PondCode(
                      code: o.pond.code,
                      colour: o.pond.colour,
                      ink: picked ? ink : null,
                    ),
                    if (o.caption != null)
                      Text(
                        o.caption!,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: ink),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
