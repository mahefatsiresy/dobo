import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../db/repositories/errors.dart';
import '../../db/repositories/pond_repository.dart';
import '../../db/repositories/providers.dart';
import '../../domain/pond.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../common/attention_band.dart';
import '../common/choice_buttons.dart';
import '../common/details_fold.dart';
import '../common/pinned_action.dart';
import '../common/number_field.dart';
import '../common/pond_colour.dart';
import 'pond_overview.dart';
import '../common/save_once.dart';
import '../common/form_body.dart';
import '../../theme/tokens.dart';

/// Statuses a member sets by hand on a pond without fish. Fish decide
/// `stocked`; health events set and lift `isolated` (SPEC F9).
const _manualStatuses = [
  PondStatus.empty,
  PondStatus.preparing,
  PondStatus.ready,
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

  void _load(Pond p, PondStatus shown) {
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
    _status = shown;
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
      final overview = ref
          .watch(pondOverviewsProvider)
          .value
          ?.where((o) => o.pond.id == id)
          .firstOrNull;
      if (overview == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      _load(overview.pond, overview.status);
    }
    final colour = _colour ?? nextFreeColour(ponds);
    final config = ref.watch(domainConfigProvider);
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

    final editing = _editing;
    final hasDetails =
        editing != null &&
        (editing.depthInletM != null ||
            editing.depthOutletM != null ||
            editing.waterSupply != null ||
            editing.surfaceM2Override != null);
    final c = context.dobo;

    return Scaffold(
      appBar: AppBar(title: Text(id == null ? l10n.pondAdd : _code.text)),
      bottomNavigationBar: PinnedAction(
        icon: id == null ? Icons.add : Icons.check,
        label: id == null ? l10n.pondAdd : l10n.actionSavePond,
        onPressed: saving ? null : () => saveOnce(() => _save(colour)),
      ),
      body: Form(
        key: _form,
        child: FormBody(
          controller: _scroll,
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
            Text(
              l10n.pondColourLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in PondColour.values)
                  Semantics(
                    label: l10n.pondColour(p),
                    selected: p == colour,
                    button: true,
                    child: InkWell(
                      onTap: () => setState(() => _colour = p),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: pondColourValue(p),
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: p == colour ? 4 : 1,
                            color: p == colour ? c.ink : c.inkMuted,
                          ),
                        ),
                        child: p == colour
                            ? Icon(Icons.check, color: pondInk(p))
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            gap,
            ChoiceField<PondRole>(
              label: l10n.pondRoleLabel,
              options: [for (final r in PondRole.values) (r, l10n.pondRole(r))],
              value: _role,
              onChanged: (v) => setState(() => _role = v),
            ),
            gap,
            ChoiceField<StructureType>(
              label: l10n.pondStructure,
              options: [
                for (final s in StructureType.values) (s, l10n.structure(s)),
              ],
              value: _structure,
              onChanged: (v) => setState(() => _structure = v),
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
            for (final w in warnings)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AttentionBand(
                  severity: BandSeverity.warning,
                  text: l10n.pondDesignWarning(w, config),
                ),
              ),
            DetailsFold(
              initiallyOpen: hasDetails,
              children: [
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
                gap,
                ChoiceField<WaterSupply?>(
                  label: l10n.pondWaterSupply,
                  options: [
                    (null, l10n.notSpecified),
                    for (final w in WaterSupply.values)
                      (w, l10n.waterSupply(w)),
                  ],
                  value: _supply,
                  onChanged: (v) => setState(() => _supply = v),
                ),
                gap,
                NumberField(
                  label: l10n.pondSurfaceOverride,
                  controller: _surface,
                  decimal: true,
                  suffix: 'm²',
                ),
                gap,
                if (_manualStatuses.contains(_status))
                  ChoiceField<PondStatus>(
                    label: l10n.pondStatusLabel,
                    options: [
                      for (final s in _manualStatuses) (s, l10n.pondStatus(s)),
                    ],
                    value: _status,
                    onChanged: (v) => setState(() => _status = v),
                  )
                else
                  Text(
                    l10n.labelValue(
                      l10n.pondStatusLabel,
                      l10n.pondStatus(_status),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
