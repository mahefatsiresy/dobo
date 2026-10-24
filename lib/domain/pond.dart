import 'dart:math';

import 'config.dart';
import 'types.dart';

class PrepDoses {
  const PrepDoses(this.limeKg, this.manureKg);

  final Range<double> limeKg;
  final Range<double> manureKg;
}

/// Quicklime and manure for one pond. DOMAIN §Formulas.
PrepDoses? prepDoses(double? surfaceM2, DomainConfig config) {
  if (surfaceM2 == null || surfaceM2 <= 0) return null;
  Range<double> scale(Range<double> perM2) =>
      Range(perM2.min * surfaceM2, perM2.max * surfaceM2);
  return PrepDoses(scale(config.limeKgPerM2), scale(config.manureKgPerM2));
}

enum PondDesignWarning {
  surfaceTooSmall,
  surfaceTooLarge,
  notElongated,
  tooElongated,
  tooShallow,
}

/// Soft design guidance shown at pond setup. DOMAIN §Ponds.
Set<PondDesignWarning> pondDesignWarnings({
  double? lengthM,
  double? widthM,
  double? depthInletM,
  double? depthOutletM,
  required DomainConfig config,
}) {
  final warnings = <PondDesignWarning>{};
  if (lengthM != null && widthM != null && lengthM > 0 && widthM > 0) {
    final surface = lengthM * widthM;
    if (surface < config.pondSurfaceM2.min) {
      warnings.add(PondDesignWarning.surfaceTooSmall);
    } else if (surface > config.pondSurfaceM2.max) {
      warnings.add(PondDesignWarning.surfaceTooLarge);
    }
    final ratio = max(lengthM, widthM) / min(lengthM, widthM);
    if (ratio < config.pondLengthWidthRatio.min) {
      warnings.add(PondDesignWarning.notElongated);
    } else if (ratio > config.pondLengthWidthRatio.max) {
      warnings.add(PondDesignWarning.tooElongated);
    }
  }
  // Inlet and outlet differ by design (0.8–1 m vs 1.2–1.5 m), so one depth
  // alone says nothing about the mean.
  if (depthInletM != null &&
      depthOutletM != null &&
      (depthInletM + depthOutletM) / 2 < config.minDepthM) {
    warnings.add(PondDesignWarning.tooShallow);
  }
  return warnings;
}
