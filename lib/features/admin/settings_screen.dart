import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/providers.dart';
import '../../domain/config.dart';
import '../../domain/config_overrides.dart';
import '../../l10n/app_localizations.dart';
import '../../sync/photo_store.dart';
import '../../l10n/formatting.dart';
import '../../theme/tokens.dart';
import '../common/folded_section.dart';
import '../common/form_menu.dart';
import '../common/pinned_action.dart';
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
    showDone(context, l10n.settingsSaved);
    context.canPop() ? context.pop() : context.go('/more/admin');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final text = Theme.of(context).textTheme;
    final c = context.dobo;
    final overrides = ref.watch(settingOverridesProvider).value;
    if (overrides == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loaded == null) _load(overrides);

    /// A value: its name, the handbook's, its field and "Rétablir" when it
    /// holds one of the site's own.
    Widget value({
      required Key key,
      required String label,
      required String handbook,
      required TextEditingController field,
      bool decimal = true,
    }) => Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                Text(l10n.settingDefault(handbook), style: text.bodySmall),
                if (field.text.trim().isNotEmpty)
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: () => setState(field.clear),
                    child: Text(l10n.settingReset),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 96,
            child: TextField(
              controller: field,
              keyboardType: TextInputType.numberWithOptions(decimal: decimal),
              textAlign: TextAlign.end,
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );

    final sections = <String, List<ConfigKey>>{};
    for (final k in configKeys) {
      (sections[k.section] ??= []).add(k);
    }
    int changed(Iterable<TextEditingController> fields) =>
        fields.where((f) => f.text.trim().isNotEmpty).length;
    Widget rule() => Divider(height: 1, color: c.line);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminSettings)),
      bottomNavigationBar: PinnedAction(
        key: const Key('saveSettings'),
        icon: Icons.check,
        label: l10n.save,
        onPressed: saving ? null : () => saveOnce(_save),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.settingsIntro),
          ),
          rule(),
          for (final MapEntry(key: section, value: keys)
              in sections.entries) ...[
            FoldedSection(
              title: settingSection(l10n, section),
              summary: l10n.settingsChanged(
                changed(keys.map((k) => _fields[k.key]!)),
              ),
              builder: (context) => Column(
                children: [
                  for (final k in keys)
                    value(
                      key: Key('setting-${k.key}'),
                      label:
                          '${settingLabel(l10n, k.subject)}'
                          '${k.key.endsWith('.min')
                              ? ' – ${l10n.settingMin}'
                              : k.key.endsWith('.max')
                              ? ' – ${l10n.settingMax}'
                              : ''}',
                      handbook: formatNumber(
                        k.read(DomainConfig.defaults).toDouble(),
                        locale,
                      ),
                      field: _fields[k.key]!,
                    ),
                ],
              ),
            ),
            rule(),
          ],
          // Not a farming number: kept out of DomainConfig (plan Decision 11).
          FoldedSection(
            title: l10n.settingsPhotos,
            summary: l10n.settingsChanged(changed([_photoCap])),
            builder: (context) => value(
              key: const Key('setting-$photoUploadCapKey'),
              label: l10n.settingPhotoUploadCap,
              handbook: '$defaultPhotoUploadCap',
              field: _photoCap,
              decimal: false,
            ),
          ),
          rule(),
        ],
      ),
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
  'feedUsageDays' => l10n.cfgFeedUsageDays,
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
