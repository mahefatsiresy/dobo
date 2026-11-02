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
  String personOfMember(String name) {
    return '$name (membre)';
  }

  @override
  String personOfWorker(String name) {
    return '$name (ouvrier)';
  }

  @override
  String get personRenameFromAdmin => 'Renommer depuis Admin › Membres';

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

  @override
  String get reportProblem => 'Signaler un problème';

  @override
  String get suspectedIssue => 'Problème suspecté (facultatif)';

  @override
  String get isolatePond => 'Isoler l\'étang';

  @override
  String get technicianCalled => 'Technicien ou vétérinaire appelé';

  @override
  String get healthResponse =>
      'Isoler l\'étang, ne déplacer ni poissons ni eau vers les autres étangs, appeler un technicien ou un vétérinaire avant tout traitement.';

  @override
  String get healthInfoTitle => 'Information, pas un diagnostic';

  @override
  String get diseaseStrepto => 'Streptococcose';

  @override
  String get diseaseStreptoSigns =>
      'nage désordonnée, yeux gonflés, mortalité rapide ; favorisée par une forte densité et la chaleur.';

  @override
  String get diseaseAeromonas => 'Aeromonas';

  @override
  String get diseaseAeromonasSigns =>
      'ulcères de la peau, nageoires qui saignent ; liée à une eau de mauvaise qualité ou aux blessures de manipulation.';

  @override
  String get diseaseParasites => 'Parasites externes (Trichodina, Ich)';

  @override
  String get diseaseParasitesSigns =>
      'se frotte aux parois ou au fond, trop de mucus, points blancs.';

  @override
  String get releaseIsolation => 'Lever l\'isolement';

  @override
  String get treatment => 'Traitement';

  @override
  String get product => 'Produit';

  @override
  String get dose => 'Dose';

  @override
  String get advisedBy => 'Conseillé par';

  @override
  String get treatmentDate => 'Date du traitement';

  @override
  String get healthHistory => 'Santé';

  @override
  String get actionIsolated => 'isolé';

  @override
  String get actionTechnician => 'technicien appelé';

  @override
  String get actionReleased => 'isolement levé';

  @override
  String get batchOptional => 'Lot (facultatif)';

  @override
  String releaseConfirm(String code) {
    return 'Lever l\'isolement de $code ? Les poissons pourront de nouveau en sortir.';
  }

  @override
  String get tabVisit => 'Visite';

  @override
  String get startVisit => 'Démarrer une visite';

  @override
  String get sectionWater => 'Eau';

  @override
  String get sectionSamples => 'Échantillons';

  @override
  String get sectionConditions => 'État des étangs';

  @override
  String get sectionBiosecurity => 'Biosécurité';

  @override
  String get sectionObservations => 'Observations';

  @override
  String get summary => 'Résumé';

  @override
  String get allDone => 'Tout est fait';

  @override
  String get endVisit => 'Terminer la visite';

  @override
  String get endVisitConfirm =>
      'Terminer la visite ? Le rapport sera préparé à partir de ce qui a été saisi.';

  @override
  String get visitEnded => 'terminée';

  @override
  String get visitOngoing => 'en cours';

  @override
  String get addObservation => 'Ajouter une observation';

  @override
  String get observationText => 'Observation';

  @override
  String get category => 'Catégorie';

  @override
  String get conditionOk => 'OK';

  @override
  String get conditionProblem => 'Problème';

  @override
  String get pastVisits => 'Visites précédentes';

  @override
  String get noVisits => 'Aucune visite pour l\'instant';

  @override
  String get bioDisinfect =>
      'Filets, seaux et épuisettes désinfectés entre les étangs (chlore dilué, puis rinçage)';

  @override
  String get bioToolsPerPond => 'Un jeu d\'outils par étang si possible';

  @override
  String get bioFootbath => 'Pédiluve ou bottes propres à l\'entrée';

  @override
  String get bioAnimals => 'Canards et autres animaux tenus à l\'écart';

  @override
  String get bioPredators =>
      'Filets anti-prédateurs et petite clôture en place';

  @override
  String get bioProtection => 'Gants et bottes pour la chaux et le chlore';

  @override
  String get bioNotAlone =>
      'Personne ne travaille seul pendant une vidange ou une grosse pêche';

  @override
  String visitOpenSince(String time) {
    return 'Visite en cours depuis $time';
  }

  @override
  String sampleOfIn(String batch, String pond) {
    return '$batch dans $pond';
  }

  @override
  String conditionsOf(String pond) {
    return 'État de $pond';
  }

  @override
  String visitLine(String date, String state) {
    return '$date · $state';
  }

  @override
  String get welcomeTitle => 'Bienvenue';

  @override
  String get welcomeMember => 'Se connecter (membre)';

  @override
  String get welcomeWorker => 'Je suis ouvrier';

  @override
  String get welcomeCreate => 'Créer l\'association';

  @override
  String get loginTitle => 'Connexion';

  @override
  String get loginEmail => 'Adresse e-mail';

  @override
  String get loginPassword => 'Mot de passe';

  @override
  String get loginUsername => 'Nom d\'utilisateur';

  @override
  String get loginPin => 'Code PIN (6 chiffres)';

  @override
  String get loginSubmit => 'Se connecter';

  @override
  String get errorOffline => 'Connexion nécessaire';

  @override
  String get errorBadLogin => 'Identifiant ou mot de passe incorrect';

  @override
  String get errorOtherAssociation =>
      'Ce téléphone contient les données d\'une autre association. Exportez d\'abord une sauvegarde.';

  @override
  String get errorNoMember => 'Ce compte n\'est pas actif';

  @override
  String get errorNoSite =>
      'L\'association n\'a pas encore de site : synchronisez d\'abord le téléphone du fondateur.';

  @override
  String get errorTaken => 'Cet identifiant est déjà utilisé';

  @override
  String errorFailed(String code) {
    return 'Échec : $code';
  }

  @override
  String get passwordTooShort => '8 caractères au moins';

  @override
  String get pinSixDigits => '6 chiffres';

  @override
  String get createTitle => 'Créer l\'association';

  @override
  String get createAssociationName => 'Nom de l\'association';

  @override
  String get createGroupName => 'Nom de votre branche';

  @override
  String get createYourName => 'Votre nom';

  @override
  String get createSubmit => 'Créer';

  @override
  String get moreAccount => 'Compte';

  @override
  String get accountSignOut => 'Se déconnecter';

  @override
  String get accountSignOutQuestion => 'Se déconnecter de ce téléphone ?';

  @override
  String accountSignOutPending(int count) {
    return '$count enregistrements ne sont pas encore envoyés. Ils restent sur ce téléphone et partiront à la prochaine synchronisation.';
  }

  @override
  String get accountRole => 'Rôle';

  @override
  String get roleMember => 'Membre';

  @override
  String get roleWorker => 'Ouvrier';

  @override
  String get roleAdmin => 'Administrateur';

  @override
  String get roleSales => 'Ventes';

  @override
  String get moreSync => 'Synchronisation';

  @override
  String syncLast(String at) {
    return 'Dernière synchronisation : $at';
  }

  @override
  String get syncNever => 'Jamais synchronisé';

  @override
  String syncPending(int count) {
    return 'En attente d\'envoi : $count';
  }

  @override
  String syncRejectedCount(int count) {
    return 'Refusés : $count';
  }

  @override
  String get syncNow => 'Synchroniser';

  @override
  String get syncRetry => 'Réessayer les refusés';

  @override
  String get syncRelogin => 'Se reconnecter';

  @override
  String get syncLink => 'Créer le compte de l\'association';

  @override
  String get syncStateRunning => 'Synchronisation en cours…';

  @override
  String get syncStateOffline =>
      'Pas de connexion : les données restent sur le téléphone.';

  @override
  String get syncStateSignedOut =>
      'Session terminée : reconnectez-vous pour envoyer les données.';

  @override
  String get syncStateUnlinked => 'Ce téléphone n\'est relié à aucun compte.';

  @override
  String get syncStateNotConfigured =>
      'Aucun serveur dans cette version : les données restent sur le téléphone.';

  @override
  String syncStateFailed(String error) {
    return 'La synchronisation a échoué : $error';
  }

  @override
  String get rejectRole => 'Votre rôle ne permet pas cet enregistrement';

  @override
  String get rejectLastAdmin => 'Il doit rester au moins un administrateur';

  @override
  String rejectOther(String reason) {
    return 'Refusé : $reason';
  }

  @override
  String get tableDailyLogs => 'Journal';

  @override
  String get tableWaterReadings => 'Relevé d\'eau';

  @override
  String get tableSamples => 'Échantillonnage';

  @override
  String get tableObservations => 'Observation';

  @override
  String get tableHealthEvents => 'Problème de santé';

  @override
  String get tableTreatments => 'Traitement';

  @override
  String get tableStockings => 'Empoissonnement';

  @override
  String get tableTransfers => 'Transfert';

  @override
  String get tablePonds => 'Étang';

  @override
  String get tableBatches => 'Lot';

  @override
  String get tablePeople => 'Personne';

  @override
  String get tableSites => 'Site';

  @override
  String get tableVisits => 'Visite';

  @override
  String get tableGroups => 'Branche';

  @override
  String get tableMembers => 'Membre';

  @override
  String get tableSettingOverrides => 'Réglage';

  @override
  String get backupExport => 'Exporter une sauvegarde';

  @override
  String get backupImport => 'Importer une sauvegarde';

  @override
  String backupImported(int added, int updated) {
    return '$added enregistrements ajoutés, $updated mis à jour';
  }

  @override
  String get backupNotABackup => 'Ce fichier n\'est pas une sauvegarde Dobo';

  @override
  String get backupOtherAssociation =>
      'Cette sauvegarde appartient à une autre association';

  @override
  String get moreAdmin => 'Administration';

  @override
  String get moreLanguage => 'Langue';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageMalagasy => 'Malagasy';

  @override
  String get adminMembers => 'Membres';

  @override
  String get adminGroups => 'Branches';

  @override
  String get memberNew => 'Nouveau compte';

  @override
  String get memberName => 'Nom';

  @override
  String get memberGroup => 'Branche';

  @override
  String get memberNoGroup => 'Sans branche';

  @override
  String get memberActive => 'Actif';

  @override
  String get memberPerson => 'Fiche de l\'ouvrier (facultatif)';

  @override
  String get memberNone => 'Aucune';

  @override
  String get memberInactive => 'Inactif';

  @override
  String get groupName => 'Nom de la branche';

  @override
  String get groupsEmpty => 'Aucune branche';

  @override
  String get adminSettings => 'Réglages';

  @override
  String get settingsIntro =>
      'Laissez vide pour garder la valeur du dossier d\'élevage.';

  @override
  String get settingMin => 'min';

  @override
  String get settingMax => 'max';

  @override
  String settingDefault(String value) {
    return 'Dossier : $value';
  }

  @override
  String get settingsSaved => 'Réglages enregistrés';

  @override
  String get cfgFryMaxG => 'Fin de l\'alevinage (g)';

  @override
  String get cfgPregrowMaxG => 'Fin du prégrossissement (g)';

  @override
  String get cfgGrowoutMaxG => 'Fin du grossissement (g)';

  @override
  String get cfgRationRateFry => 'Ration en alevinage (part de la biomasse)';

  @override
  String get cfgRationRatePregrow =>
      'Ration en prégrossissement (part de la biomasse)';

  @override
  String get cfgRationRateGrowout =>
      'Ration en grossissement (part de la biomasse)';

  @override
  String get cfgRationRateFinishing =>
      'Ration en finition (part de la biomasse)';

  @override
  String get cfgMaxRationRate => 'Ration maximale (part de la biomasse)';

  @override
  String get cfgLeftoverReduction => 'Baisse après des restes (part)';

  @override
  String get cfgAteFastIncrease => 'Hausse si tout est mangé vite (part)';

  @override
  String get cfgDensityPerM2Earth => 'Densité en étang de terre (poissons/m²)';

  @override
  String get cfgDensityPerM2Tank => 'Densité en bassin (poissons/m²)';

  @override
  String get cfgDensityPerM2Cage => 'Densité en cage (poissons/m²)';

  @override
  String get cfgTemperatureC => 'Température (°C)';

  @override
  String get cfgPh => 'pH';

  @override
  String get cfgMinOxygenMgL => 'Oxygène minimum (mg/L)';

  @override
  String get cfgWaterRenewalPctPerWeek =>
      'Renouvellement de l\'eau (% par semaine)';

  @override
  String get cfgSampleIntervalDays => 'Jours entre deux échantillonnages';

  @override
  String get cfgSampleMinFish => 'Poissons pesés, au moins';

  @override
  String get cfgSampleMaxFish => 'Poissons pesés, au plus';

  @override
  String get cfgWaterCheckIntervalDays => 'Jours entre deux relevés d\'eau';

  @override
  String get cfgFcrTarget => 'IC visé';

  @override
  String get cfgFeedAgeWarnDays => 'Aliment vieux : alerte (jours)';

  @override
  String get cfgFeedAgeDangerDays => 'Aliment trop vieux (jours)';

  @override
  String get cfgLowStockDays => 'Stock bas (jours restants)';

  @override
  String get cfgMortalitySpikeShare => 'Pic de mortalité : part des poissons';

  @override
  String get cfgMortalitySpikeMultiplier =>
      'Pic de mortalité : fois la moyenne';

  @override
  String get cfgMortalitySpikeMinDeaths => 'Pic de mortalité : morts au moins';

  @override
  String get cfgMortalityTrailingDays => 'Pic de mortalité : jours de moyenne';

  @override
  String get cfgWarningSignLookbackDays => 'Signes d\'alerte récents (jours)';

  @override
  String get cfgMortalityLookbackDays => 'Pic de mortalité affiché (jours)';

  @override
  String get cfgStopFeedingSignDays =>
      'Ne pas nourrir après des signes de stress (jours)';

  @override
  String get cfgQuarantineDays => 'Quarantaine (jours)';

  @override
  String get cfgDryingDays => 'Assèchement (jours)';

  @override
  String get cfgRestDays => 'Repos après remplissage (jours)';

  @override
  String get cfgPreHarvestFastHours => 'Jeûne avant la récolte (heures)';

  @override
  String get cfgHarvestHour => 'Heure de début de la récolte';

  @override
  String get cfgLimeKgPerM2 => 'Chaux (kg/m²)';

  @override
  String get cfgManureKgPerM2 => 'Fumier (kg/m²)';

  @override
  String get cfgPondSurfaceM2 => 'Surface d\'un étang (m²)';

  @override
  String get cfgPondLengthWidthRatio => 'Rapport longueur / largeur';

  @override
  String get cfgMinDepthM => 'Profondeur minimale (m)';

  @override
  String get cfgStockingWeightG => 'Poids à l\'empoissonnement (g)';

  @override
  String get cfgAcclimatisationMinutes => 'Acclimatation (minutes)';

  @override
  String get cfgSectionPhases => 'Phases';

  @override
  String get cfgSectionFeeding => 'Alimentation';

  @override
  String get cfgSectionPonds => 'Étangs';

  @override
  String get cfgSectionWaterQuality => 'Qualité de l\'eau';

  @override
  String get cfgSectionSampling => 'Échantillonnage';

  @override
  String get cfgSectionAlertRules => 'Alertes';

  @override
  String get cfgSectionFormulas => 'Calculs';

  @override
  String get cfgSectionFeedStock => 'Stock d\'aliment';

  @override
  String get cfgSectionSpeciesAndFingerlings => 'Alevins';

  @override
  String get cfgSectionPondPreparation => 'Préparation des étangs';

  @override
  String get cfgSectionHarvestAndDelivery => 'Récolte';

  @override
  String get takeoverTitle => 'Reprendre ce téléphone';

  @override
  String get takeoverHint =>
      'Réservé à un administrateur. L\'ouvrier sera déconnecté ; tout ce qu\'il a enregistré reste sur le téléphone.';

  @override
  String takeoverUnsent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enregistrements de l\'ouvrier ne sont pas encore envoyés',
      one: '1 enregistrement de l\'ouvrier n\'est pas encore envoyé',
    );
    return '$_temp0. Connectez le téléphone au réseau puis réessayez.';
  }

  @override
  String get errorNotAdmin => 'Ce compte n\'est pas administrateur.';

  @override
  String get tabAlerts => 'Alertes';

  @override
  String get alertsEmpty => 'Aucune alerte, rien à faire';

  @override
  String get alertsAll => 'Tous';

  @override
  String alertWaterLow(String param, String value) {
    return '$param trop bas : $value';
  }

  @override
  String alertWaterHigh(String param, String value) {
    return '$param trop haut : $value';
  }

  @override
  String get alertWaterColour =>
      'Eau trop verte ou trouble : renouveler l\'eau';

  @override
  String alertFcrWorsening(String batch) {
    return 'Lot $batch : IC en hausse deux fois de suite';
  }

  @override
  String alertGrowthStalled(String batch) {
    return 'Lot $batch : pas de croissance depuis le dernier échantillonnage';
  }

  @override
  String alertMortalitySpike(String deaths, String date) {
    return '$deaths morts le $date';
  }

  @override
  String alertWarningSignSeen(String signs) {
    return 'Signes d\'alerte : $signs';
  }

  @override
  String alertPhaseChange(String batch, String phase) {
    return 'Lot $batch : passe en $phase, changer d\'aliment et de nombre de repas';
  }

  @override
  String alertSampleDue(String batch, String days) {
    return 'Lot $batch : échantillonnage à faire ($days jours)';
  }

  @override
  String get alertWaterCheckDue => 'Relevé d\'eau à faire';

  @override
  String alertQuarantineEnding(String batch, String days, String recommended) {
    return 'Lot $batch : $days jours de quarantaine, transfert conseillé avant le jour $recommended';
  }

  @override
  String alertPreHarvestFast(String batch) {
    return 'Lot $batch : jeûne avant la récolte, ne pas nourrir';
  }

  @override
  String alertPreHarvestFed(String batch) {
    return 'Lot $batch : jeûne avant la récolte, mais de l\'aliment a été donné';
  }

  @override
  String alertFeedStockLow(String days) {
    return 'Stock d\'aliment : $days jours restants';
  }

  @override
  String get alertFeedTooOld => 'Un lot d\'aliment est trop vieux';

  @override
  String get alertPrepStepDue => 'Préparation : l\'étape suivante est possible';

  @override
  String alertDuplicateLog(String date) {
    return 'Deux journaux pour le $date : choisir lequel garder';
  }

  @override
  String get duplicateKeep => 'Garder celui-ci';

  @override
  String get duplicateResolved => 'Résolu : un seul journal pour ce jour';

  @override
  String duplicateEnteredBy(String name) {
    return 'Saisi par $name';
  }

  @override
  String duplicateObservedBy(String name) {
    return 'Vu par $name';
  }

  @override
  String get duplicateOtherPhone => 'un autre téléphone';

  @override
  String get staleRecord =>
      'Ce journal a déjà été changé sur un autre téléphone';

  @override
  String get rationToday => 'Ration du jour';

  @override
  String lastWeighed(String days) {
    return 'Dernière pesée : il y a $days j';
  }

  @override
  String notSampledYet(String days) {
    return 'Pas encore échantillonné, empoissonné il y a $days j';
  }

  @override
  String fcrValue(String value) {
    return 'IC : $value';
  }

  @override
  String survivalValue(String pct) {
    return 'Survie : $pct %';
  }

  @override
  String get chartWeight => 'Poids moyen (g)';

  @override
  String get chartDeaths => 'Morts par jour';

  @override
  String get chartFcr => 'IC par période';

  @override
  String get chartEmpty => 'Pas encore de données';

  @override
  String get fcrStalled => 'pas de croissance';

  @override
  String get workerStopFeeding => 'Ne pas nourrir';

  @override
  String get workerReasonFast => 'Récolte bientôt';

  @override
  String get workerReasonOxygen => 'Manque d\'oxygène';

  @override
  String get workerReasonDistress => 'Poissons stressés';

  @override
  String labelValue(String label, String value) {
    return '$label : $value';
  }

  @override
  String labelColon(String label) {
    return '$label :';
  }

  @override
  String get tabReports => 'Rapports';

  @override
  String get reportTitle => 'Rapport de visite';

  @override
  String get reportsEmpty => 'Aucun rapport pour l\'instant';

  @override
  String get reportDraft => 'Brouillon — à publier';

  @override
  String get reportPublish => 'Publier';

  @override
  String get reportShare => 'Partager';

  @override
  String reportCardTitle(String date, String member) {
    return '$date · $member';
  }

  @override
  String reportPeriod(String from, String to) {
    return 'Du $from au $to';
  }

  @override
  String reportAuthor(String member) {
    return 'Par $member';
  }

  @override
  String reportAuthorGroup(String member, String group) {
    return 'Par $member ($group)';
  }

  @override
  String reportPublishedOn(String date) {
    return 'Publié le $date';
  }

  @override
  String get reportUpdateApp =>
      'Mettez l\'application à jour pour lire ce rapport.';

  @override
  String get reportSummary => 'Résumé';

  @override
  String get reportAlerts => 'Alertes';

  @override
  String get reportHealth => 'Santé';

  @override
  String get reportWater => 'Eau';

  @override
  String get reportGrowth => 'Croissance';

  @override
  String get reportFeed => 'Aliment';

  @override
  String get reportNext => 'À venir';

  @override
  String get reportObservations => 'Observations et photos';

  @override
  String get reportNothing => 'Rien à signaler';

  @override
  String get reportNoSummary => 'Pas de résumé';

  @override
  String get reportNoReading => 'Aucun relevé';

  @override
  String get reportNoFish => 'Aucun poisson en étang';

  @override
  String get reportNoFeed => 'Aucun aliment noté sur la période';

  @override
  String get reportFeedStockLater =>
      'Stock d\'aliment : à partir de la gestion des stocks';

  @override
  String reportDeaths(String count) {
    return '$count morts';
  }

  @override
  String reportObserverDeaths(String name, String count) {
    return '$name $count';
  }

  @override
  String get reportListSeparator => ' · ';

  @override
  String get reportUnknownPerson => 'inconnu';

  @override
  String reportSigns(String date, String signs) {
    return '$date : $signs';
  }

  @override
  String reportTreatmentLine(String date, String product, String dose) {
    return '$date : $product, $dose';
  }

  @override
  String reportHealthEventLine(String date, String details) {
    return '$date : $details';
  }

  @override
  String reportReadingOn(String date) {
    return 'Relevé du $date';
  }

  @override
  String reportGrowthLine(String batch, String weight, String date) {
    return '$batch · $weight (pesé le $date)';
  }

  @override
  String get reportBiomass => 'Biomasse';

  @override
  String get reportFish => 'Poissons';

  @override
  String get reportFcrShared => 'bassin partagé';

  @override
  String get reportFcrNoSample => 'pas encore pesé';

  @override
  String get reportTrendWorse => 'en hausse';

  @override
  String get reportTrendBetter => 'en baisse';

  @override
  String get reportTrendSame => 'stable';

  @override
  String get reportFeedTotal => 'Total';

  @override
  String reportNextSample(String batch) {
    return 'Pesée de $batch';
  }

  @override
  String reportNextHarvest(String batch) {
    return 'Récolte de $batch';
  }

  @override
  String reportNextQuarantine(String batch) {
    return 'Fin de quarantaine de $batch';
  }

  @override
  String reportAllOk(String items) {
    return 'En ordre : $items';
  }

  @override
  String get photoAdd => 'Ajouter une photo';

  @override
  String get photoUpload => 'Envoyer au serveur';

  @override
  String get photoDelete => 'Supprimer la photo';

  @override
  String get photoFailed =>
      'La photo n\'a pas pu être prise. L\'enregistrement se fait sans elle.';

  @override
  String get photoUnavailable => 'Photo pas encore disponible';

  @override
  String syncPhotosWaiting(int count) {
    return 'Photos en attente d\'envoi : $count';
  }

  @override
  String get syncPhotoCap =>
      'Limite de photos atteinte : un administrateur peut la relever dans Réglages.';

  @override
  String get settingsPhotos => 'Photos';

  @override
  String get settingPhotoUploadCap => 'Photos envoyées au serveur, au plus';
}
