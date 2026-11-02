import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/providers.dart';
import '../../domain/config.dart';
import '../../domain/config_overrides.dart';
import '../../l10n/app_localizations.dart';
import '../../sync/photo_store.dart';
import '../../l10n/formatting.dart';
import '../common/form_body.dart';
import '../common/save_once.dart';

/// Per-site overrides of the farming numbers (SPEC F14), each beside the
/// handbook's value. Empty means the handbook's value.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SaveOnce {
  final _fields = {for (final k in configKeys) k.key: TextEditingController()};
  final _photoCap = TextEditingController();
  Map<String, num>? _loaded;

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    _photoCap.dispose();
    super.dispose();
  }

  void _load(Map<String, num> overrides) {
    _loaded = overrides;
    for (final MapEntry(:key, :value) in overrides.entries) {
      _fields[key]?.text = formatForInput(value.toDouble());
    }
    final cap = overrides[photoUploadCapKey];
    if (cap != null) _photoCap.text = formatForInput(cap.toDouble());
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(settingsRepositoryProvider);
    for (final k in configKeys) {
      final text = _fields[k.key]!.text.trim();
      final value = text.isEmpty ? null : parseDecimal(text);
      final before = _loaded![k.key];
      if (value == before) continue;
      value == null ? await repo.clear(k.key) : await repo.set(k.key, value);
    }
    // Not a farming number: kept out of DomainConfig (plan Decision 11).
    final capText = _photoCap.text.trim();
    final cap = capText.isEmpty ? null : parseDecimal(capText)?.round();
    if (cap != _loaded![photoUploadCapKey]) {
      cap == null || cap < 0
          ? await repo.clear(photoUploadCapKey)
          : await repo.set(photoUploadCapKey, cap);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.settingsSaved)));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final overrides = ref.watch(settingOverridesProvider).value;
    if (overrides == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loaded == null) _load(overrides);
    final rows = <Widget>[
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l10n.settingsIntro),
      ),
    ];
    String? section;
    for (final k in configKeys) {
      if (k.section != section) {
        section = k.section;
        rows.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              settingSection(l10n, k.section),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        );
      }
      final bound = k.key.endsWith('.min')
          ? ' – ${l10n.settingMin}'
          : k.key.endsWith('.max')
          ? ' – ${l10n.settingMax}'
          : '';
      rows.add(
        Padding(
          key: Key('setting-${k.key}'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${settingLabel(l10n, k.subject)}$bound'),
                    Text(
                      l10n.settingDefault(
                        formatNumber(
                          k.read(DomainConfig.defaults).toDouble(),
                          locale,
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 96,
                child: TextField(
                  controller: _fields[k.key],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
      );
    }
    rows.addAll([
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          l10n.settingsPhotos,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
      Padding(
        key: const Key('setting-$photoUploadCapKey'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.settingPhotoUploadCap),
                  Text(
                    l10n.settingDefault('$defaultPhotoUploadCap'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 96,
              child: TextField(
                controller: _photoCap,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    ]);
    rows.add(
      Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          key: const Key('saveSettings'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: saving ? null : () => saveOnce(_save),
          child: Text(l10n.save),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminSettings)),
      body: FormBody(children: rows),
    );
  }
}

/// A setting's name, for people.
String settingLabel(AppLocalizations l10n, String subject) => switch (subject) {
  'fryMaxG' => l10n.cfgFryMaxG,
  'pregrowMaxG' => l10n.cfgPregrowMaxG,
  'growoutMaxG' => l10n.cfgGrowoutMaxG,
  'rationRate.fry' => l10n.cfgRationRateFry,
  'rationRate.pregrow' => l10n.cfgRationRatePregrow,
  'rationRate.growout' => l10n.cfgRationRateGrowout,
  'rationRate.finishing' => l10n.cfgRationRateFinishing,
  'maxRationRate' => l10n.cfgMaxRationRate,
  'leftoverReduction' => l10n.cfgLeftoverReduction,
  'ateFastIncrease' => l10n.cfgAteFastIncrease,
  'densityPerM2.earth' => l10n.cfgDensityPerM2Earth,
  'densityPerM2.tank' => l10n.cfgDensityPerM2Tank,
  'densityPerM2.cage' => l10n.cfgDensityPerM2Cage,
  'temperatureC' => l10n.cfgTemperatureC,
  'ph' => l10n.cfgPh,
  'minOxygenMgL' => l10n.cfgMinOxygenMgL,
  'waterRenewalPctPerWeek' => l10n.cfgWaterRenewalPctPerWeek,
  'sampleIntervalDays' => l10n.cfgSampleIntervalDays,
  'sampleMinFish' => l10n.cfgSampleMinFish,
  'sampleMaxFish' => l10n.cfgSampleMaxFish,
  'waterCheckIntervalDays' => l10n.cfgWaterCheckIntervalDays,
  'fcrTarget' => l10n.cfgFcrTarget,
  'feedAgeWarnDays' => l10n.cfgFeedAgeWarnDays,
  'feedAgeDangerDays' => l10n.cfgFeedAgeDangerDays,
  'lowStockDays' => l10n.cfgLowStockDays,
  'mortalitySpikeShare' => l10n.cfgMortalitySpikeShare,
  'mortalitySpikeMultiplier' => l10n.cfgMortalitySpikeMultiplier,
  'mortalitySpikeMinDeaths' => l10n.cfgMortalitySpikeMinDeaths,
  'mortalityTrailingDays' => l10n.cfgMortalityTrailingDays,
  'warningSignLookbackDays' => l10n.cfgWarningSignLookbackDays,
  'mortalityLookbackDays' => l10n.cfgMortalityLookbackDays,
  'stopFeedingSignDays' => l10n.cfgStopFeedingSignDays,
  'quarantineDays' => l10n.cfgQuarantineDays,
  'dryingDays' => l10n.cfgDryingDays,
  'restDays' => l10n.cfgRestDays,
  'preHarvestFastHours' => l10n.cfgPreHarvestFastHours,
  'harvestHour' => l10n.cfgHarvestHour,
  'limeKgPerM2' => l10n.cfgLimeKgPerM2,
  'manureKgPerM2' => l10n.cfgManureKgPerM2,
  'pondSurfaceM2' => l10n.cfgPondSurfaceM2,
  'pondLengthWidthRatio' => l10n.cfgPondLengthWidthRatio,
  'minDepthM' => l10n.cfgMinDepthM,
  'stockingWeightG' => l10n.cfgStockingWeightG,
  'acclimatisationMinutes' => l10n.cfgAcclimatisationMinutes,
  _ => subject,
};

/// A DOMAIN section heading, for people.
String settingSection(AppLocalizations l10n, String section) =>
    switch (section) {
      '§Phases' => l10n.cfgSectionPhases,
      '§Feeding' => l10n.cfgSectionFeeding,
      '§Ponds' => l10n.cfgSectionPonds,
      '§Water quality' => l10n.cfgSectionWaterQuality,
      '§Sampling' => l10n.cfgSectionSampling,
      '§Alert rules' => l10n.cfgSectionAlertRules,
      '§Formulas' => l10n.cfgSectionFormulas,
      '§Feed stock' => l10n.cfgSectionFeedStock,
      '§Species and fingerlings' => l10n.cfgSectionSpeciesAndFingerlings,
      '§Pond preparation' => l10n.cfgSectionPondPreparation,
      '§Harvest and delivery' => l10n.cfgSectionHarvestAndDelivery,
      _ => section,
    };
