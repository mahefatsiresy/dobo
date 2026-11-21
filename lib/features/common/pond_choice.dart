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
    this.multi = false,
    this.values = const {},
    this.onChangedMany,
  });

  final List<PondOption> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool allowNone;

  /// Many ponds may be picked: [values] holds them and a tap toggles one,
  /// reported to [onChangedMany]; [value] and [onChanged] are not used.
  final bool multi;
  final Set<String> values;
  final ValueChanged<Set<String>>? onChangedMany;

  @override
  State<PondChoice> createState() => _PondChoiceState();
}

class _PondChoiceState extends State<PondChoice> {
  @override
  void initState() {
    super.initState();
    if (!widget.multi &&
        !widget.allowNone &&
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
              final picked = widget.multi
                  ? widget.values.contains(o.pond.id)
                  : o.pond.id == widget.value;
              final ink = picked ? c.paper : c.ink;
              return OutlinedButton(
                key: ValueKey('pond-${o.pond.id}'),
                style: pickStyle(context, picked: picked),
                onPressed: widget.multi
                    ? () => widget.onChangedMany?.call(
                        picked
                            ? ({...widget.values}..remove(o.pond.id))
                            : {...widget.values, o.pond.id},
                      )
                    : () => widget.onChanged(
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

/// A pond a form is about and can't change: its label, the code and swatch,
/// then what it holds.
class PondHeader extends StatelessWidget {
  const PondHeader({
    super.key,
    required this.label,
    required this.pond,
    this.trailing,
  });

  final String label;
  final Pond pond;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 56),
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        PondCode(code: pond.code, colour: pond.colour),
        ?trailing,
      ],
    ),
  );
}

/// A form field around [PondChoice]: fails with [requiredText] while no
/// pond is picked.
class PondChoiceField extends StatelessWidget {
  const PondChoiceField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.requiredText,
  });

  final String label;
  final List<PondOption> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String requiredText;

  @override
  Widget build(BuildContext context) => FormField<String>(
    validator: (_) => value == null ? requiredText : null,
    builder: (state) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        PondChoice(
          options: options,
          value: value,
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
