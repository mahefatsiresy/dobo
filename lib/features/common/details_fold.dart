import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// A form's optional fields behind one "Plus de détails" line, opening on
/// a tap without animation (docs/design.md §Step 7). The fields are always
/// built, kept offstage while closed, so `Form.validate` still checks them;
/// a field that fails opens the fold.
class DetailsFold extends StatefulWidget {
  const DetailsFold({
    super.key,
    required this.children,
    this.initiallyOpen = false,
  });

  final List<Widget> children;
  final bool initiallyOpen;

  @override
  State<DetailsFold> createState() => _DetailsFoldState();
}

class _DetailsFoldState extends State<DetailsFold> {
  late var _open = widget.initiallyOpen;
  final _fields = GlobalKey();

  /// True when a form field inside has an error showing.
  bool _anyError() {
    var error = false;
    void visit(Element e) {
      if (e is StatefulElement && e.state is FormFieldState) {
        if ((e.state as FormFieldState).hasError) error = true;
      }
      e.visitChildren(visit);
    }

    _fields.currentContext?.visitChildElements(visit);
    return error;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return FormField<void>(
      // Runs before the fields inside (it registered first), so their
      // errors are read once the whole validation is over, before the next
      // frame; the fold then opens to show them.
      validator: (_) {
        Future.microtask(() {
          if (mounted && !_open && _anyError()) setState(() => _open = true);
        });
        return null;
      },
      builder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Row(
                children: [
                  Icon(_open ? Icons.expand_more : Icons.chevron_right),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).detailsFold,
                      style: text.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Offstage(
            offstage: !_open,
            child: TickerMode(
              enabled: _open,
              child: Column(
                key: _fields,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
