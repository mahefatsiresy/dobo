import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/providers.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../common/form_body.dart';
import '../common/notice.dart';
import '../common/save_once.dart';
import '../common/sign_grid.dart';
import 'health_info.dart';

/// A suspected health problem (SPEC F9): signs seen, what is suspected, and
/// what was done. Isolating stops fish and water leaving the pond.
class ReportProblemScreen extends ConsumerStatefulWidget {
  const ReportProblemScreen({super.key, required this.pondId});

  final String pondId;

  @override
  ConsumerState<ReportProblemScreen> createState() =>
      _ReportProblemScreenState();
}

class _ReportProblemScreenState extends ConsumerState<ReportProblemScreen>
    with SaveOnce {
  final _suspected = TextEditingController();
  var _signs = <WarningSign>{};
  var _isolate = false;
  var _technician = false;

  @override
  void dispose() {
    _suspected.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final suspected = _suspected.text.trim();
    await ref
        .read(healthRepositoryProvider)
        .report(
          pondId: widget.pondId,
          signs: _signs,
          suspectedIssue: suspected.isEmpty ? null : suspected,
          isolate: _isolate,
          technicianCalled: _technician,
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportProblem)),
      body: FormBody(
        children: [
          Notice(l10n.healthResponse),
          gap,
          SignGrid(
            options: WarningSign.values.toSet(),
            selected: _signs,
            onChanged: (s) => setState(() => _signs = s),
          ),
          gap,
          TextField(
            controller: _suspected,
            decoration: InputDecoration(labelText: l10n.suspectedIssue),
          ),
          gap,
          CheckboxListTile(
            minTileHeight: 56,
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.isolatePond),
            value: _isolate,
            onChanged: (v) => setState(() => _isolate = v!),
          ),
          CheckboxListTile(
            minTileHeight: 56,
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.technicianCalled),
            value: _technician,
            onChanged: (v) => setState(() => _technician = v!),
          ),
          gap,
          const HealthInfoCard(),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: saving ? null : () => saveOnce(_save),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
