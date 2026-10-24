// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

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

  @override
  String get morePeople => 'Personnes';

  @override
  String get moreBatches => 'Lots';

  @override
  String get personName => 'Nom';

  @override
  String get personPhone => 'Téléphone';

  @override
  String get personNote => 'Note';

  @override
  String get personActive => 'Actif';

  @override
  String get personInactive => 'Inactif';

  @override
  String get save => 'Enregistrer';

  @override
  String get add => 'Ajouter';

  @override
  String get peopleEmpty =>
      'Aucune personne : ajoutez les ouvriers et les membres';

  @override
  String get pondAdd => 'Ajouter un étang';

  @override
  String get pondsEmpty => 'Aucun étang : ajoutez le premier';

  @override
  String get pondCode => 'Code';

  @override
  String get pondColourLabel => 'Couleur';

  @override
  String get pondStructure => 'Type';

  @override
  String get pondRoleLabel => 'Rôle';

  @override
  String get pondWaterSupply => 'Alimentation en eau';

  @override
  String get notSpecified => 'Non précisé';

  @override
  String get pondLength => 'Longueur';

  @override
  String get pondWidth => 'Largeur';

  @override
  String get pondSurfaceOverride => 'Surface mesurée (facultatif)';

  @override
  String get pondDepthInlet => 'Profondeur à l\'entrée';

  @override
  String get pondDepthOutlet => 'Profondeur à la sortie';

  @override
  String get pondStatusLabel => 'État';

  @override
  String get duplicateCode => 'Ce code existe déjà';

  @override
  String get pondFish => 'Poissons';

  @override
  String get pondBiomass => 'Biomasse';

  @override
  String get pondDensity => 'Densité';

  @override
  String get pondSurface => 'Surface';

  @override
  String get inconsistent => 'À vérifier';

  @override
  String get pondStock => 'Empoissonner';

  @override
  String get pondTransfer => 'Transférer';

  @override
  String get edit => 'Modifier';

  @override
  String get archive => 'Archiver';

  @override
  String get cancel => 'Annuler';

  @override
  String get avgWeight => 'Poids moyen';

  @override
  String get pondNoFish => 'Pas de poissons';

  @override
  String get adultFeed => 'aliment adulte';

  @override
  String pondSurfaceComputed(String surface) {
    return 'Surface calculée : $surface';
  }

  @override
  String densityValue(String density) {
    return '$density /m²';
  }

  @override
  String archiveConfirm(String code) {
    return 'Archiver l\'étang $code ? Il disparaîtra des listes.';
  }

  @override
  String feedingGuide(String protein, String pellet, String meals) {
    return 'Aliment : $protein de protéines, granulé $pellet, $meals repas par jour';
  }

  @override
  String get stockTitle => 'Empoissonner';

  @override
  String get batchCode => 'Code du lot';

  @override
  String get stockDate => 'Date d\'empoissonnement';

  @override
  String get stockCount => 'Nombre d\'alevins';

  @override
  String get strain => 'Souche (ex. GIFT)';

  @override
  String get hatchery => 'Écloserie';

  @override
  String get certificate => 'N° de certificat sanitaire';

  @override
  String get monosex => 'Tout mâle (monosexe)';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get unknown => 'Ne sait pas';

  @override
  String get plannedHarvest => 'Récolte prévue (facultatif)';

  @override
  String get pickPond => 'Étang';

  @override
  String get warnPondIsolated => 'Étang isolé : à éviter';

  @override
  String get warnDensityBelow => 'Densité sous le minimum conseillé';

  @override
  String get warnDensityAbove => 'Densité au-dessus du maximum conseillé';

  @override
  String get batchesEmpty => 'Aucun lot : empoissonnez un étang depuis sa page';

  @override
  String get history => 'Historique';

  @override
  String get eventStocking => 'Empoissonnement';

  @override
  String get eventTransfer => 'Transfert';

  @override
  String get correct => 'Corriger';

  @override
  String get delete => 'Supprimer';

  @override
  String get deleteConfirm => 'Supprimer cet enregistrement ?';

  @override
  String get fishPerPond => 'Poissons par étang';

  @override
  String get batchEdit => 'Modifier le lot';

  @override
  String get correctionTitle => 'Corriger';

  @override
  String acclimatised(String min, String max) {
    return 'Acclimatés $min à $max min';
  }

  @override
  String acclimatiseReminder(String min, String max) {
    return 'Faire flotter le sac fermé $min à $max min sur l\'étang avant de lâcher les alevins.';
  }

  @override
  String densityResult(String density, String min, String max) {
    return 'Densité après empoissonnement : $density /m² (conseillé : $min à $max)';
  }

  @override
  String warnPondNotReady(String status) {
    return 'L\'étang n\'est pas marqué prêt ($status)';
  }

  @override
  String warnWeightOutsideRange(String min, String max) {
    return 'Poids moyen hors des $min à $max g conseillés';
  }

  @override
  String stockedOn(String date) {
    return 'Empoissonné le $date';
  }

  @override
  String initialStock(String count, String weight, String date) {
    return 'Départ : $count alevins de $weight, le $date';
  }

  @override
  String plannedHarvestOn(String date) {
    return 'Récolte prévue le $date';
  }

  @override
  String get toPond => 'Vers l\'étang';

  @override
  String get transferCount => 'Nombre de poissons';

  @override
  String get transferDate => 'Date du transfert';

  @override
  String get avgWeightOptional => 'Poids moyen (facultatif)';

  @override
  String get warnDestIsolated => 'L\'étang de destination est isolé';

  @override
  String get isolatedSource => 'Étang isolé : aucun poisson ne doit en sortir';

  @override
  String transferTitle(String code, String pond) {
    return 'Transférer $code depuis $pond';
  }

  @override
  String estimateIn(String count, String pond) {
    return '≈ $count dans $pond';
  }

  @override
  String warnAboveEstimate(String count) {
    return 'Plus que l\'estimation ($count)';
  }

  @override
  String destDensity(String pond, String density, String min, String max) {
    return 'Densité de $pond après transfert : $density /m² (conseillé : $min à $max)';
  }

  @override
  String get pondNotEmpty =>
      'Cet étang contient encore des poissons : transférez-les d\'abord.';

  @override
  String get signNoAppetite => 'Ne mange pas';

  @override
  String get signSurfaceSwimming => 'Nage en surface';

  @override
  String get signNearBanks => 'Reste près des bords';

  @override
  String get signErraticOrCircling => 'Nage en rond';

  @override
  String get signAbnormalColour => 'Couleur anormale';

  @override
  String get signSkinLesions => 'Plaies sur la peau';

  @override
  String get signPaleOrSwollenGills => 'Branchies pâles ou gonflées';

  @override
  String get signGroupedDeaths => 'Morts en groupe';

  @override
  String get signRubbing => 'Se frotte';

  @override
  String get signExcessMucus => 'Trop de mucus';

  @override
  String get signWhiteSpots => 'Points blancs';

  @override
  String get signBulgingEyes => 'Yeux gonflés';

  @override
  String get signFinBleeding => 'Nageoires qui saignent';

  @override
  String get leftoverNone => 'Tout mangé';

  @override
  String get leftoverSome => 'Un peu de reste';

  @override
  String get leftoverLots => 'Beaucoup de reste';

  @override
  String get ateFast => 'Mangé très vite';

  @override
  String get waterClear => 'Claire';

  @override
  String get waterLightGreen => 'Vert clair';

  @override
  String get waterMediumGreen => 'Vert';

  @override
  String get waterDarkGreen => 'Vert foncé';

  @override
  String get waterBrownTurbid => 'Marron, trouble';

  @override
  String get obsDike => 'Digues';

  @override
  String get obsInletScreen => 'Grilles d\'entrée';

  @override
  String get obsPredatorNets => 'Filets anti-prédateurs';

  @override
  String get obsFence => 'Clôture';

  @override
  String get obsGrass => 'Herbe';

  @override
  String get obsPredators => 'Prédateurs';

  @override
  String get obsTheft => 'Vol';

  @override
  String get obsOther => 'Autre';

  @override
  String get workerMode => 'Mode ouvrier';

  @override
  String get workerToday => 'Aujourd\'hui';

  @override
  String get workerExit => 'Quitter';

  @override
  String get dailyLog => 'Journal du jour';

  @override
  String get feedGiven => 'Aliment donné';

  @override
  String get feedings => 'Repas donnés';

  @override
  String get leftovers => 'Reste';

  @override
  String get deaths => 'Morts';

  @override
  String get deathAppearance => 'Aspect des morts';

  @override
  String get signsSeen => 'Signes';

  @override
  String get waterColourLabel => 'Couleur de l\'eau';

  @override
  String get addNote => 'Ajouter une note';

  @override
  String get noteLabel => 'Note';

  @override
  String get saved => 'Enregistré';

  @override
  String get pondIsolatedBanner => 'Étang isolé';

  @override
  String rationHint(String amount) {
    return '≈ $amount';
  }

  @override
  String get waterReading => 'Relevé d\'eau';

  @override
  String get sampling => 'Échantillonnage';

  @override
  String get temperature => 'Température';

  @override
  String get ph => 'pH';

  @override
  String get oxygen => 'Oxygène dissous';

  @override
  String get renewedPct => 'Eau renouvelée';

  @override
  String get readingTime => 'Heure du relevé';

  @override
  String get sampleFish => 'Poissons pesés';

  @override
  String get sampleWeight => 'Poids total';

  @override
  String get sampleDate => 'Date de pesée';

  @override
  String get renewWater => 'Couleur : renouveler l\'eau';

  @override
  String targetRange(String min, String max, String unit) {
    return 'cible $min à $max $unit';
  }

  @override
  String targetMin(String min, String unit) {
    return 'cible $min $unit ou plus';
  }

  @override
  String lastReading(String date) {
    return 'Dernier relevé, le $date :';
  }

  @override
  String smallSample(String min) {
    return 'Petit échantillon (moins de $min poissons)';
  }

  @override
  String sampleAverage(String weight) {
    return 'Poids moyen : $weight';
  }

  @override
  String get transcription => 'Saisie des fiches';

  @override
  String get sheetOf => 'Fiche de';

  @override
  String get previousWeek => 'Semaine précédente';

  @override
  String get nextWeek => 'Semaine suivante';

  @override
  String get feedMissing =>
      'Indiquez l\'aliment pour chaque case remplie (0 si rien n\'a été donné).';

  @override
  String weekOfLabel(String date) {
    return 'Semaine du $date';
  }
}
