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
  String get batchesEmpty =>
      'Aucun lot. Empoissonnez un étang depuis sa page ou ci-dessous.';

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
  String get startVisit => 'Commencer la visite';

  @override
  String get sectionBiosecurity => 'Biosécurité';

  @override
  String get sectionObservations => 'Observations';

  @override
  String get endVisit => 'Terminer la visite';

  @override
  String get endVisitConfirm =>
      'Terminer la visite ? Le rapport sera préparé à partir de ce qui a été saisi.';

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
  String get conditionsAllOk => 'Tout est en ordre';

  @override
  String get observationPond => 'Étang (facultatif)';

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
  String conditionsOf(String pond) {
    return 'État de $pond';
  }

  @override
  String get welcomeTitle => 'Bienvenue';

  @override
  String get welcomeMember => 'Se connecter (membre)';

  @override
  String get welcomeWorker => 'Je suis ouvrier';

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
  String get resetPassword => 'Nouveau mot de passe';

  @override
  String get resetPin => 'Nouveau code PIN';

  @override
  String get resetHint =>
      'Donnez-le à la personne en main propre. Ses téléphones déjà connectés le restent.';

  @override
  String get resetConfirm => 'Changer';

  @override
  String get resetPasswordDone => 'Mot de passe changé';

  @override
  String get resetPinDone => 'Code PIN changé';

  @override
  String get consoleTitle => 'Dobo — console';

  @override
  String get consoleNavAssociation => 'Association';

  @override
  String get consoleNavGroups => 'Groupes';

  @override
  String get consoleNavMembers => 'Membres';

  @override
  String get consoleNavPeople => 'Personnes';

  @override
  String get consoleSignOut => 'Se déconnecter';

  @override
  String get consoleAdminsOnly =>
      'La console est réservée aux administrateurs.';

  @override
  String get consoleIdleNotice => 'Déconnecté après 30 minutes sans activité.';

  @override
  String get consoleSignInTitle => 'Connexion à la console';

  @override
  String get consoleFoundLink => 'Fonder une association';

  @override
  String get consoleFoundTitle => 'Fonder l\'association';

  @override
  String get consoleFoundIntro =>
      'Une seule fois, par la personne qui sera le premier administrateur. Le code de fondation vous a été donné avec l\'adresse de la console.';

  @override
  String get consoleFoundCode => 'Code de fondation';

  @override
  String get consoleFoundAssociation => 'Nom de l\'association';

  @override
  String get consoleFoundGroup => 'Nom de votre branche';

  @override
  String get consoleFoundName => 'Votre nom';

  @override
  String get consoleFoundPasswordAgain => 'Mot de passe, encore une fois';

  @override
  String get consolePasswordsDiffer => 'Les deux mots de passe diffèrent';

  @override
  String get consoleFoundSubmit => 'Fonder';

  @override
  String get consoleBadCode => 'Code de fondation faux ou déjà utilisé';

  @override
  String get consoleRename => 'Renommer';

  @override
  String get consoleEdit => 'Modifier';

  @override
  String get consoleNewGroup => 'Nouveau groupe';

  @override
  String get consoleNewPerson => 'Nouvelle personne';

  @override
  String get consoleNothingYet => 'Rien pour l\'instant';

  @override
  String get consoleLogin => 'Identifiant';

  @override
  String get consoleAgain => 'Encore une fois';

  @override
  String get consoleSecretsDiffer => 'Les deux saisies diffèrent';

  @override
  String get consoleDeactivate => 'Désactiver';

  @override
  String get consoleReactivate => 'Réactiver';

  @override
  String consoleDeactivateAsk(String name) {
    return 'Désactiver le compte de $name ? Il ne pourra plus se connecter ; ses relevés restent.';
  }

  @override
  String consoleReactivateAsk(String name) {
    return 'Réactiver le compte de $name ?';
  }

  @override
  String consoleRefused(String code) {
    return 'Le serveur a refusé : $code';
  }

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
  String get cfgFeedUsageDays => 'Consommation moyenne sur (jours)';

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
  String get alertFeedOld =>
      'Un lot d\'aliment vieillit : l\'utiliser en priorité';

  @override
  String get alertFeedExpired =>
      'Un lot d\'aliment est trop vieux : ne pas l\'utiliser';

  @override
  String get moreFeed => 'Aliment';

  @override
  String get harvestAction => 'Récolter';

  @override
  String harvestHasSales(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Supprimez d\'abord ses $count ventes.',
      one: 'Supprimez d\'abord sa vente.',
    );
    return '$_temp0';
  }

  @override
  String harvestEditTitle(String batch) {
    return 'Corriger la récolte $batch';
  }

  @override
  String get sellAction => 'Vendre';

  @override
  String harvestTitle(String batch) {
    return 'Récolte $batch';
  }

  @override
  String get harvestPond => 'Étang';

  @override
  String get harvestDate => 'Date de récolte';

  @override
  String get harvestCount => 'Nombre de poissons';

  @override
  String get harvestWeight => 'Poids total';

  @override
  String get harvestPartial => 'Partielle';

  @override
  String get harvestFinal => 'Finale (l\'étang est vidé)';

  @override
  String harvestMissing(String count) {
    return '$count poissons non retrouvés (prédateurs, vol ou erreur de comptage)';
  }

  @override
  String get harvestNoPond =>
      'Aucun étang de ce lot ne peut être récolté : il est vide ou isolé';

  @override
  String get harvestsHeading => 'Récoltes et ventes';

  @override
  String get harvestKindPartial => 'Récolte partielle';

  @override
  String get harvestKindFinal => 'Récolte finale';

  @override
  String harvestLine(
    String date,
    String kind,
    String pond,
    String count,
    String kg,
  ) {
    return '$date · $kind $pond : $count poissons · $kg';
  }

  @override
  String saleLine(String customer, String form, String kg) {
    return '$customer · $form · $kg';
  }

  @override
  String saleTitle(String batch) {
    return 'Vente $batch';
  }

  @override
  String get saleHarvest => 'Récolte';

  @override
  String get saleCustomer => 'Client';

  @override
  String get saleWeight => 'Poids vendu';

  @override
  String get saleForm => 'Forme';

  @override
  String get saleDate => 'Date de vente';

  @override
  String get saleNote => 'Bon de livraison (facultatif)';

  @override
  String saleOverHarvest(String kg) {
    return 'Plus que le poids récolté pas encore vendu ($kg)';
  }

  @override
  String get formLive => 'Vivant';

  @override
  String get formFresh => 'Frais';

  @override
  String get formFrozen => 'Congelé';

  @override
  String get formSmoked => 'Fumé';

  @override
  String get formDried => 'Séché';

  @override
  String get moreSales => 'Ventes';

  @override
  String get traceTitle => 'Fiche de traçabilité';

  @override
  String traceBatch(String code) {
    return 'Lot $code';
  }

  @override
  String get traceIdentity => 'Identité';

  @override
  String get tracePonds => 'Étangs';

  @override
  String get traceTreatments => 'Traitements';

  @override
  String get traceHarvests => 'Récoltes';

  @override
  String get traceSales => 'Ventes';

  @override
  String get traceResults => 'Bilan';

  @override
  String get traceCycleFcr => 'IC du cycle';

  @override
  String get traceCycleOngoing => 'cycle en cours';

  @override
  String get traceSurvival => 'Survie';

  @override
  String get traceUnaccounted => 'Poissons non retrouvés';

  @override
  String get traceFeed => 'Aliment donné';

  @override
  String get traceStocked => 'Mis en étang';

  @override
  String get traceHarvested => 'Récolté';

  @override
  String get traceLive => 'Encore en étang';

  @override
  String traceAdvisedBy(String who) {
    return 'conseillé par $who';
  }

  @override
  String get salesTitle => 'Récoltes et ventes';

  @override
  String get salesNone => 'Aucune récolte enregistrée';

  @override
  String get customersTitle => 'Clients';

  @override
  String get customerNew => 'Nouveau client';

  @override
  String get customerEdit => 'Client';

  @override
  String get customerName => 'Nom';

  @override
  String get customerType => 'Type';

  @override
  String get customerContact => 'Contact (facultatif)';

  @override
  String get customerArchive => 'Retirer de la liste';

  @override
  String get customersNone => 'Aucun client';

  @override
  String get custMarket => 'Marché';

  @override
  String get custRestaurant => 'Restaurant';

  @override
  String get custSupermarket => 'Supermarché';

  @override
  String get custExporter => 'Exportateur';

  @override
  String get custIndividual => 'Particulier';

  @override
  String get feedTitle => 'Stock d\'aliment';

  @override
  String get feedOnHand => 'En stock';

  @override
  String get feedNoUsage => 'Pas de consommation ces derniers jours';

  @override
  String feedOverdrawn(String kg) {
    return 'Plus d\'aliment donné que livré : $kg';
  }

  @override
  String get feedNoLots => 'Aucun aliment en stock. Enregistrez une livraison.';

  @override
  String get feedLotOld => 'À utiliser en priorité';

  @override
  String get feedLotExpired => 'À ne pas utiliser';

  @override
  String get feedDeliver => 'Livraison';

  @override
  String get feedDeliveryTitle => 'Livraison d\'aliment';

  @override
  String get feedPhase => 'Aliment pour';

  @override
  String get feedWeight => 'Poids livré';

  @override
  String get feedMadeOn => 'Date de fabrication';

  @override
  String get feedDeliveredOn => 'Date de livraison';

  @override
  String get feedPellet => 'Taille du granulé';

  @override
  String get feedProtein => 'Protéines';

  @override
  String get feedSupplier => 'Fournisseur';

  @override
  String get feedLabel => 'Marque sur les sacs';

  @override
  String get feedDiscardTitle => 'Aliment jeté';

  @override
  String get feedDiscardWeight => 'Poids jeté';

  @override
  String get feedDiscardReason => 'Pourquoi';

  @override
  String get discardMould => 'Moisi';

  @override
  String get discardRancid => 'Rance';

  @override
  String get discardClumped => 'En grumeaux';

  @override
  String get discardOther => 'Autre';

  @override
  String get feedLot => 'Lot d\'aliment';

  @override
  String get feedLotAuto => 'Le plus ancien (automatique)';

  @override
  String get alertPrepDry =>
      'Séchage fini ? Vérifier les fissures, puis noter l\'assèchement';

  @override
  String get alertPrepRest => 'Repos fini : l\'étang peut être déclaré prêt';

  @override
  String get prepButton => 'Préparation';

  @override
  String prepTitle(String pond) {
    return 'Préparation $pond';
  }

  @override
  String get prepStepDrain => 'Vidange et curage';

  @override
  String get prepStepDry => 'Assèchement au soleil';

  @override
  String get prepStepTreat => 'Traitement (chaux vive ou chlore)';

  @override
  String get prepStepFertilise => 'Fertilisation (fumier)';

  @override
  String get prepStepFill => 'Remplissage par l\'entrée grillagée';

  @override
  String get prepStepRest => 'Repos';

  @override
  String get prepDone => 'Fait';

  @override
  String prepDoneOn(String date) {
    return 'Fait le $date';
  }

  @override
  String prepDryUntil(String from, String to) {
    return 'Séchage : du $from au $to';
  }

  @override
  String prepRestUntil(String date) {
    return 'Repos jusqu\'au $date';
  }

  @override
  String prepLimeDose(String range, String surface) {
    return 'Chaux vive : $range pour $surface';
  }

  @override
  String prepManureDose(String range, String surface) {
    return 'Fumier : $range pour $surface';
  }

  @override
  String get prepNoSurface =>
      'Sans la surface de l\'étang, pas de dose : renseignez sa longueur et sa largeur';

  @override
  String get prepMarkReady => 'Prêt à empoissonner';

  @override
  String prepSkipped(String steps) {
    return 'Étapes non faites : $steps';
  }

  @override
  String prepRestShort(String date) {
    return 'Le repos n\'est pas fini (jusqu\'au $date)';
  }

  @override
  String get prepReadyConfirm => 'Déclarer l\'étang prêt à empoissonner ?';

  @override
  String get prepProductQuicklime => 'Chaux vive';

  @override
  String get prepProductChlorine => 'Chlore';

  @override
  String get prepProductManure => 'Fumier';

  @override
  String get prepDoseUsed => 'Dose utilisée';

  @override
  String get doneDate => 'Date';

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
  String get reportsEmpty =>
      'Aucun rapport. Le rapport se prépare à la fin d\'une visite.';

  @override
  String get reportPublish => 'Publier';

  @override
  String get reportShare => 'Partager';

  @override
  String reportCardTitle(String date, String member) {
    return '$date, $member';
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
      'Stock d\'aliment : non suivi (aucune livraison enregistrée)';

  @override
  String reportFeedOnHand(String kg, String days) {
    return 'En stock : $kg, $days jours de stock';
  }

  @override
  String reportFeedOnHandNoUsage(String kg) {
    return 'En stock : $kg';
  }

  @override
  String reportFeedLot(String lot, String kg, String date) {
    return '$lot · $kg · fabriqué le $date';
  }

  @override
  String reportNextDry(String pond) {
    return 'Séchage de $pond fini ?';
  }

  @override
  String reportNextRest(String pond) {
    return 'Repos de $pond fini : prêt à empoissonner';
  }

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
  String reportGrowthLine(String batch, String weight, String date) {
    return '$batch $weight ($date)';
  }

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

  @override
  String get photoDeleteConfirm =>
      'Supprimer cette photo ? Elle sera effacée de ce téléphone.';

  @override
  String get paperTitle => 'Fiche journalière';

  @override
  String paperWeek(String from, String to) {
    return 'Semaine du $from au $to';
  }

  @override
  String get paperWorker => 'Ouvrier';

  @override
  String get paperFeedKg => 'Aliment (kg)';

  @override
  String get paperDay => 'Jour';

  @override
  String get paperHowTo => 'Cochez la case de ce que vous voyez.';

  @override
  String get paperNoPonds => 'Aucun étang actif.';

  @override
  String get weekdayMon => 'lun.';

  @override
  String get weekdayTue => 'mar.';

  @override
  String get weekdayWed => 'mer.';

  @override
  String get weekdayThu => 'jeu.';

  @override
  String get weekdayFri => 'ven.';

  @override
  String get weekdaySat => 'sam.';

  @override
  String get weekdaySun => 'dim.';

  @override
  String get morePaper => 'Fiches papier';

  @override
  String get paperWeeksLabel => 'Nombre de semaines';

  @override
  String get paperPondsLabel => 'Étangs';

  @override
  String get paperPrint => 'Imprimer';

  @override
  String get paperShare => 'Partager le PDF';

  @override
  String get transcriptionCellDetails => 'Détails du jour';

  @override
  String get exportRegisterTitle => 'Registre de production';

  @override
  String get exportWeeklyTitle => 'Fiche de suivi hebdomadaire';

  @override
  String exportPeriod(String from, String to) {
    return 'Du $from au $to';
  }

  @override
  String get exportColDate => 'Date';

  @override
  String get exportColPondBatch => 'Étang / Lot';

  @override
  String get exportColOrigin => 'Provenance alevins';

  @override
  String get exportColFeedKg => 'Quantité aliment (kg)';

  @override
  String get exportColDeaths => 'Mortalité (nb)';

  @override
  String get exportColSalesKg => 'Ventes (kg)';

  @override
  String get exportColObservations => 'Observations';

  @override
  String get exportColPond => 'Étang';

  @override
  String get exportColWeekOf => 'Semaine du';

  @override
  String get exportColTemp => 'Temp. (°C)';

  @override
  String get exportColPh => 'pH';

  @override
  String get exportColOxygen => 'Oxygène (mg/L)';

  @override
  String get exportColFeedGivenKg => 'Aliment distribué (kg)';

  @override
  String get exportColAvgWeight => 'Poids moyen échantillon (g)';

  @override
  String exportFishCount(String count) {
    return '$count poissons';
  }

  @override
  String get exportTreatment => 'Traitement';

  @override
  String get exportHealth => 'Problème signalé';

  @override
  String exportThresholds(
    String temp,
    String ph,
    String oxygen,
    String renewal,
  ) {
    return 'Seuils : température $temp °C · pH $ph · oxygène ≥ $oxygen mg/L · renouvellement d\'eau $renewal % par semaine si l\'eau devient trouble.';
  }

  @override
  String get moreExports => 'Exports';

  @override
  String get exportKindRegister => 'Registre de production (annexe A)';

  @override
  String get exportKindWeekly => 'Suivi hebdomadaire (annexe B)';

  @override
  String get exportFrom => 'Du';

  @override
  String get exportTo => 'Au';

  @override
  String get exportPond => 'Étang';

  @override
  String get exportAllPonds => 'Tous les étangs';

  @override
  String get exportPdf => 'PDF';

  @override
  String get exportCsv => 'CSV';

  @override
  String get exportEndBeforeStart =>
      'La date de fin est avant la date de début.';

  @override
  String get exportWeeklyWholeWeeks =>
      'Semaines entières, du lundi au dimanche.';

  @override
  String get close => 'Fermer';

  @override
  String get exportBuilding => 'Préparation du fichier…';

  @override
  String get pondsRationTotal => 'Ration du jour, tous les étangs';

  @override
  String pondsDangerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étangs en danger',
      one: '1 étang en danger',
      zero: 'Aucun étang en danger',
    );
    return '$_temp0';
  }

  @override
  String bandMore(String lead, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count autres',
      one: '1 autre',
    );
    return '$lead, et $_temp0';
  }

  @override
  String get pondLogDone => 'Journal fait';

  @override
  String get pondLogNotYet => 'Pas encore de journal';

  @override
  String pondPrepNext(String status, String step) {
    return '$status : $step';
  }

  @override
  String pondFishCount(String count) {
    return '$count poissons';
  }

  @override
  String get pondPrepare => 'Préparer l\'étang';

  @override
  String get weighAction => 'Peser';

  @override
  String feedGivenToday(String amount) {
    return 'Donné : $amount';
  }

  @override
  String growthSummary(String weight, String delta, int days) {
    return '$weight, $delta en $days j';
  }

  @override
  String deathsSummary(int count, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count morts',
      one: '1 mort',
      zero: 'Aucun mort',
    );
    return '$_temp0 en $days j';
  }

  @override
  String healthSummary(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count événements',
      one: '1 événement',
    );
    return '$_temp0, dernier le $date';
  }

  @override
  String get pondFacts => 'Étang';

  @override
  String get moreActions => 'Plus d\'actions';

  @override
  String workerProgress(int done, int total) {
    return '$done / $total faits';
  }

  @override
  String get workerAllDone => 'Tous les étangs sont faits';

  @override
  String get workerNoPonds => 'Aucun étang avec des poissons';

  @override
  String get pickDone => 'Terminé';

  @override
  String get feedingsButton => 'Repas';

  @override
  String get deathAppearanceButton => 'Aspect';

  @override
  String get alertsDanger => 'Danger';

  @override
  String get alertsTodo => 'À faire';

  @override
  String get visitTodayHeading => 'À faire aujourd\'hui';

  @override
  String visitWaterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count relevés d\'eau',
      one: '1 relevé d\'eau',
    );
    return '$_temp0';
  }

  @override
  String visitSampleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count échantillonnages',
      one: '1 échantillonnage',
    );
    return '$_temp0';
  }

  @override
  String visitInspectCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étangs à inspecter',
      one: '1 étang à inspecter',
    );
    return '$_temp0';
  }

  @override
  String visitLast(String date, String member) {
    return 'Dernière visite : $date, $member';
  }

  @override
  String visitProgress(int done, int total) {
    return '$done / $total';
  }

  @override
  String get visitInspection => 'État de l\'étang';

  @override
  String get visitAllInOrder => 'tout en ordre';

  @override
  String visitProblems(int count, String list) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problèmes : $list',
      one: '1 problème : $list',
    );
    return '$_temp0';
  }

  @override
  String visitSampleDone(String batch, String avg, int count) {
    return '$batch : $avg ($count poissons)';
  }

  @override
  String bioReminders(int count) {
    return '$count rappels';
  }

  @override
  String endVisitLeft(int count, String items) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contrôles pas faits : $items.',
      one: '1 contrôle pas fait : $items.',
    );
    return '$_temp0 Terminer quand même ?';
  }

  @override
  String leftWater(String pond) {
    return 'relevé $pond';
  }

  @override
  String leftSample(String batch) {
    return 'échantillon $batch';
  }

  @override
  String leftInspection(String pond) {
    return 'état $pond';
  }

  @override
  String get reportAlertsNone => 'Aucune alerte';

  @override
  String get reportHealthNone => 'Aucun mort, aucun signe';

  @override
  String get reportNextNone => 'Rien de prévu';

  @override
  String get reportObservationsNone => 'Aucune observation';

  @override
  String reportInOrder(String ponds) {
    return 'Tout en ordre : $ponds';
  }

  @override
  String reportHeaderTitle(String site, String date) {
    return '$site, $date';
  }

  @override
  String get reportDraftNote =>
      'Brouillon : visible par vous seul jusqu\'à la publication';

  @override
  String get reportSummaryHint => 'Ce que vous avez vu, en quelques mots';

  @override
  String reportDeathsBy(String deaths, String observers) {
    return '$deaths ($observers)';
  }

  @override
  String reportDraftRow(String date) {
    return 'À publier : $date';
  }

  @override
  String reportDangerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count en danger',
      one: '1 en danger',
    );
    return '$_temp0';
  }

  @override
  String get detailsFold => 'Plus de détails';

  @override
  String get doneDeleted => 'Supprimé';

  @override
  String get actionSaveCorrection => 'Enregistrer la correction';

  @override
  String get actionSaveBatch => 'Enregistrer le lot';

  @override
  String get actionSaveDelivery => 'Enregistrer la livraison';

  @override
  String get actionDiscard => 'Jeter';

  @override
  String get doneStocked => 'Empoissonné';

  @override
  String get doneTransferred => 'Transféré';

  @override
  String get doneDelivered => 'Livraison enregistrée';

  @override
  String get doneDiscarded => 'Jeté';

  @override
  String get doneCorrected => 'Correction enregistrée';

  @override
  String get doneSaved => 'Enregistré';

  @override
  String get transferFrom => 'De';

  @override
  String get feedDiscardPart => 'Jeter une partie';

  @override
  String feedLotLine(String label, String date, String days) {
    return '$label fait le $date, $days j';
  }

  @override
  String get feedLotUnnamed => 'Lot';

  @override
  String deleteStockingConfirm(String date, String count, String pond) {
    return 'Supprimer l\'empoissonnement du $date ($count poissons, $pond) ? Le lot perd ces poissons.';
  }

  @override
  String deleteTransferConfirm(
    String date,
    String count,
    String from,
    String to,
  ) {
    return 'Supprimer le transfert du $date ($count poissons, $from → $to) ? Les poissons comptent de nouveau dans $from.';
  }

  @override
  String deleteDeliveryConfirm(String date, String kg) {
    return 'Supprimer la livraison du $date ($kg) ? Le stock baisse de $kg.';
  }

  @override
  String harvestAim(String count, String pond) {
    return '$count poissons dans $pond';
  }

  @override
  String get customerPickTitle => 'Client';

  @override
  String get doneHarvested => 'Récolté';

  @override
  String get doneSold => 'Vendu';

  @override
  String get actionAddCustomer => 'Ajouter le client';

  @override
  String get actionSaveCustomer => 'Enregistrer le client';

  @override
  String saleHarvestLeft(String date, String kind, String kg) {
    return '$date, $kind, reste $kg';
  }

  @override
  String saleHarvestChoice(String date, String pond, String kg) {
    return '$date $pond, reste $kg';
  }

  @override
  String deleteHarvestConfirm(String date, String kg, String pond) {
    return 'Supprimer la récolte du $date ($kg, $pond) ? Les poissons comptent de nouveau dans $pond.';
  }

  @override
  String deleteSaleConfirm(String date, String kg, String customer) {
    return 'Supprimer la vente du $date ($kg, $customer) ? Ces kilos restent à vendre.';
  }

  @override
  String get actionSaveReading => 'Enregistrer le relevé';

  @override
  String get actionSaveSample => 'Enregistrer la pesée';

  @override
  String get actionSaveTreatment => 'Enregistrer le traitement';

  @override
  String get actionReport => 'Signaler';

  @override
  String get actionSavePond => 'Enregistrer l\'étang';

  @override
  String get actionAddPerson => 'Ajouter la personne';

  @override
  String deleteReadingConfirm(String date) {
    return 'Supprimer le relevé d\'eau du $date ?';
  }

  @override
  String deleteSampleConfirm(String date, String batch) {
    return 'Supprimer la pesée du $date ($batch) ?';
  }

  @override
  String get moreGroupFarm => 'La ferme';

  @override
  String get moreGroupSheets => 'Fiches';

  @override
  String get moreGroupPhone => 'Ce téléphone';

  @override
  String get moreGroupAdmin => 'Association';

  @override
  String moreBatchesSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count en cours',
      one: '1 en cours',
      zero: 'Aucun en cours',
    );
    return '$_temp0';
  }

  @override
  String feedDaysLeftShort(String days) {
    return '$days jours';
  }

  @override
  String get syncSummaryUpToDate => 'À jour';

  @override
  String syncSummaryPending(String count) {
    return '$count en attente';
  }

  @override
  String syncSummaryRejected(String count) {
    return '$count refusés';
  }

  @override
  String get syncSummaryNever => 'Jamais synchronisé';

  @override
  String get batchesClosed => 'Lots terminés';

  @override
  String batchesClosedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lots',
      one: '1 lot',
    );
    return '$_temp0';
  }

  @override
  String get batchesStockRow => 'Empoissonner un étang';

  @override
  String batchClosedOn(String date) {
    return 'Terminé le $date';
  }

  @override
  String get fishUnit => 'poissons';

  @override
  String get batchOrigin => 'Origine';

  @override
  String batchHarvestedLine(String count, String kg) {
    return 'Récolté $count poissons, $kg';
  }

  @override
  String batchCycleFcr(String value) {
    return 'IC du cycle $value';
  }

  @override
  String unsoldLine(String kg) {
    return 'Reste à vendre : $kg';
  }

  @override
  String get harvestFinalShort => 'Finale';

  @override
  String harvestRowLine(String kind, String count, String kg) {
    return '$kind, $count poissons, $kg';
  }

  @override
  String saleRowLine(String customer, String form) {
    return '$customer, $form';
  }

  @override
  String historyFish(String count) {
    return '$count poissons';
  }

  @override
  String historyFishWeight(String count, String weight) {
    return '$count poissons, $weight';
  }

  @override
  String feedExpiredBand(String kg) {
    return '$kg périmés, à jeter';
  }

  @override
  String customersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clients',
      one: '1 client',
      zero: 'Aucun',
    );
    return '$_temp0';
  }

  @override
  String transcriptionSave(String pond) {
    return 'Enregistrer la fiche $pond';
  }

  @override
  String transcriptionSavedPond(String pond) {
    return 'Fiche $pond enregistrée';
  }

  @override
  String get transcriptionLogged => 'déjà saisi';

  @override
  String transcriptionFeedMissing(String days) {
    return '$days : la quantité d\'aliment manque';
  }

  @override
  String transcriptionLeave(String ponds) {
    return 'Quitter sans enregistrer les fiches $ponds ?';
  }

  @override
  String get transcriptionStay => 'Rester';

  @override
  String get transcriptionQuit => 'Quitter';

  @override
  String paperPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String paperPondCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count étangs',
      one: '1 étang',
    );
    return '$_temp0';
  }

  @override
  String paperWeekCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semaines',
      one: '1 semaine',
    );
    return '$_temp0';
  }

  @override
  String paperPages(String pages, String ponds, String weeks) {
    return '$pages : $ponds × $weeks';
  }
}
