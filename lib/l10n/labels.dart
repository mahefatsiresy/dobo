import 'package:flutter/widgets.dart';

import '../domain/feed_stock.dart';
import '../domain/alerts/alert.dart';
import '../domain/config.dart';
import '../domain/pond.dart';
import '../domain/report/report_content.dart';
import '../domain/stock.dart';
import '../domain/types.dart';
import '../domain/water.dart';
import 'app_localizations.dart';
import 'formatting.dart';

/// Display names for domain enums; the domain itself returns no text.
extension EnumLabels on AppLocalizations {
  String pondStatus(PondStatus s) => switch (s) {
    PondStatus.empty => pondStatusEmpty,
    PondStatus.preparing => pondStatusPreparing,
    PondStatus.ready => pondStatusReady,
    PondStatus.stocked => pondStatusStocked,
    PondStatus.isolated => pondStatusIsolated,
  };

  String structure(StructureType s) => switch (s) {
    StructureType.earth => structureEarth,
    StructureType.tank => structureTank,
    StructureType.cage => structureCage,
  };

  String pondRole(PondRole r) => switch (r) {
    PondRole.breeding => roleBreeding,
    PondRole.nursery => roleNursery,
    PondRole.pregrow => rolePregrow,
    PondRole.growout => roleGrowout,
    PondRole.holding => roleHolding,
    PondRole.quarantine => roleQuarantine,
  };

  String waterSupply(WaterSupply w) => switch (w) {
    WaterSupply.barrage => supplyBarrage,
    WaterSupply.derivation => supplyDerivation,
    WaterSupply.marsh => supplyMarsh,
  };

  String pondColour(PondColour c) => switch (c) {
    PondColour.blue => colourBlue,
    PondColour.green => colourGreen,
    PondColour.yellow => colourYellow,
    PondColour.orange => colourOrange,
    PondColour.red => colourRed,
    PondColour.purple => colourPurple,
    PondColour.brown => colourBrown,
    PondColour.black => colourBlack,
  };

  String batchStatus(BatchStatus s) => switch (s) {
    BatchStatus.quarantine => batchStatusQuarantine,
    BatchStatus.active => batchStatusActive,
    BatchStatus.harvesting => batchStatusHarvesting,
    BatchStatus.closed => batchStatusClosed,
  };

  String phase(Phase p) => switch (p) {
    Phase.fry => phaseFry,
    Phase.pregrow => phasePregrow,
    Phase.growout => phaseGrowout,
    Phase.finishing => phaseFinishing,
  };

  String densityStatus(DensityStatus s) => switch (s) {
    DensityStatus.below => densityBelow,
    DensityStatus.within => densityWithin,
    DensityStatus.above => densityAbove,
  };

  /// Soft design guidance, quoting the DOMAIN ranges from [config].
  String pondDesignWarning(PondDesignWarning w, DomainConfig config) {
    final locale = Locale(localeName);
    String n(double v) => formatNumber(v, locale);
    return switch (w) {
      PondDesignWarning.surfaceTooSmall => warnSurfaceTooSmall(
        n(config.pondSurfaceM2.min),
        n(config.pondSurfaceM2.max),
      ),
      PondDesignWarning.surfaceTooLarge => warnSurfaceTooLarge(
        n(config.pondSurfaceM2.min),
        n(config.pondSurfaceM2.max),
      ),
      PondDesignWarning.notElongated => warnNotElongated(
        n(config.pondLengthWidthRatio.min),
        n(config.pondLengthWidthRatio.max),
      ),
      PondDesignWarning.tooElongated => warnTooElongated(
        n(config.pondLengthWidthRatio.min),
        n(config.pondLengthWidthRatio.max),
      ),
      PondDesignWarning.tooShallow => warnTooShallow(n(config.minDepthM)),
    };
  }

  String warningSign(WarningSign s) => switch (s) {
    WarningSign.noAppetite => signNoAppetite,
    WarningSign.surfaceSwimming => signSurfaceSwimming,
    WarningSign.nearBanks => signNearBanks,
    WarningSign.erraticOrCircling => signErraticOrCircling,
    WarningSign.abnormalColour => signAbnormalColour,
    WarningSign.skinLesions => signSkinLesions,
    WarningSign.paleOrSwollenGills => signPaleOrSwollenGills,
    WarningSign.groupedDeaths => signGroupedDeaths,
    WarningSign.rubbing => signRubbing,
    WarningSign.excessMucus => signExcessMucus,
    WarningSign.whiteSpots => signWhiteSpots,
    WarningSign.bulgingEyes => signBulgingEyes,
    WarningSign.finBleeding => signFinBleeding,
  };

  String leftover(Leftover l) => switch (l) {
    Leftover.none => leftoverNone,
    Leftover.some => leftoverSome,
    Leftover.lots => leftoverLots,
  };

  String waterColour(WaterColour c) => switch (c) {
    WaterColour.clear => waterClear,
    WaterColour.lightGreen => waterLightGreen,
    WaterColour.mediumGreen => waterMediumGreen,
    WaterColour.darkGreen => waterDarkGreen,
    WaterColour.brownTurbid => waterBrownTurbid,
  };

  String prepStep(PrepStep s) => switch (s) {
    PrepStep.drain => prepStepDrain,
    PrepStep.dry => prepStepDry,
    PrepStep.treat => prepStepTreat,
    PrepStep.fertilise => prepStepFertilise,
    PrepStep.fill => prepStepFill,
    PrepStep.rest => prepStepRest,
  };

  String productForm(ProductForm f) => switch (f) {
    ProductForm.live => formLive,
    ProductForm.fresh => formFresh,
    ProductForm.frozen => formFrozen,
    ProductForm.smoked => formSmoked,
    ProductForm.dried => formDried,
  };

  String customerTypeLabel(CustomerType t) => switch (t) {
    CustomerType.market => custMarket,
    CustomerType.restaurant => custRestaurant,
    CustomerType.supermarket => custSupermarket,
    CustomerType.exporter => custExporter,
    CustomerType.individual => custIndividual,
  };

  String discardReason(DiscardReason r) => switch (r) {
    DiscardReason.mould => discardMould,
    DiscardReason.rancid => discardRancid,
    DiscardReason.clumped => discardClumped,
    DiscardReason.other => discardOther,
  };

  String prepProduct(PrepProduct p) => switch (p) {
    PrepProduct.quicklime => prepProductQuicklime,
    PrepProduct.chlorine => prepProductChlorine,
    PrepProduct.manure => prepProductManure,
  };

  String observationCategory(ObservationCategory c) => switch (c) {
    ObservationCategory.dike => obsDike,
    ObservationCategory.inletScreen => obsInletScreen,
    ObservationCategory.predatorNets => obsPredatorNets,
    ObservationCategory.fence => obsFence,
    ObservationCategory.grass => obsGrass,
    ObservationCategory.predators => obsPredators,
    ObservationCategory.theft => obsTheft,
    ObservationCategory.other => obsOther,
  };

  /// One line saying what [a] is about. [batchCode] names its batch.
  String alertText(Alert a, {String? batchCode}) {
    final locale = Locale(localeName);
    final batch = batchCode ?? '?';
    final f = a.facts;
    return switch (a.kind) {
      AlertKind.waterOutOfRange => _water(f, locale),
      AlertKind.fcrWorsening => alertFcrWorsening(batch),
      AlertKind.growthStalled => alertGrowthStalled(batch),
      AlertKind.mortalitySpike => alertMortalitySpike(
        formatCount(f['deathsToday']! as int, locale),
        formatDate(f['date']! as DateTime),
      ),
      AlertKind.warningSignSeen => alertWarningSignSeen(
        (f['signs']! as Set<WarningSign>).map(warningSign).join(', '),
      ),
      AlertKind.densityOutOfRange => densityStatus(
        f['status']! as DensityStatus,
      ),
      AlertKind.phaseChange => alertPhaseChange(
        batch,
        phase(f['to']! as Phase),
      ),
      AlertKind.sampleDue => alertSampleDue(batch, '${f['daysSince']}'),
      AlertKind.waterCheckDue => alertWaterCheckDue,
      AlertKind.quarantineEnding => alertQuarantineEnding(
        batch,
        '${f['days']}',
        '${f['recommendedDays']}',
      ),
      AlertKind.preHarvestFast =>
        f['fedDuringFast'] == true
            ? alertPreHarvestFed(batch)
            : alertPreHarvestFast(batch),
      AlertKind.feedStockLow => alertFeedStockLow(
        formatDecimal(f['daysLeft']! as double, locale, decimals: 0),
      ),
      AlertKind.feedTooOld =>
        f['age'] == FeedAge.expired ? alertFeedExpired : alertFeedOld,
      AlertKind.prepStepDue =>
        f['waitingStep'] == PrepStep.rest ? alertPrepRest : alertPrepDry,
      AlertKind.duplicateDailyLog => alertDuplicateLog(
        formatDate(f['date']! as DateTime),
      ),
    };
  }

  /// A report's "next" item, without its date.
  String reportNextText(
    NextItem n, {
    required String pond,
    required String batch,
  }) => switch (n.kind) {
    NextKind.sample => reportNextSample(batch),
    NextKind.harvest => reportNextHarvest(batch),
    NextKind.quarantineRelease => reportNextQuarantine(batch),
    NextKind.prepStep =>
      n.step == PrepStep.rest ? reportNextRest(pond) : reportNextDry(pond),
  };

  /// The report's feed stock lines; one "not tracked" line without stock.
  List<String> reportFeedStockLines(FeedStockSection? s, Locale locale) {
    if (s == null) return [reportFeedStockLater];
    final onHand = formatKg(s.onHandG, locale);
    return [
      s.daysLeft == null
          ? reportFeedOnHandNoUsage(onHand)
          : reportFeedOnHand(
              onHand,
              formatDecimal(s.daysLeft!, locale, decimals: 0),
            ),
      if (s.overdrawnG > 0) feedOverdrawn(formatKg(s.overdrawnG, locale)),
      for (final l in s.lots)
        () {
          final text = reportFeedLot(
            [
              if (l.label != null) l.label!,
              phase(l.phase),
            ].join(reportListSeparator),
            formatKg(l.balanceG, locale),
            formatDate(l.manufacturedOn),
          );
          return switch (l.age) {
            FeedAge.ok => text,
            FeedAge.old => labelValue(text, feedLotOld),
            FeedAge.expired => labelValue(text, feedLotExpired),
          };
        }(),
    ];
  }

  String _water(Map<String, Object?> f, Locale locale) {
    final param = f['param']! as WaterParam;
    if (param == WaterParam.colour) return alertWaterColour;
    final v = f['value']! as double;
    final (name, value) = switch (param) {
      WaterParam.temperature => (temperature, '${formatNumber(v, locale)} °C'),
      WaterParam.ph => (ph, formatNumber(v, locale)),
      WaterParam.oxygen => (oxygen, '${formatNumber(v, locale)} mg/L'),
      WaterParam.colour => throw StateError('handled above'),
    };
    return f['direction'] == Direction.high
        ? alertWaterHigh(name, value)
        : alertWaterLow(name, value);
  }
}
