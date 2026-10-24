import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../db/repositories/errors.dart';
import '../../db/repositories/pond_repository.dart';
import '../../db/repositories/providers.dart';
import '../../domain/config.dart';
import '../../domain/pond.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../common/notice.dart';
import '../common/number_field.dart';
import '../common/pond_colour.dart';
import 'pond_overview.dart';
import '../common/save_once.dart';

/// Statuses a member sets by hand, also to fix one a correction left wrong.
/// `isolated` is set and lifted only by health events (SPEC F9).
const _manualStatuses = [
  PondStatus.empty,
  PondStatus.preparing,
  PondStatus.ready,
  PondStatus.stocked,
];

/// Adds a pond, or edits the one with [pondId] (SPEC F1).
class PondFormScreen extends ConsumerStatefulWidget {
  const PondFormScreen({super.key, this.pondId});

  final String? pondId;

  @override
  ConsumerState<PondFormScreen> createState() => _PondFormScreenState();
}

class _PondFormScreenState extends ConsumerState<PondFormScreen> with SaveOnce {
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _code = TextEditingController();
  final _length = TextEditingController();
  final _width = TextEditingController();
  final _surface = TextEditingController();
  final _depthIn = TextEditingController();
  final _depthOut = TextEditingController();
  PondColour? _colour;
  var _structure = StructureType.earth;
  var _role = PondRole.growout;
  WaterSupply? _supply;
  var _status = PondStatus.empty;
  String? _codeError;
  Pond? _editing;

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in [_code, _length, _width, _surface, _depthIn, _depthOut]) {
      c.dispose();
    }
    super.dispose();
  }

  void _load(Pond p) {
    _editing = p;
    _code.text = p.code;
    String n(double? v) => v == null ? '' : formatForInput(v);
    _length.text = n(p.lengthM);
    _width.text = n(p.widthM);
    _surface.text = n(p.surfaceM2Override);
    _depthIn.text = n(p.depthInletM);
    _depthOut.text = n(p.depthOutletM);
    _colour = p.colour;
    _structure = p.structure;
    _role = p.role;
    _supply = p.waterSupply;
    _status = p.status;
  }

  PondInput _input(PondColour colour) => PondInput(
    code: _code.text,
    colour: colour,
    structure: _structure,
    role: _role,
    waterSupply: _supply,
    lengthM: parseDecimal(_length.text),
    widthM: parseDecimal(_width.text),
    surfaceM2Override: parseDecimal(_surface.text),
    depthInletM: parseDecimal(_depthIn.text),
    depthOutletM: parseDecimal(_depthOut.text),
  );

  Future<void> _save(PondColour colour) async {
    setState(() => _codeError = null);
    if (!_form.currentState!.validate()) return;
    final repo = ref.read(pondRepositoryProvider);
    final l10n = AppLocalizations.of(context);
    try {
      final editing = _editing;
      final id = editing?.id ?? await repo.create(_input(colour));
      if (editing != null) await repo.update(id, _input(colour));
      if (_manualStatuses.contains(_status) && _status != editing?.status) {
        if (editing != null || _status != PondStatus.empty) {
          await repo.setStatus(id, _status);
        }
      }
      if (mounted) context.go(editing == null ? '/ponds' : '/ponds/$id');
    } on DuplicateCodeException {
      setState(() => _codeError = l10n.duplicateCode);
      // The code field is at the top; Save is at the bottom.
      await _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ponds = ref.watch(pondsProvider).value;
    final id = widget.pondId;
    if (ponds == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (id != null && _editing == null) {
      final pond = ponds.where((p) => p.id == id).firstOrNull;
      if (pond == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      _load(pond);
    }
    final colour = _colour ?? nextFreeColour(ponds);
    const config = DomainConfig.defaults;
    final surface = pondSurfaceM2(
      lengthM: parseDecimal(_length.text),
      widthM: parseDecimal(_width.text),
    );
    final warnings = pondDesignWarnings(
      lengthM: parseDecimal(_length.text),
      widthM: parseDecimal(_width.text),
      depthInletM: parseDecimal(_depthIn.text),
      depthOutletM: parseDecimal(_depthOut.text),
      config: config,
    );
    void refresh(String _) => setState(() {});
    const gap = SizedBox(height: 16);

    return Scaffold(
      appBar: AppBar(title: Text(id == null ? l10n.pondAdd : _code.text)),
      body: Form(
        key: _form,
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _code,
              decoration: InputDecoration(
                labelText: l10n.pondCode,
                errorText: _codeError,
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
            ),
            gap,
            Text(l10n.pondColourLabel),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in PondColour.values)
                  Semantics(
                    label: l10n.pondColour(c),
                    selected: c == colour,
                    button: true,
                    child: InkWell(
                      onTap: () => setState(() => _colour = c),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: pondColourValue(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: c == colour ? 4 : 1,
                            color: c == colour
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                          ),
                        ),
                        child: c == colour
                            ? Icon(
                                Icons.check,
                                color:
                                    pondColourValue(c).computeLuminance() > 0.4
                                    ? Colors.black
                                    : Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            gap,
            DropdownButtonFormField<StructureType>(
              initialValue: _structure,
              decoration: InputDecoration(labelText: l10n.pondStructure),
              items: [
                for (final s in StructureType.values)
                  DropdownMenuItem(value: s, child: Text(l10n.structure(s))),
              ],
              onChanged: (v) => setState(() => _structure = v!),
            ),
            gap,
            DropdownButtonFormField<PondRole>(
              initialValue: _role,
              decoration: InputDecoration(labelText: l10n.pondRoleLabel),
              items: [
                for (final r in PondRole.values)
                  DropdownMenuItem(value: r, child: Text(l10n.pondRole(r))),
              ],
              onChanged: (v) => setState(() => _role = v!),
            ),
            gap,
            DropdownButtonFormField<WaterSupply?>(
              initialValue: _supply,
              decoration: InputDecoration(labelText: l10n.pondWaterSupply),
              items: [
                DropdownMenuItem(child: Text(l10n.notSpecified)),
                for (final w in WaterSupply.values)
                  DropdownMenuItem(value: w, child: Text(l10n.waterSupply(w))),
              ],
              onChanged: (v) => setState(() => _supply = v),
            ),
            gap,
            NumberField(
              label: l10n.pondLength,
              controller: _length,
              decimal: true,
              suffix: 'm',
              onChanged: refresh,
            ),
            gap,
            NumberField(
              label: l10n.pondWidth,
              controller: _width,
              decimal: true,
              suffix: 'm',
              onChanged: refresh,
            ),
            if (surface != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.pondSurfaceComputed(
                    '${formatNumber(surface, Localizations.localeOf(context))} m²',
                  ),
                ),
              ),
            gap,
            NumberField(
              label: l10n.pondSurfaceOverride,
              controller: _surface,
              decimal: true,
              suffix: 'm²',
            ),
            gap,
            NumberField(
              label: l10n.pondDepthInlet,
              controller: _depthIn,
              decimal: true,
              suffix: 'm',
              onChanged: refresh,
            ),
            gap,
            NumberField(
              label: l10n.pondDepthOutlet,
              controller: _depthOut,
              decimal: true,
              suffix: 'm',
              onChanged: refresh,
            ),
            for (final w in warnings) Notice(l10n.pondDesignWarning(w, config)),
            gap,
            if (_manualStatuses.contains(_status))
              DropdownButtonFormField<PondStatus>(
                initialValue: _status,
                decoration: InputDecoration(labelText: l10n.pondStatusLabel),
                items: [
                  for (final s in _manualStatuses)
                    DropdownMenuItem(value: s, child: Text(l10n.pondStatus(s))),
                ],
                onChanged: (v) => setState(() => _status = v!),
              )
            else
              Text('${l10n.pondStatusLabel} : ${l10n.pondStatus(_status)}'),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: saving ? null : () => saveOnce(() => _save(colour)),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
