import 'package:flutter/material.dart';

import '../../domain/types.dart';

/// Stand-in pictograms until the worker's artwork, chosen from the field
/// test (`docs/field-test.md`). The paper sheet draws the same glyphs from
/// `pictogram_paths.dart`: change an icon here, then rerun
/// `tool/pictogram_paths.py` so paper and screen stay alike.
IconData warningSignIcon(WarningSign s) => switch (s) {
  WarningSign.noAppetite => Icons.no_food,
  WarningSign.surfaceSwimming => Icons.vertical_align_top,
  WarningSign.nearBanks => Icons.border_outer,
  WarningSign.erraticOrCircling => Icons.loop,
  WarningSign.abnormalColour => Icons.palette,
  WarningSign.skinLesions => Icons.healing,
  WarningSign.paleOrSwollenGills => Icons.air,
  WarningSign.groupedDeaths => Icons.groups,
  WarningSign.rubbing => Icons.swipe,
  WarningSign.excessMucus => Icons.water_drop,
  WarningSign.whiteSpots => Icons.grain,
  WarningSign.bulgingEyes => Icons.visibility,
  WarningSign.finBleeding => Icons.bloodtype,
};

/// A bowl that is empty, half full or full.
IconData leftoverIcon(Leftover l) => switch (l) {
  Leftover.none => Icons.panorama_fish_eye,
  Leftover.some => Icons.contrast,
  Leftover.lots => Icons.circle,
};

/// What the water looks like, for the colour swatches.
Color waterColourValue(WaterColour c) => switch (c) {
  WaterColour.clear => const Color(0xFFE3F2FD),
  WaterColour.lightGreen => const Color(0xFFAED581),
  WaterColour.mediumGreen => const Color(0xFF7CB342),
  WaterColour.darkGreen => const Color(0xFF33691E),
  WaterColour.brownTurbid => const Color(0xFF8D6E63),
};
