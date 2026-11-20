import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/providers.dart';
import '../../db/repositories/reading_repository.dart';
import '../../domain/dates.dart';
import '../../domain/types.dart';
import '../../domain/water.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../common/colour_swatches.dart';
import '../common/date_field.dart';
import '../common/form_body.dart';
import '../common/attention_band.dart';
import '../common/form_menu.dart';
import '../common/pinned_action.dart';
import '../common/number_field.dart';
import '../common/save_once.dart';
import 'water_targets.dart';

/// Temperature, pH, oxygen and colour of a pond (DOMAIN §Water quality).
/// Values out of their target show in red as they are typed. Given
/// [readingId], the form opens filled in and saves a correction.
class WaterReadingScreen extends ConsumerStatefulWidget {
  const WaterReadingScreen({super.key, required this.pondId, this.readingId});

  final String pondId;

  /// The reading to correct.
  final String? readingId;

  @override
  ConsumerState<WaterReadingScreen> createState() => _WaterReadingScreenState();
}

class _WaterReadingScreenState extends ConsumerState<WaterReadingScreen>
    with SaveOnce {
  final _temperature = TextEditingController();
  final _ph = TextEditingController();
  final _oxygen = TextEditingController();
  final _renewed = TextEditingController();
  WaterColour? _colour;
  late DateTime _date;
  late TimeOfDay _time;
  var _emptyRefused = false;

  /// False until the reading to correct is in the form.
  late bool _loaded = widget.readingId == null;

  @override
  void initState() {
    super.initState();
    final farmNow = DateTime.now().toUtc().add(farmUtcOffset);
    _date = DateTime(farmNow.year, farmNow.month, farmNow.day);
    _time = TimeOfDay(hour: farmNow.hour, minute: farmNow.minute);
    if (widget.readingId case final id?) _load(id);
  }

  Future<void> _load(String id) async {
    final r = await ref.read(readingRepositoryProvider).getWaterReading(id);
    if (!mounted) return;
    final farm = r.recordedAt.toUtc().add(farmUtcOffset);
    String text(num? v) => v == null ? '' : formatForInput(v.toDouble());
    setState(() {
      _date = DateTime(farm.year, farm.month, farm.day);
      _time = TimeOfDay(hour: farm.hour, minute: farm.minute);
      _temperature.text = text(r.temperatureC);
      _ph.text = text(r.ph);
      _oxygen.text = text(r.oxygenMgL);
      _renewed.text = text(r.renewedPct);
      _colour = r.colour;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    for (final c in [_temperature, _ph, _oxygen, _renewed]) {
      c.dispose();
    }
    super.dispose();
  }

  WaterReadingInput get _input => WaterReadingInput(
    pondId: widget.pondId,
    at: farmTimeToUtc(_date, _time.hour, _time.minute),
    temperatureC: parseDecimal(_temperature.text),
    ph: parseDecimal(_ph.text),
    oxygenMgL: parseDecimal(_oxygen.text),
    colour: _colour,
    renewedPct: parseDecimal(_renewed.text)?.round(),
  );

  Future<void> _save() async {
    final input = _input;
    if (input.isEmpty) {
      setState(() => _emptyRefused = true);
      return;
    }
    final repo = ref.read(readingRepositoryProvider);
    if (widget.readingId case final id?) {
      await repo.correctWaterReading(id, input);
    } else {
      await repo.addWaterReading(input);
    }
    if (mounted) _leave();
  }

  void _leave() =>
      context.canPop() ? context.pop() : context.go('/ponds/${widget.pondId}');

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirmDelete(
      context,
      l10n.deleteReadingConfirm(formatDate(_date)),
    );
    if (!ok || !mounted) return;
    await ref
        .read(readingRepositoryProvider)
        .deleteWaterReading(widget.readingId!);
    if (!mounted) return;
    showDone(context, l10n.doneDeleted);
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final config = ref.watch(domainConfigProvider);
    final input = _input;
    final issues = {
      for (final i in waterIssues(
        temperatureC: input.temperatureC,
        ph: input.ph,
        oxygenMgL: input.oxygenMgL,
        colour: input.colour,
        config: config,
      ))
        i.param: (
          i.severity == Severity.danger
              ? BandSeverity.danger
              : BandSeverity.warning,
          waterTarget(l10n, i.param, config, locale).trim(),
        ),
    };
    List<Widget> band(WaterParam p) => [
      if (issues[p] case (final severity, final text))
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: AttentionBand(severity: severity, text: text),
        ),
    ];
    void refresh(String _) => setState(() => _emptyRefused = false);
    const gap = SizedBox(height: 16);

    final correcting = widget.readingId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(correcting ? l10n.correctionTitle : l10n.waterReading),
        actions: [
          if (correcting)
            FormMenu(
              entries: [
                FormMenuEntry(
                  label: l10n.delete,
                  icon: Icons.delete_outline,
                  onTap: _delete,
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: PinnedAction(
        icon: Icons.check,
        label: correcting ? l10n.actionSaveCorrection : l10n.actionSaveReading,
        onPressed: saving || !_loaded ? null : () => saveOnce(_save),
      ),
      body: FormBody(
        children: [
          DateField(
            label: l10n.sampleDate,
            value: _date,
            onChanged: (d) => setState(() => _date = d),
          ),
          gap,
          ListTile(
            minTileHeight: 56,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(l10n.readingTime),
            trailing: Text(_time.format(context)),
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: _time,
              );
              if (t != null) setState(() => _time = t);
            },
          ),
          gap,
          NumberField(
            label: l10n.temperature,
            controller: _temperature,
            decimal: true,
            suffix: '°C',
            onChanged: refresh,
          ),
          ...band(WaterParam.temperature),
          gap,
          NumberField(
            label: l10n.ph,
            controller: _ph,
            decimal: true,
            onChanged: refresh,
          ),
          ...band(WaterParam.ph),
          gap,
          NumberField(
            label: l10n.oxygen,
            controller: _oxygen,
            decimal: true,
            suffix: 'mg/L',
            onChanged: refresh,
          ),
          ...band(WaterParam.oxygen),
          gap,
          ColourSwatches(
            value: _colour,
            onChanged: (c) => setState(() {
              _colour = c;
              _emptyRefused = false;
            }),
          ),
          ...band(WaterParam.colour),
          gap,
          NumberField(
            label: l10n.renewedPct,
            controller: _renewed,
            suffix: '%',
            onChanged: refresh,
          ),
          if (_emptyRefused)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: AttentionBand(
                severity: BandSeverity.danger,
                text: l10n.fieldRequired,
              ),
            ),
        ],
      ),
    );
  }
}
