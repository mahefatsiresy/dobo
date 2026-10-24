// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malagasy (`mg`).
class AppLocalizationsMg extends AppLocalizations {
  AppLocalizationsMg([String locale = 'mg']) : super(locale);

  @override
  String get appTitle => 'Dobo';

  @override
  String get setupTitle => 'Installation';

  @override
  String get setupSiteName => 'Nom du site';

  @override
  String get setupLocationNote => 'Lieu (facultatif)';

  @override
  String get setupStart => 'Commencer';

  @override
  String get tabPonds => 'Étangs';

  @override
  String get tabMore => 'Plus';

  @override
  String get fieldRequired => 'Obligatoire';

  @override
  String get estimated => 'estimé';

  @override
  String get pondStatusEmpty => 'Vide';

  @override
  String get pondStatusPreparing => 'En préparation';

  @override
  String get pondStatusReady => 'Prêt';

  @override
  String get pondStatusStocked => 'Empoissonné';

  @override
  String get pondStatusIsolated => 'Isolé';

  @override
  String get structureEarth => 'Étang en terre';

  @override
  String get structureTank => 'Bassin';

  @override
  String get structureCage => 'Cage flottante';

  @override
  String get roleBreeding => 'Reproduction';

  @override
  String get roleNursery => 'Frayère (alevins)';

  @override
  String get rolePregrow => 'Prégrossissement';

  @override
  String get roleGrowout => 'Grossissement';

  @override
  String get roleHolding => 'Stockage avant vente';

  @override
  String get roleQuarantine => 'Quarantaine';

  @override
  String get supplyBarrage => 'Barrage';

  @override
  String get supplyDerivation => 'Dérivation';

  @override
  String get supplyMarsh => 'Marais';

  @override
  String get colourBlue => 'Bleu';

  @override
  String get colourGreen => 'Vert';

  @override
  String get colourYellow => 'Jaune';

  @override
  String get colourOrange => 'Orange';

  @override
  String get colourRed => 'Rouge';

  @override
  String get colourPurple => 'Violet';

  @override
  String get colourBrown => 'Marron';

  @override
  String get colourBlack => 'Noir';

  @override
  String get batchStatusQuarantine => 'Quarantaine';

  @override
  String get batchStatusActive => 'Actif';

  @override
  String get batchStatusHarvesting => 'En récolte';

  @override
  String get batchStatusClosed => 'Clôturé';

  @override
  String get phaseFry => 'Alevinage';

  @override
  String get phasePregrow => 'Prégrossissement';

  @override
  String get phaseGrowout => 'Grossissement';

  @override
  String get phaseFinishing => 'Finition';

  @override
  String get densityBelow => 'Densité trop faible';

  @override
  String get densityWithin => 'Densité correcte';

  @override
  String get densityAbove => 'Densité trop forte';

  @override
  String warnSurfaceTooSmall(String min, String max) {
    return 'Surface sous $min m² (conseillé : $min à $max m²)';
  }

  @override
  String warnSurfaceTooLarge(String min, String max) {
    return 'Surface au-dessus de $max m² (conseillé : $min à $max m²)';
  }

  @override
  String warnNotElongated(String min, String max) {
    return 'Étang peu allongé (conseillé : longueur = $min à $max fois la largeur)';
  }

  @override
  String warnTooElongated(String min, String max) {
    return 'Étang très allongé (conseillé : longueur = $min à $max fois la largeur)';
  }

  @override
  String warnTooShallow(String min) {
    return 'Profondeur moyenne sous $min m';
  }
}
