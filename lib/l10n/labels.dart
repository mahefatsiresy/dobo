import 'package:flutter/widgets.dart';

import '../domain/config.dart';
import '../domain/pond.dart';
import '../domain/stock.dart';
import '../domain/types.dart';
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
}
