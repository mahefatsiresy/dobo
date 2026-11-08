import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fr.dart';
import 'app_localizations_mg.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('mg'),
  ];

  /// Application name
  ///
  /// In fr, this message translates to:
  /// **'Dobo'**
  String get appTitle;

  /// No description provided for @setupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Installation'**
  String get setupTitle;

  /// No description provided for @setupSiteName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du site'**
  String get setupSiteName;

  /// No description provided for @setupLocationNote.
  ///
  /// In fr, this message translates to:
  /// **'Lieu (facultatif)'**
  String get setupLocationNote;

  /// No description provided for @setupStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get setupStart;

  /// No description provided for @tabPonds.
  ///
  /// In fr, this message translates to:
  /// **'Étangs'**
  String get tabPonds;

  /// No description provided for @tabMore.
  ///
  /// In fr, this message translates to:
  /// **'Plus'**
  String get tabMore;

  /// No description provided for @fieldRequired.
  ///
  /// In fr, this message translates to:
  /// **'Obligatoire'**
  String get fieldRequired;

  /// No description provided for @estimated.
  ///
  /// In fr, this message translates to:
  /// **'estimé'**
  String get estimated;

  /// No description provided for @pondStatusEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Vide'**
  String get pondStatusEmpty;

  /// No description provided for @pondStatusPreparing.
  ///
  /// In fr, this message translates to:
  /// **'En préparation'**
  String get pondStatusPreparing;

  /// No description provided for @pondStatusReady.
  ///
  /// In fr, this message translates to:
  /// **'Prêt'**
  String get pondStatusReady;

  /// No description provided for @pondStatusStocked.
  ///
  /// In fr, this message translates to:
  /// **'Empoissonné'**
  String get pondStatusStocked;

  /// No description provided for @pondStatusIsolated.
  ///
  /// In fr, this message translates to:
  /// **'Isolé'**
  String get pondStatusIsolated;

  /// No description provided for @structureEarth.
  ///
  /// In fr, this message translates to:
  /// **'Étang en terre'**
  String get structureEarth;

  /// No description provided for @structureTank.
  ///
  /// In fr, this message translates to:
  /// **'Bassin'**
  String get structureTank;

  /// No description provided for @structureCage.
  ///
  /// In fr, this message translates to:
  /// **'Cage flottante'**
  String get structureCage;

  /// No description provided for @roleBreeding.
  ///
  /// In fr, this message translates to:
  /// **'Reproduction'**
  String get roleBreeding;

  /// No description provided for @roleNursery.
  ///
  /// In fr, this message translates to:
  /// **'Frayère (alevins)'**
  String get roleNursery;

  /// No description provided for @rolePregrow.
  ///
  /// In fr, this message translates to:
  /// **'Prégrossissement'**
  String get rolePregrow;

  /// No description provided for @roleGrowout.
  ///
  /// In fr, this message translates to:
  /// **'Grossissement'**
  String get roleGrowout;

  /// No description provided for @roleHolding.
  ///
  /// In fr, this message translates to:
  /// **'Stockage avant vente'**
  String get roleHolding;

  /// No description provided for @roleQuarantine.
  ///
  /// In fr, this message translates to:
  /// **'Quarantaine'**
  String get roleQuarantine;

  /// No description provided for @supplyBarrage.
  ///
  /// In fr, this message translates to:
  /// **'Barrage'**
  String get supplyBarrage;

  /// No description provided for @supplyDerivation.
  ///
  /// In fr, this message translates to:
  /// **'Dérivation'**
  String get supplyDerivation;

  /// No description provided for @supplyMarsh.
  ///
  /// In fr, this message translates to:
  /// **'Marais'**
  String get supplyMarsh;

  /// No description provided for @colourBlue.
  ///
  /// In fr, this message translates to:
  /// **'Bleu'**
  String get colourBlue;

  /// No description provided for @colourGreen.
  ///
  /// In fr, this message translates to:
  /// **'Vert'**
  String get colourGreen;

  /// No description provided for @colourYellow.
  ///
  /// In fr, this message translates to:
  /// **'Jaune'**
  String get colourYellow;

  /// No description provided for @colourOrange.
  ///
  /// In fr, this message translates to:
  /// **'Orange'**
  String get colourOrange;

  /// No description provided for @colourRed.
  ///
  /// In fr, this message translates to:
  /// **'Rouge'**
  String get colourRed;

  /// No description provided for @colourPurple.
  ///
  /// In fr, this message translates to:
  /// **'Violet'**
  String get colourPurple;

  /// No description provided for @colourBrown.
  ///
  /// In fr, this message translates to:
  /// **'Marron'**
  String get colourBrown;

  /// No description provided for @colourBlack.
  ///
  /// In fr, this message translates to:
  /// **'Noir'**
  String get colourBlack;

  /// No description provided for @batchStatusQuarantine.
  ///
  /// In fr, this message translates to:
  /// **'Quarantaine'**
  String get batchStatusQuarantine;

  /// No description provided for @batchStatusActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get batchStatusActive;

  /// No description provided for @batchStatusHarvesting.
  ///
  /// In fr, this message translates to:
  /// **'En récolte'**
  String get batchStatusHarvesting;

  /// No description provided for @batchStatusClosed.
  ///
  /// In fr, this message translates to:
  /// **'Clôturé'**
  String get batchStatusClosed;

  /// No description provided for @phaseFry.
  ///
  /// In fr, this message translates to:
  /// **'Alevinage'**
  String get phaseFry;

  /// No description provided for @phasePregrow.
  ///
  /// In fr, this message translates to:
  /// **'Prégrossissement'**
  String get phasePregrow;

  /// No description provided for @phaseGrowout.
  ///
  /// In fr, this message translates to:
  /// **'Grossissement'**
  String get phaseGrowout;

  /// No description provided for @phaseFinishing.
  ///
  /// In fr, this message translates to:
  /// **'Finition'**
  String get phaseFinishing;

  /// No description provided for @densityBelow.
  ///
  /// In fr, this message translates to:
  /// **'Densité trop faible'**
  String get densityBelow;

  /// No description provided for @densityWithin.
  ///
  /// In fr, this message translates to:
  /// **'Densité correcte'**
  String get densityWithin;

  /// No description provided for @densityAbove.
  ///
  /// In fr, this message translates to:
  /// **'Densité trop forte'**
  String get densityAbove;

  /// No description provided for @warnSurfaceTooSmall.
  ///
  /// In fr, this message translates to:
  /// **'Surface sous {min} m² (conseillé : {min} à {max} m²)'**
  String warnSurfaceTooSmall(String min, String max);

  /// No description provided for @warnSurfaceTooLarge.
  ///
  /// In fr, this message translates to:
  /// **'Surface au-dessus de {max} m² (conseillé : {min} à {max} m²)'**
  String warnSurfaceTooLarge(String min, String max);

  /// No description provided for @warnNotElongated.
  ///
  /// In fr, this message translates to:
  /// **'Étang peu allongé (conseillé : longueur = {min} à {max} fois la largeur)'**
  String warnNotElongated(String min, String max);

  /// No description provided for @warnTooElongated.
  ///
  /// In fr, this message translates to:
  /// **'Étang très allongé (conseillé : longueur = {min} à {max} fois la largeur)'**
  String warnTooElongated(String min, String max);

  /// No description provided for @warnTooShallow.
  ///
  /// In fr, this message translates to:
  /// **'Profondeur moyenne sous {min} m'**
  String warnTooShallow(String min);

  /// No description provided for @morePeople.
  ///
  /// In fr, this message translates to:
  /// **'Personnes'**
  String get morePeople;

  /// No description provided for @moreBatches.
  ///
  /// In fr, this message translates to:
  /// **'Lots'**
  String get moreBatches;

  /// No description provided for @personName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get personName;

  /// No description provided for @personPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get personPhone;

  /// No description provided for @personNote.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get personNote;

  /// No description provided for @personActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get personActive;

  /// No description provided for @personOfMember.
  ///
  /// In fr, this message translates to:
  /// **'{name} (membre)'**
  String personOfMember(String name);

  /// No description provided for @personOfWorker.
  ///
  /// In fr, this message translates to:
  /// **'{name} (ouvrier)'**
  String personOfWorker(String name);

  /// No description provided for @personRenameFromAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Renommer depuis Admin › Membres'**
  String get personRenameFromAdmin;

  /// No description provided for @personInactive.
  ///
  /// In fr, this message translates to:
  /// **'Inactif'**
  String get personInactive;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @peopleEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune personne : ajoutez les ouvriers et les membres'**
  String get peopleEmpty;

  /// No description provided for @pondAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un étang'**
  String get pondAdd;

  /// No description provided for @pondsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun étang : ajoutez le premier'**
  String get pondsEmpty;

  /// No description provided for @pondCode.
  ///
  /// In fr, this message translates to:
  /// **'Code'**
  String get pondCode;

  /// No description provided for @pondColourLabel.
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get pondColourLabel;

  /// No description provided for @pondStructure.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get pondStructure;

  /// No description provided for @pondRoleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get pondRoleLabel;

  /// No description provided for @pondWaterSupply.
  ///
  /// In fr, this message translates to:
  /// **'Alimentation en eau'**
  String get pondWaterSupply;

  /// No description provided for @notSpecified.
  ///
  /// In fr, this message translates to:
  /// **'Non précisé'**
  String get notSpecified;

  /// No description provided for @pondLength.
  ///
  /// In fr, this message translates to:
  /// **'Longueur'**
  String get pondLength;

  /// No description provided for @pondWidth.
  ///
  /// In fr, this message translates to:
  /// **'Largeur'**
  String get pondWidth;

  /// No description provided for @pondSurfaceOverride.
  ///
  /// In fr, this message translates to:
  /// **'Surface mesurée (facultatif)'**
  String get pondSurfaceOverride;

  /// No description provided for @pondDepthInlet.
  ///
  /// In fr, this message translates to:
  /// **'Profondeur à l\'entrée'**
  String get pondDepthInlet;

  /// No description provided for @pondDepthOutlet.
  ///
  /// In fr, this message translates to:
  /// **'Profondeur à la sortie'**
  String get pondDepthOutlet;

  /// No description provided for @pondStatusLabel.
  ///
  /// In fr, this message translates to:
  /// **'État'**
  String get pondStatusLabel;

  /// No description provided for @duplicateCode.
  ///
  /// In fr, this message translates to:
  /// **'Ce code existe déjà'**
  String get duplicateCode;

  /// No description provided for @pondFish.
  ///
  /// In fr, this message translates to:
  /// **'Poissons'**
  String get pondFish;

  /// No description provided for @pondBiomass.
  ///
  /// In fr, this message translates to:
  /// **'Biomasse'**
  String get pondBiomass;

  /// No description provided for @pondDensity.
  ///
  /// In fr, this message translates to:
  /// **'Densité'**
  String get pondDensity;

  /// No description provided for @pondSurface.
  ///
  /// In fr, this message translates to:
  /// **'Surface'**
  String get pondSurface;

  /// No description provided for @inconsistent.
  ///
  /// In fr, this message translates to:
  /// **'À vérifier'**
  String get inconsistent;

  /// No description provided for @pondStock.
  ///
  /// In fr, this message translates to:
  /// **'Empoissonner'**
  String get pondStock;

  /// No description provided for @pondTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Transférer'**
  String get pondTransfer;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @archive.
  ///
  /// In fr, this message translates to:
  /// **'Archiver'**
  String get archive;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @avgWeight.
  ///
  /// In fr, this message translates to:
  /// **'Poids moyen'**
  String get avgWeight;

  /// No description provided for @pondNoFish.
  ///
  /// In fr, this message translates to:
  /// **'Pas de poissons'**
  String get pondNoFish;

  /// No description provided for @adultFeed.
  ///
  /// In fr, this message translates to:
  /// **'aliment adulte'**
  String get adultFeed;

  /// No description provided for @pondSurfaceComputed.
  ///
  /// In fr, this message translates to:
  /// **'Surface calculée : {surface}'**
  String pondSurfaceComputed(String surface);

  /// No description provided for @densityValue.
  ///
  /// In fr, this message translates to:
  /// **'{density} /m²'**
  String densityValue(String density);

  /// No description provided for @archiveConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Archiver l\'étang {code} ? Il disparaîtra des listes.'**
  String archiveConfirm(String code);

  /// No description provided for @feedingGuide.
  ///
  /// In fr, this message translates to:
  /// **'Aliment : {protein} de protéines, granulé {pellet}, {meals} repas par jour'**
  String feedingGuide(String protein, String pellet, String meals);

  /// No description provided for @stockTitle.
  ///
  /// In fr, this message translates to:
  /// **'Empoissonner'**
  String get stockTitle;

  /// No description provided for @batchCode.
  ///
  /// In fr, this message translates to:
  /// **'Code du lot'**
  String get batchCode;

  /// No description provided for @stockDate.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'empoissonnement'**
  String get stockDate;

  /// No description provided for @stockCount.
  ///
  /// In fr, this message translates to:
  /// **'Nombre d\'alevins'**
  String get stockCount;

  /// No description provided for @strain.
  ///
  /// In fr, this message translates to:
  /// **'Souche (ex. GIFT)'**
  String get strain;

  /// No description provided for @hatchery.
  ///
  /// In fr, this message translates to:
  /// **'Écloserie'**
  String get hatchery;

  /// No description provided for @certificate.
  ///
  /// In fr, this message translates to:
  /// **'N° de certificat sanitaire'**
  String get certificate;

  /// No description provided for @monosex.
  ///
  /// In fr, this message translates to:
  /// **'Tout mâle (monosexe)'**
  String get monosex;

  /// No description provided for @yes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// No description provided for @unknown.
  ///
  /// In fr, this message translates to:
  /// **'Ne sait pas'**
  String get unknown;

  /// No description provided for @plannedHarvest.
  ///
  /// In fr, this message translates to:
  /// **'Récolte prévue (facultatif)'**
  String get plannedHarvest;

  /// No description provided for @pickPond.
  ///
  /// In fr, this message translates to:
  /// **'Étang'**
  String get pickPond;

  /// No description provided for @warnPondIsolated.
  ///
  /// In fr, this message translates to:
  /// **'Étang isolé : à éviter'**
  String get warnPondIsolated;

  /// No description provided for @warnDensityBelow.
  ///
  /// In fr, this message translates to:
  /// **'Densité sous le minimum conseillé'**
  String get warnDensityBelow;

  /// No description provided for @warnDensityAbove.
  ///
  /// In fr, this message translates to:
  /// **'Densité au-dessus du maximum conseillé'**
  String get warnDensityAbove;

  /// No description provided for @batchesEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun lot : empoissonnez un étang depuis sa page'**
  String get batchesEmpty;

  /// No description provided for @history.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get history;

  /// No description provided for @eventStocking.
  ///
  /// In fr, this message translates to:
  /// **'Empoissonnement'**
  String get eventStocking;

  /// No description provided for @eventTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Transfert'**
  String get eventTransfer;

  /// No description provided for @correct.
  ///
  /// In fr, this message translates to:
  /// **'Corriger'**
  String get correct;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @deleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cet enregistrement ?'**
  String get deleteConfirm;

  /// No description provided for @fishPerPond.
  ///
  /// In fr, this message translates to:
  /// **'Poissons par étang'**
  String get fishPerPond;

  /// No description provided for @batchEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le lot'**
  String get batchEdit;

  /// No description provided for @correctionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Corriger'**
  String get correctionTitle;

  /// No description provided for @acclimatised.
  ///
  /// In fr, this message translates to:
  /// **'Acclimatés {min} à {max} min'**
  String acclimatised(String min, String max);

  /// No description provided for @acclimatiseReminder.
  ///
  /// In fr, this message translates to:
  /// **'Faire flotter le sac fermé {min} à {max} min sur l\'étang avant de lâcher les alevins.'**
  String acclimatiseReminder(String min, String max);

  /// No description provided for @densityResult.
  ///
  /// In fr, this message translates to:
  /// **'Densité après empoissonnement : {density} /m² (conseillé : {min} à {max})'**
  String densityResult(String density, String min, String max);

  /// No description provided for @warnPondNotReady.
  ///
  /// In fr, this message translates to:
  /// **'L\'étang n\'est pas marqué prêt ({status})'**
  String warnPondNotReady(String status);

  /// No description provided for @warnWeightOutsideRange.
  ///
  /// In fr, this message translates to:
  /// **'Poids moyen hors des {min} à {max} g conseillés'**
  String warnWeightOutsideRange(String min, String max);

  /// No description provided for @stockedOn.
  ///
  /// In fr, this message translates to:
  /// **'Empoissonné le {date}'**
  String stockedOn(String date);

  /// No description provided for @initialStock.
  ///
  /// In fr, this message translates to:
  /// **'Départ : {count} alevins de {weight}, le {date}'**
  String initialStock(String count, String weight, String date);

  /// No description provided for @plannedHarvestOn.
  ///
  /// In fr, this message translates to:
  /// **'Récolte prévue le {date}'**
  String plannedHarvestOn(String date);

  /// No description provided for @toPond.
  ///
  /// In fr, this message translates to:
  /// **'Vers l\'étang'**
  String get toPond;

  /// No description provided for @transferCount.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de poissons'**
  String get transferCount;

  /// No description provided for @transferDate.
  ///
  /// In fr, this message translates to:
  /// **'Date du transfert'**
  String get transferDate;

  /// No description provided for @avgWeightOptional.
  ///
  /// In fr, this message translates to:
  /// **'Poids moyen (facultatif)'**
  String get avgWeightOptional;

  /// No description provided for @warnDestIsolated.
  ///
  /// In fr, this message translates to:
  /// **'L\'étang de destination est isolé'**
  String get warnDestIsolated;

  /// No description provided for @isolatedSource.
  ///
  /// In fr, this message translates to:
  /// **'Étang isolé : aucun poisson ne doit en sortir'**
  String get isolatedSource;

  /// No description provided for @transferTitle.
  ///
  /// In fr, this message translates to:
  /// **'Transférer {code} depuis {pond}'**
  String transferTitle(String code, String pond);

  /// No description provided for @estimateIn.
  ///
  /// In fr, this message translates to:
  /// **'≈ {count} dans {pond}'**
  String estimateIn(String count, String pond);

  /// No description provided for @warnAboveEstimate.
  ///
  /// In fr, this message translates to:
  /// **'Plus que l\'estimation ({count})'**
  String warnAboveEstimate(String count);

  /// No description provided for @destDensity.
  ///
  /// In fr, this message translates to:
  /// **'Densité de {pond} après transfert : {density} /m² (conseillé : {min} à {max})'**
  String destDensity(String pond, String density, String min, String max);

  /// No description provided for @pondNotEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Cet étang contient encore des poissons : transférez-les d\'abord.'**
  String get pondNotEmpty;

  /// No description provided for @signNoAppetite.
  ///
  /// In fr, this message translates to:
  /// **'Ne mange pas'**
  String get signNoAppetite;

  /// No description provided for @signSurfaceSwimming.
  ///
  /// In fr, this message translates to:
  /// **'Nage en surface'**
  String get signSurfaceSwimming;

  /// No description provided for @signNearBanks.
  ///
  /// In fr, this message translates to:
  /// **'Reste près des bords'**
  String get signNearBanks;

  /// No description provided for @signErraticOrCircling.
  ///
  /// In fr, this message translates to:
  /// **'Nage en rond'**
  String get signErraticOrCircling;

  /// No description provided for @signAbnormalColour.
  ///
  /// In fr, this message translates to:
  /// **'Couleur anormale'**
  String get signAbnormalColour;

  /// No description provided for @signSkinLesions.
  ///
  /// In fr, this message translates to:
  /// **'Plaies sur la peau'**
  String get signSkinLesions;

  /// No description provided for @signPaleOrSwollenGills.
  ///
  /// In fr, this message translates to:
  /// **'Branchies pâles ou gonflées'**
  String get signPaleOrSwollenGills;

  /// No description provided for @signGroupedDeaths.
  ///
  /// In fr, this message translates to:
  /// **'Morts en groupe'**
  String get signGroupedDeaths;

  /// No description provided for @signRubbing.
  ///
  /// In fr, this message translates to:
  /// **'Se frotte'**
  String get signRubbing;

  /// No description provided for @signExcessMucus.
  ///
  /// In fr, this message translates to:
  /// **'Trop de mucus'**
  String get signExcessMucus;

  /// No description provided for @signWhiteSpots.
  ///
  /// In fr, this message translates to:
  /// **'Points blancs'**
  String get signWhiteSpots;

  /// No description provided for @signBulgingEyes.
  ///
  /// In fr, this message translates to:
  /// **'Yeux gonflés'**
  String get signBulgingEyes;

  /// No description provided for @signFinBleeding.
  ///
  /// In fr, this message translates to:
  /// **'Nageoires qui saignent'**
  String get signFinBleeding;

  /// No description provided for @leftoverNone.
  ///
  /// In fr, this message translates to:
  /// **'Tout mangé'**
  String get leftoverNone;

  /// No description provided for @leftoverSome.
  ///
  /// In fr, this message translates to:
  /// **'Un peu de reste'**
  String get leftoverSome;

  /// No description provided for @leftoverLots.
  ///
  /// In fr, this message translates to:
  /// **'Beaucoup de reste'**
  String get leftoverLots;

  /// No description provided for @ateFast.
  ///
  /// In fr, this message translates to:
  /// **'Mangé très vite'**
  String get ateFast;

  /// No description provided for @waterClear.
  ///
  /// In fr, this message translates to:
  /// **'Claire'**
  String get waterClear;

  /// No description provided for @waterLightGreen.
  ///
  /// In fr, this message translates to:
  /// **'Vert clair'**
  String get waterLightGreen;

  /// No description provided for @waterMediumGreen.
  ///
  /// In fr, this message translates to:
  /// **'Vert'**
  String get waterMediumGreen;

  /// No description provided for @waterDarkGreen.
  ///
  /// In fr, this message translates to:
  /// **'Vert foncé'**
  String get waterDarkGreen;

  /// No description provided for @waterBrownTurbid.
  ///
  /// In fr, this message translates to:
  /// **'Marron, trouble'**
  String get waterBrownTurbid;

  /// No description provided for @obsDike.
  ///
  /// In fr, this message translates to:
  /// **'Digues'**
  String get obsDike;

  /// No description provided for @obsInletScreen.
  ///
  /// In fr, this message translates to:
  /// **'Grilles d\'entrée'**
  String get obsInletScreen;

  /// No description provided for @obsPredatorNets.
  ///
  /// In fr, this message translates to:
  /// **'Filets anti-prédateurs'**
  String get obsPredatorNets;

  /// No description provided for @obsFence.
  ///
  /// In fr, this message translates to:
  /// **'Clôture'**
  String get obsFence;

  /// No description provided for @obsGrass.
  ///
  /// In fr, this message translates to:
  /// **'Herbe'**
  String get obsGrass;

  /// No description provided for @obsPredators.
  ///
  /// In fr, this message translates to:
  /// **'Prédateurs'**
  String get obsPredators;

  /// No description provided for @obsTheft.
  ///
  /// In fr, this message translates to:
  /// **'Vol'**
  String get obsTheft;

  /// No description provided for @obsOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get obsOther;

  /// No description provided for @workerMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode ouvrier'**
  String get workerMode;

  /// No description provided for @workerToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get workerToday;

  /// No description provided for @workerExit.
  ///
  /// In fr, this message translates to:
  /// **'Quitter'**
  String get workerExit;

  /// No description provided for @dailyLog.
  ///
  /// In fr, this message translates to:
  /// **'Journal du jour'**
  String get dailyLog;

  /// No description provided for @feedGiven.
  ///
  /// In fr, this message translates to:
  /// **'Aliment donné'**
  String get feedGiven;

  /// No description provided for @feedings.
  ///
  /// In fr, this message translates to:
  /// **'Repas donnés'**
  String get feedings;

  /// No description provided for @leftovers.
  ///
  /// In fr, this message translates to:
  /// **'Reste'**
  String get leftovers;

  /// No description provided for @deaths.
  ///
  /// In fr, this message translates to:
  /// **'Morts'**
  String get deaths;

  /// No description provided for @deathAppearance.
  ///
  /// In fr, this message translates to:
  /// **'Aspect des morts'**
  String get deathAppearance;

  /// No description provided for @signsSeen.
  ///
  /// In fr, this message translates to:
  /// **'Signes'**
  String get signsSeen;

  /// No description provided for @waterColourLabel.
  ///
  /// In fr, this message translates to:
  /// **'Couleur de l\'eau'**
  String get waterColourLabel;

  /// No description provided for @addNote.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une note'**
  String get addNote;

  /// No description provided for @noteLabel.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get noteLabel;

  /// No description provided for @saved.
  ///
  /// In fr, this message translates to:
  /// **'Enregistré'**
  String get saved;

  /// No description provided for @pondIsolatedBanner.
  ///
  /// In fr, this message translates to:
  /// **'Étang isolé'**
  String get pondIsolatedBanner;

  /// No description provided for @rationHint.
  ///
  /// In fr, this message translates to:
  /// **'≈ {amount}'**
  String rationHint(String amount);

  /// No description provided for @waterReading.
  ///
  /// In fr, this message translates to:
  /// **'Relevé d\'eau'**
  String get waterReading;

  /// No description provided for @sampling.
  ///
  /// In fr, this message translates to:
  /// **'Échantillonnage'**
  String get sampling;

  /// No description provided for @temperature.
  ///
  /// In fr, this message translates to:
  /// **'Température'**
  String get temperature;

  /// No description provided for @ph.
  ///
  /// In fr, this message translates to:
  /// **'pH'**
  String get ph;

  /// No description provided for @oxygen.
  ///
  /// In fr, this message translates to:
  /// **'Oxygène dissous'**
  String get oxygen;

  /// No description provided for @renewedPct.
  ///
  /// In fr, this message translates to:
  /// **'Eau renouvelée'**
  String get renewedPct;

  /// No description provided for @readingTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure du relevé'**
  String get readingTime;

  /// No description provided for @sampleFish.
  ///
  /// In fr, this message translates to:
  /// **'Poissons pesés'**
  String get sampleFish;

  /// No description provided for @sampleWeight.
  ///
  /// In fr, this message translates to:
  /// **'Poids total'**
  String get sampleWeight;

  /// No description provided for @sampleDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de pesée'**
  String get sampleDate;

  /// No description provided for @renewWater.
  ///
  /// In fr, this message translates to:
  /// **'Couleur : renouveler l\'eau'**
  String get renewWater;

  /// No description provided for @targetRange.
  ///
  /// In fr, this message translates to:
  /// **'cible {min} à {max} {unit}'**
  String targetRange(String min, String max, String unit);

  /// No description provided for @targetMin.
  ///
  /// In fr, this message translates to:
  /// **'cible {min} {unit} ou plus'**
  String targetMin(String min, String unit);

  /// No description provided for @lastReading.
  ///
  /// In fr, this message translates to:
  /// **'Dernier relevé, le {date} :'**
  String lastReading(String date);

  /// No description provided for @smallSample.
  ///
  /// In fr, this message translates to:
  /// **'Petit échantillon (moins de {min} poissons)'**
  String smallSample(String min);

  /// No description provided for @sampleAverage.
  ///
  /// In fr, this message translates to:
  /// **'Poids moyen : {weight}'**
  String sampleAverage(String weight);

  /// No description provided for @transcription.
  ///
  /// In fr, this message translates to:
  /// **'Saisie des fiches'**
  String get transcription;

  /// No description provided for @sheetOf.
  ///
  /// In fr, this message translates to:
  /// **'Fiche de'**
  String get sheetOf;

  /// No description provided for @previousWeek.
  ///
  /// In fr, this message translates to:
  /// **'Semaine précédente'**
  String get previousWeek;

  /// No description provided for @nextWeek.
  ///
  /// In fr, this message translates to:
  /// **'Semaine suivante'**
  String get nextWeek;

  /// No description provided for @feedMissing.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez l\'aliment pour chaque case remplie (0 si rien n\'a été donné).'**
  String get feedMissing;

  /// No description provided for @weekOfLabel.
  ///
  /// In fr, this message translates to:
  /// **'Semaine du {date}'**
  String weekOfLabel(String date);

  /// No description provided for @reportProblem.
  ///
  /// In fr, this message translates to:
  /// **'Signaler un problème'**
  String get reportProblem;

  /// No description provided for @suspectedIssue.
  ///
  /// In fr, this message translates to:
  /// **'Problème suspecté (facultatif)'**
  String get suspectedIssue;

  /// No description provided for @isolatePond.
  ///
  /// In fr, this message translates to:
  /// **'Isoler l\'étang'**
  String get isolatePond;

  /// No description provided for @technicianCalled.
  ///
  /// In fr, this message translates to:
  /// **'Technicien ou vétérinaire appelé'**
  String get technicianCalled;

  /// No description provided for @healthResponse.
  ///
  /// In fr, this message translates to:
  /// **'Isoler l\'étang, ne déplacer ni poissons ni eau vers les autres étangs, appeler un technicien ou un vétérinaire avant tout traitement.'**
  String get healthResponse;

  /// No description provided for @healthInfoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Information, pas un diagnostic'**
  String get healthInfoTitle;

  /// No description provided for @diseaseStrepto.
  ///
  /// In fr, this message translates to:
  /// **'Streptococcose'**
  String get diseaseStrepto;

  /// No description provided for @diseaseStreptoSigns.
  ///
  /// In fr, this message translates to:
  /// **'nage désordonnée, yeux gonflés, mortalité rapide ; favorisée par une forte densité et la chaleur.'**
  String get diseaseStreptoSigns;

  /// No description provided for @diseaseAeromonas.
  ///
  /// In fr, this message translates to:
  /// **'Aeromonas'**
  String get diseaseAeromonas;

  /// No description provided for @diseaseAeromonasSigns.
  ///
  /// In fr, this message translates to:
  /// **'ulcères de la peau, nageoires qui saignent ; liée à une eau de mauvaise qualité ou aux blessures de manipulation.'**
  String get diseaseAeromonasSigns;

  /// No description provided for @diseaseParasites.
  ///
  /// In fr, this message translates to:
  /// **'Parasites externes (Trichodina, Ich)'**
  String get diseaseParasites;

  /// No description provided for @diseaseParasitesSigns.
  ///
  /// In fr, this message translates to:
  /// **'se frotte aux parois ou au fond, trop de mucus, points blancs.'**
  String get diseaseParasitesSigns;

  /// No description provided for @releaseIsolation.
  ///
  /// In fr, this message translates to:
  /// **'Lever l\'isolement'**
  String get releaseIsolation;

  /// No description provided for @treatment.
  ///
  /// In fr, this message translates to:
  /// **'Traitement'**
  String get treatment;

  /// No description provided for @product.
  ///
  /// In fr, this message translates to:
  /// **'Produit'**
  String get product;

  /// No description provided for @dose.
  ///
  /// In fr, this message translates to:
  /// **'Dose'**
  String get dose;

  /// No description provided for @advisedBy.
  ///
  /// In fr, this message translates to:
  /// **'Conseillé par'**
  String get advisedBy;

  /// No description provided for @treatmentDate.
  ///
  /// In fr, this message translates to:
  /// **'Date du traitement'**
  String get treatmentDate;

  /// No description provided for @healthHistory.
  ///
  /// In fr, this message translates to:
  /// **'Santé'**
  String get healthHistory;

  /// No description provided for @actionIsolated.
  ///
  /// In fr, this message translates to:
  /// **'isolé'**
  String get actionIsolated;

  /// No description provided for @actionTechnician.
  ///
  /// In fr, this message translates to:
  /// **'technicien appelé'**
  String get actionTechnician;

  /// No description provided for @actionReleased.
  ///
  /// In fr, this message translates to:
  /// **'isolement levé'**
  String get actionReleased;

  /// No description provided for @batchOptional.
  ///
  /// In fr, this message translates to:
  /// **'Lot (facultatif)'**
  String get batchOptional;

  /// No description provided for @releaseConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Lever l\'isolement de {code} ? Les poissons pourront de nouveau en sortir.'**
  String releaseConfirm(String code);

  /// No description provided for @tabVisit.
  ///
  /// In fr, this message translates to:
  /// **'Visite'**
  String get tabVisit;

  /// No description provided for @startVisit.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer une visite'**
  String get startVisit;

  /// No description provided for @sectionWater.
  ///
  /// In fr, this message translates to:
  /// **'Eau'**
  String get sectionWater;

  /// No description provided for @sectionSamples.
  ///
  /// In fr, this message translates to:
  /// **'Échantillons'**
  String get sectionSamples;

  /// No description provided for @sectionConditions.
  ///
  /// In fr, this message translates to:
  /// **'État des étangs'**
  String get sectionConditions;

  /// No description provided for @sectionBiosecurity.
  ///
  /// In fr, this message translates to:
  /// **'Biosécurité'**
  String get sectionBiosecurity;

  /// No description provided for @sectionObservations.
  ///
  /// In fr, this message translates to:
  /// **'Observations'**
  String get sectionObservations;

  /// No description provided for @summary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé'**
  String get summary;

  /// No description provided for @allDone.
  ///
  /// In fr, this message translates to:
  /// **'Tout est fait'**
  String get allDone;

  /// No description provided for @endVisit.
  ///
  /// In fr, this message translates to:
  /// **'Terminer la visite'**
  String get endVisit;

  /// No description provided for @endVisitConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Terminer la visite ? Le rapport sera préparé à partir de ce qui a été saisi.'**
  String get endVisitConfirm;

  /// No description provided for @visitEnded.
  ///
  /// In fr, this message translates to:
  /// **'terminée'**
  String get visitEnded;

  /// No description provided for @visitOngoing.
  ///
  /// In fr, this message translates to:
  /// **'en cours'**
  String get visitOngoing;

  /// No description provided for @addObservation.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une observation'**
  String get addObservation;

  /// No description provided for @observationText.
  ///
  /// In fr, this message translates to:
  /// **'Observation'**
  String get observationText;

  /// No description provided for @category.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get category;

  /// No description provided for @conditionOk.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get conditionOk;

  /// No description provided for @conditionProblem.
  ///
  /// In fr, this message translates to:
  /// **'Problème'**
  String get conditionProblem;

  /// No description provided for @pastVisits.
  ///
  /// In fr, this message translates to:
  /// **'Visites précédentes'**
  String get pastVisits;

  /// No description provided for @noVisits.
  ///
  /// In fr, this message translates to:
  /// **'Aucune visite pour l\'instant'**
  String get noVisits;

  /// No description provided for @bioDisinfect.
  ///
  /// In fr, this message translates to:
  /// **'Filets, seaux et épuisettes désinfectés entre les étangs (chlore dilué, puis rinçage)'**
  String get bioDisinfect;

  /// No description provided for @bioToolsPerPond.
  ///
  /// In fr, this message translates to:
  /// **'Un jeu d\'outils par étang si possible'**
  String get bioToolsPerPond;

  /// No description provided for @bioFootbath.
  ///
  /// In fr, this message translates to:
  /// **'Pédiluve ou bottes propres à l\'entrée'**
  String get bioFootbath;

  /// No description provided for @bioAnimals.
  ///
  /// In fr, this message translates to:
  /// **'Canards et autres animaux tenus à l\'écart'**
  String get bioAnimals;

  /// No description provided for @bioPredators.
  ///
  /// In fr, this message translates to:
  /// **'Filets anti-prédateurs et petite clôture en place'**
  String get bioPredators;

  /// No description provided for @bioProtection.
  ///
  /// In fr, this message translates to:
  /// **'Gants et bottes pour la chaux et le chlore'**
  String get bioProtection;

  /// No description provided for @bioNotAlone.
  ///
  /// In fr, this message translates to:
  /// **'Personne ne travaille seul pendant une vidange ou une grosse pêche'**
  String get bioNotAlone;

  /// No description provided for @visitOpenSince.
  ///
  /// In fr, this message translates to:
  /// **'Visite en cours depuis {time}'**
  String visitOpenSince(String time);

  /// No description provided for @sampleOfIn.
  ///
  /// In fr, this message translates to:
  /// **'{batch} dans {pond}'**
  String sampleOfIn(String batch, String pond);

  /// No description provided for @conditionsOf.
  ///
  /// In fr, this message translates to:
  /// **'État de {pond}'**
  String conditionsOf(String pond);

  /// No description provided for @visitLine.
  ///
  /// In fr, this message translates to:
  /// **'{date} · {state}'**
  String visitLine(String date, String state);

  /// No description provided for @welcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue'**
  String get welcomeTitle;

  /// No description provided for @welcomeMember.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter (membre)'**
  String get welcomeMember;

  /// No description provided for @welcomeWorker.
  ///
  /// In fr, this message translates to:
  /// **'Je suis ouvrier'**
  String get welcomeWorker;

  /// No description provided for @welcomeCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer l\'association'**
  String get welcomeCreate;

  /// No description provided for @loginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get loginTitle;

  /// No description provided for @loginEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get loginEmail;

  /// No description provided for @loginPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get loginPassword;

  /// No description provided for @loginUsername.
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'utilisateur'**
  String get loginUsername;

  /// No description provided for @loginPin.
  ///
  /// In fr, this message translates to:
  /// **'Code PIN (6 chiffres)'**
  String get loginPin;

  /// No description provided for @loginSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginSubmit;

  /// No description provided for @errorOffline.
  ///
  /// In fr, this message translates to:
  /// **'Connexion nécessaire'**
  String get errorOffline;

  /// No description provided for @errorBadLogin.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant ou mot de passe incorrect'**
  String get errorBadLogin;

  /// No description provided for @errorOtherAssociation.
  ///
  /// In fr, this message translates to:
  /// **'Ce téléphone contient les données d\'une autre association. Exportez d\'abord une sauvegarde.'**
  String get errorOtherAssociation;

  /// No description provided for @errorNoMember.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte n\'est pas actif'**
  String get errorNoMember;

  /// No description provided for @errorNoSite.
  ///
  /// In fr, this message translates to:
  /// **'L\'association n\'a pas encore de site : synchronisez d\'abord le téléphone du fondateur.'**
  String get errorNoSite;

  /// No description provided for @errorTaken.
  ///
  /// In fr, this message translates to:
  /// **'Cet identifiant est déjà utilisé'**
  String get errorTaken;

  /// No description provided for @errorFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec : {code}'**
  String errorFailed(String code);

  /// No description provided for @passwordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'8 caractères au moins'**
  String get passwordTooShort;

  /// No description provided for @pinSixDigits.
  ///
  /// In fr, this message translates to:
  /// **'6 chiffres'**
  String get pinSixDigits;

  /// No description provided for @createTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer l\'association'**
  String get createTitle;

  /// No description provided for @createAssociationName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'association'**
  String get createAssociationName;

  /// No description provided for @createGroupName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de votre branche'**
  String get createGroupName;

  /// No description provided for @createYourName.
  ///
  /// In fr, this message translates to:
  /// **'Votre nom'**
  String get createYourName;

  /// No description provided for @createSubmit.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get createSubmit;

  /// No description provided for @moreAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get moreAccount;

  /// No description provided for @accountSignOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get accountSignOut;

  /// No description provided for @accountSignOutQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter de ce téléphone ?'**
  String get accountSignOutQuestion;

  /// No description provided for @accountSignOutPending.
  ///
  /// In fr, this message translates to:
  /// **'{count} enregistrements ne sont pas encore envoyés. Ils restent sur ce téléphone et partiront à la prochaine synchronisation.'**
  String accountSignOutPending(int count);

  /// No description provided for @accountRole.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get accountRole;

  /// No description provided for @roleMember.
  ///
  /// In fr, this message translates to:
  /// **'Membre'**
  String get roleMember;

  /// No description provided for @roleWorker.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrier'**
  String get roleWorker;

  /// No description provided for @roleAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur'**
  String get roleAdmin;

  /// No description provided for @roleSales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes'**
  String get roleSales;

  /// No description provided for @moreSync.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation'**
  String get moreSync;

  /// No description provided for @syncLast.
  ///
  /// In fr, this message translates to:
  /// **'Dernière synchronisation : {at}'**
  String syncLast(String at);

  /// No description provided for @syncNever.
  ///
  /// In fr, this message translates to:
  /// **'Jamais synchronisé'**
  String get syncNever;

  /// No description provided for @syncPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente d\'envoi : {count}'**
  String syncPending(int count);

  /// No description provided for @syncRejectedCount.
  ///
  /// In fr, this message translates to:
  /// **'Refusés : {count}'**
  String syncRejectedCount(int count);

  /// No description provided for @syncNow.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser'**
  String get syncNow;

  /// No description provided for @syncRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer les refusés'**
  String get syncRetry;

  /// No description provided for @syncRelogin.
  ///
  /// In fr, this message translates to:
  /// **'Se reconnecter'**
  String get syncRelogin;

  /// No description provided for @syncLink.
  ///
  /// In fr, this message translates to:
  /// **'Créer le compte de l\'association'**
  String get syncLink;

  /// No description provided for @syncStateRunning.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation en cours…'**
  String get syncStateRunning;

  /// No description provided for @syncStateOffline.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion : les données restent sur le téléphone.'**
  String get syncStateOffline;

  /// No description provided for @syncStateSignedOut.
  ///
  /// In fr, this message translates to:
  /// **'Session terminée : reconnectez-vous pour envoyer les données.'**
  String get syncStateSignedOut;

  /// No description provided for @syncStateUnlinked.
  ///
  /// In fr, this message translates to:
  /// **'Ce téléphone n\'est relié à aucun compte.'**
  String get syncStateUnlinked;

  /// No description provided for @syncStateNotConfigured.
  ///
  /// In fr, this message translates to:
  /// **'Aucun serveur dans cette version : les données restent sur le téléphone.'**
  String get syncStateNotConfigured;

  /// No description provided for @syncStateFailed.
  ///
  /// In fr, this message translates to:
  /// **'La synchronisation a échoué : {error}'**
  String syncStateFailed(String error);

  /// No description provided for @rejectRole.
  ///
  /// In fr, this message translates to:
  /// **'Votre rôle ne permet pas cet enregistrement'**
  String get rejectRole;

  /// No description provided for @rejectLastAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Il doit rester au moins un administrateur'**
  String get rejectLastAdmin;

  /// No description provided for @rejectOther.
  ///
  /// In fr, this message translates to:
  /// **'Refusé : {reason}'**
  String rejectOther(String reason);

  /// No description provided for @tableDailyLogs.
  ///
  /// In fr, this message translates to:
  /// **'Journal'**
  String get tableDailyLogs;

  /// No description provided for @tableWaterReadings.
  ///
  /// In fr, this message translates to:
  /// **'Relevé d\'eau'**
  String get tableWaterReadings;

  /// No description provided for @tableSamples.
  ///
  /// In fr, this message translates to:
  /// **'Échantillonnage'**
  String get tableSamples;

  /// No description provided for @tableObservations.
  ///
  /// In fr, this message translates to:
  /// **'Observation'**
  String get tableObservations;

  /// No description provided for @tableHealthEvents.
  ///
  /// In fr, this message translates to:
  /// **'Problème de santé'**
  String get tableHealthEvents;

  /// No description provided for @tableTreatments.
  ///
  /// In fr, this message translates to:
  /// **'Traitement'**
  String get tableTreatments;

  /// No description provided for @tableStockings.
  ///
  /// In fr, this message translates to:
  /// **'Empoissonnement'**
  String get tableStockings;

  /// No description provided for @tableTransfers.
  ///
  /// In fr, this message translates to:
  /// **'Transfert'**
  String get tableTransfers;

  /// No description provided for @tablePonds.
  ///
  /// In fr, this message translates to:
  /// **'Étang'**
  String get tablePonds;

  /// No description provided for @tableBatches.
  ///
  /// In fr, this message translates to:
  /// **'Lot'**
  String get tableBatches;

  /// No description provided for @tablePeople.
  ///
  /// In fr, this message translates to:
  /// **'Personne'**
  String get tablePeople;

  /// No description provided for @tableSites.
  ///
  /// In fr, this message translates to:
  /// **'Site'**
  String get tableSites;

  /// No description provided for @tableVisits.
  ///
  /// In fr, this message translates to:
  /// **'Visite'**
  String get tableVisits;

  /// No description provided for @tableGroups.
  ///
  /// In fr, this message translates to:
  /// **'Branche'**
  String get tableGroups;

  /// No description provided for @tableMembers.
  ///
  /// In fr, this message translates to:
  /// **'Membre'**
  String get tableMembers;

  /// No description provided for @tableSettingOverrides.
  ///
  /// In fr, this message translates to:
  /// **'Réglage'**
  String get tableSettingOverrides;

  /// No description provided for @backupExport.
  ///
  /// In fr, this message translates to:
  /// **'Exporter une sauvegarde'**
  String get backupExport;

  /// No description provided for @backupImport.
  ///
  /// In fr, this message translates to:
  /// **'Importer une sauvegarde'**
  String get backupImport;

  /// No description provided for @backupImported.
  ///
  /// In fr, this message translates to:
  /// **'{added} enregistrements ajoutés, {updated} mis à jour'**
  String backupImported(int added, int updated);

  /// No description provided for @backupNotABackup.
  ///
  /// In fr, this message translates to:
  /// **'Ce fichier n\'est pas une sauvegarde Dobo'**
  String get backupNotABackup;

  /// No description provided for @backupOtherAssociation.
  ///
  /// In fr, this message translates to:
  /// **'Cette sauvegarde appartient à une autre association'**
  String get backupOtherAssociation;

  /// No description provided for @moreAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Administration'**
  String get moreAdmin;

  /// No description provided for @moreLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get moreLanguage;

  /// No description provided for @languageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageMalagasy.
  ///
  /// In fr, this message translates to:
  /// **'Malagasy'**
  String get languageMalagasy;

  /// No description provided for @adminMembers.
  ///
  /// In fr, this message translates to:
  /// **'Membres'**
  String get adminMembers;

  /// No description provided for @adminGroups.
  ///
  /// In fr, this message translates to:
  /// **'Branches'**
  String get adminGroups;

  /// No description provided for @memberNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau compte'**
  String get memberNew;

  /// No description provided for @memberName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get memberName;

  /// No description provided for @memberGroup.
  ///
  /// In fr, this message translates to:
  /// **'Branche'**
  String get memberGroup;

  /// No description provided for @memberNoGroup.
  ///
  /// In fr, this message translates to:
  /// **'Sans branche'**
  String get memberNoGroup;

  /// No description provided for @memberActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get memberActive;

  /// No description provided for @memberPerson.
  ///
  /// In fr, this message translates to:
  /// **'Fiche de l\'ouvrier (facultatif)'**
  String get memberPerson;

  /// No description provided for @memberNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune'**
  String get memberNone;

  /// No description provided for @memberInactive.
  ///
  /// In fr, this message translates to:
  /// **'Inactif'**
  String get memberInactive;

  /// No description provided for @groupName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la branche'**
  String get groupName;

  /// No description provided for @groupsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune branche'**
  String get groupsEmpty;

  /// No description provided for @adminSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get adminSettings;

  /// No description provided for @settingsIntro.
  ///
  /// In fr, this message translates to:
  /// **'Laissez vide pour garder la valeur du dossier d\'élevage.'**
  String get settingsIntro;

  /// No description provided for @settingMin.
  ///
  /// In fr, this message translates to:
  /// **'min'**
  String get settingMin;

  /// No description provided for @settingMax.
  ///
  /// In fr, this message translates to:
  /// **'max'**
  String get settingMax;

  /// No description provided for @settingDefault.
  ///
  /// In fr, this message translates to:
  /// **'Dossier : {value}'**
  String settingDefault(String value);

  /// No description provided for @settingsSaved.
  ///
  /// In fr, this message translates to:
  /// **'Réglages enregistrés'**
  String get settingsSaved;

  /// No description provided for @cfgFryMaxG.
  ///
  /// In fr, this message translates to:
  /// **'Fin de l\'alevinage (g)'**
  String get cfgFryMaxG;

  /// No description provided for @cfgPregrowMaxG.
  ///
  /// In fr, this message translates to:
  /// **'Fin du prégrossissement (g)'**
  String get cfgPregrowMaxG;

  /// No description provided for @cfgGrowoutMaxG.
  ///
  /// In fr, this message translates to:
  /// **'Fin du grossissement (g)'**
  String get cfgGrowoutMaxG;

  /// No description provided for @cfgRationRateFry.
  ///
  /// In fr, this message translates to:
  /// **'Ration en alevinage (part de la biomasse)'**
  String get cfgRationRateFry;

  /// No description provided for @cfgRationRatePregrow.
  ///
  /// In fr, this message translates to:
  /// **'Ration en prégrossissement (part de la biomasse)'**
  String get cfgRationRatePregrow;

  /// No description provided for @cfgRationRateGrowout.
  ///
  /// In fr, this message translates to:
  /// **'Ration en grossissement (part de la biomasse)'**
  String get cfgRationRateGrowout;

  /// No description provided for @cfgRationRateFinishing.
  ///
  /// In fr, this message translates to:
  /// **'Ration en finition (part de la biomasse)'**
  String get cfgRationRateFinishing;

  /// No description provided for @cfgMaxRationRate.
  ///
  /// In fr, this message translates to:
  /// **'Ration maximale (part de la biomasse)'**
  String get cfgMaxRationRate;

  /// No description provided for @cfgLeftoverReduction.
  ///
  /// In fr, this message translates to:
  /// **'Baisse après des restes (part)'**
  String get cfgLeftoverReduction;

  /// No description provided for @cfgAteFastIncrease.
  ///
  /// In fr, this message translates to:
  /// **'Hausse si tout est mangé vite (part)'**
  String get cfgAteFastIncrease;

  /// No description provided for @cfgDensityPerM2Earth.
  ///
  /// In fr, this message translates to:
  /// **'Densité en étang de terre (poissons/m²)'**
  String get cfgDensityPerM2Earth;

  /// No description provided for @cfgDensityPerM2Tank.
  ///
  /// In fr, this message translates to:
  /// **'Densité en bassin (poissons/m²)'**
  String get cfgDensityPerM2Tank;

  /// No description provided for @cfgDensityPerM2Cage.
  ///
  /// In fr, this message translates to:
  /// **'Densité en cage (poissons/m²)'**
  String get cfgDensityPerM2Cage;

  /// No description provided for @cfgTemperatureC.
  ///
  /// In fr, this message translates to:
  /// **'Température (°C)'**
  String get cfgTemperatureC;

  /// No description provided for @cfgPh.
  ///
  /// In fr, this message translates to:
  /// **'pH'**
  String get cfgPh;

  /// No description provided for @cfgMinOxygenMgL.
  ///
  /// In fr, this message translates to:
  /// **'Oxygène minimum (mg/L)'**
  String get cfgMinOxygenMgL;

  /// No description provided for @cfgWaterRenewalPctPerWeek.
  ///
  /// In fr, this message translates to:
  /// **'Renouvellement de l\'eau (% par semaine)'**
  String get cfgWaterRenewalPctPerWeek;

  /// No description provided for @cfgSampleIntervalDays.
  ///
  /// In fr, this message translates to:
  /// **'Jours entre deux échantillonnages'**
  String get cfgSampleIntervalDays;

  /// No description provided for @cfgSampleMinFish.
  ///
  /// In fr, this message translates to:
  /// **'Poissons pesés, au moins'**
  String get cfgSampleMinFish;

  /// No description provided for @cfgSampleMaxFish.
  ///
  /// In fr, this message translates to:
  /// **'Poissons pesés, au plus'**
  String get cfgSampleMaxFish;

  /// No description provided for @cfgWaterCheckIntervalDays.
  ///
  /// In fr, this message translates to:
  /// **'Jours entre deux relevés d\'eau'**
  String get cfgWaterCheckIntervalDays;

  /// No description provided for @cfgFcrTarget.
  ///
  /// In fr, this message translates to:
  /// **'IC visé'**
  String get cfgFcrTarget;

  /// No description provided for @cfgFeedAgeWarnDays.
  ///
  /// In fr, this message translates to:
  /// **'Aliment vieux : alerte (jours)'**
  String get cfgFeedAgeWarnDays;

  /// No description provided for @cfgFeedAgeDangerDays.
  ///
  /// In fr, this message translates to:
  /// **'Aliment trop vieux (jours)'**
  String get cfgFeedAgeDangerDays;

  /// No description provided for @cfgLowStockDays.
  ///
  /// In fr, this message translates to:
  /// **'Stock bas (jours restants)'**
  String get cfgLowStockDays;

  /// No description provided for @cfgFeedUsageDays.
  ///
  /// In fr, this message translates to:
  /// **'Consommation moyenne sur (jours)'**
  String get cfgFeedUsageDays;

  /// No description provided for @cfgMortalitySpikeShare.
  ///
  /// In fr, this message translates to:
  /// **'Pic de mortalité : part des poissons'**
  String get cfgMortalitySpikeShare;

  /// No description provided for @cfgMortalitySpikeMultiplier.
  ///
  /// In fr, this message translates to:
  /// **'Pic de mortalité : fois la moyenne'**
  String get cfgMortalitySpikeMultiplier;

  /// No description provided for @cfgMortalitySpikeMinDeaths.
  ///
  /// In fr, this message translates to:
  /// **'Pic de mortalité : morts au moins'**
  String get cfgMortalitySpikeMinDeaths;

  /// No description provided for @cfgMortalityTrailingDays.
  ///
  /// In fr, this message translates to:
  /// **'Pic de mortalité : jours de moyenne'**
  String get cfgMortalityTrailingDays;

  /// No description provided for @cfgWarningSignLookbackDays.
  ///
  /// In fr, this message translates to:
  /// **'Signes d\'alerte récents (jours)'**
  String get cfgWarningSignLookbackDays;

  /// No description provided for @cfgMortalityLookbackDays.
  ///
  /// In fr, this message translates to:
  /// **'Pic de mortalité affiché (jours)'**
  String get cfgMortalityLookbackDays;

  /// No description provided for @cfgStopFeedingSignDays.
  ///
  /// In fr, this message translates to:
  /// **'Ne pas nourrir après des signes de stress (jours)'**
  String get cfgStopFeedingSignDays;

  /// No description provided for @cfgQuarantineDays.
  ///
  /// In fr, this message translates to:
  /// **'Quarantaine (jours)'**
  String get cfgQuarantineDays;

  /// No description provided for @cfgDryingDays.
  ///
  /// In fr, this message translates to:
  /// **'Assèchement (jours)'**
  String get cfgDryingDays;

  /// No description provided for @cfgRestDays.
  ///
  /// In fr, this message translates to:
  /// **'Repos après remplissage (jours)'**
  String get cfgRestDays;

  /// No description provided for @cfgPreHarvestFastHours.
  ///
  /// In fr, this message translates to:
  /// **'Jeûne avant la récolte (heures)'**
  String get cfgPreHarvestFastHours;

  /// No description provided for @cfgHarvestHour.
  ///
  /// In fr, this message translates to:
  /// **'Heure de début de la récolte'**
  String get cfgHarvestHour;

  /// No description provided for @cfgLimeKgPerM2.
  ///
  /// In fr, this message translates to:
  /// **'Chaux (kg/m²)'**
  String get cfgLimeKgPerM2;

  /// No description provided for @cfgManureKgPerM2.
  ///
  /// In fr, this message translates to:
  /// **'Fumier (kg/m²)'**
  String get cfgManureKgPerM2;

  /// No description provided for @cfgPondSurfaceM2.
  ///
  /// In fr, this message translates to:
  /// **'Surface d\'un étang (m²)'**
  String get cfgPondSurfaceM2;

  /// No description provided for @cfgPondLengthWidthRatio.
  ///
  /// In fr, this message translates to:
  /// **'Rapport longueur / largeur'**
  String get cfgPondLengthWidthRatio;

  /// No description provided for @cfgMinDepthM.
  ///
  /// In fr, this message translates to:
  /// **'Profondeur minimale (m)'**
  String get cfgMinDepthM;

  /// No description provided for @cfgStockingWeightG.
  ///
  /// In fr, this message translates to:
  /// **'Poids à l\'empoissonnement (g)'**
  String get cfgStockingWeightG;

  /// No description provided for @cfgAcclimatisationMinutes.
  ///
  /// In fr, this message translates to:
  /// **'Acclimatation (minutes)'**
  String get cfgAcclimatisationMinutes;

  /// No description provided for @cfgSectionPhases.
  ///
  /// In fr, this message translates to:
  /// **'Phases'**
  String get cfgSectionPhases;

  /// No description provided for @cfgSectionFeeding.
  ///
  /// In fr, this message translates to:
  /// **'Alimentation'**
  String get cfgSectionFeeding;

  /// No description provided for @cfgSectionPonds.
  ///
  /// In fr, this message translates to:
  /// **'Étangs'**
  String get cfgSectionPonds;

  /// No description provided for @cfgSectionWaterQuality.
  ///
  /// In fr, this message translates to:
  /// **'Qualité de l\'eau'**
  String get cfgSectionWaterQuality;

  /// No description provided for @cfgSectionSampling.
  ///
  /// In fr, this message translates to:
  /// **'Échantillonnage'**
  String get cfgSectionSampling;

  /// No description provided for @cfgSectionAlertRules.
  ///
  /// In fr, this message translates to:
  /// **'Alertes'**
  String get cfgSectionAlertRules;

  /// No description provided for @cfgSectionFormulas.
  ///
  /// In fr, this message translates to:
  /// **'Calculs'**
  String get cfgSectionFormulas;

  /// No description provided for @cfgSectionFeedStock.
  ///
  /// In fr, this message translates to:
  /// **'Stock d\'aliment'**
  String get cfgSectionFeedStock;

  /// No description provided for @cfgSectionSpeciesAndFingerlings.
  ///
  /// In fr, this message translates to:
  /// **'Alevins'**
  String get cfgSectionSpeciesAndFingerlings;

  /// No description provided for @cfgSectionPondPreparation.
  ///
  /// In fr, this message translates to:
  /// **'Préparation des étangs'**
  String get cfgSectionPondPreparation;

  /// No description provided for @cfgSectionHarvestAndDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Récolte'**
  String get cfgSectionHarvestAndDelivery;

  /// No description provided for @takeoverTitle.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre ce téléphone'**
  String get takeoverTitle;

  /// No description provided for @takeoverHint.
  ///
  /// In fr, this message translates to:
  /// **'Réservé à un administrateur. L\'ouvrier sera déconnecté ; tout ce qu\'il a enregistré reste sur le téléphone.'**
  String get takeoverHint;

  /// No description provided for @takeoverUnsent.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 enregistrement de l\'ouvrier n\'est pas encore envoyé} other{{count} enregistrements de l\'ouvrier ne sont pas encore envoyés}}. Connectez le téléphone au réseau puis réessayez.'**
  String takeoverUnsent(int count);

  /// No description provided for @errorNotAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Ce compte n\'est pas administrateur.'**
  String get errorNotAdmin;

  /// No description provided for @tabAlerts.
  ///
  /// In fr, this message translates to:
  /// **'Alertes'**
  String get tabAlerts;

  /// No description provided for @alertsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune alerte, rien à faire'**
  String get alertsEmpty;

  /// No description provided for @alertsAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get alertsAll;

  /// No description provided for @alertWaterLow.
  ///
  /// In fr, this message translates to:
  /// **'{param} trop bas : {value}'**
  String alertWaterLow(String param, String value);

  /// No description provided for @alertWaterHigh.
  ///
  /// In fr, this message translates to:
  /// **'{param} trop haut : {value}'**
  String alertWaterHigh(String param, String value);

  /// No description provided for @alertWaterColour.
  ///
  /// In fr, this message translates to:
  /// **'Eau trop verte ou trouble : renouveler l\'eau'**
  String get alertWaterColour;

  /// No description provided for @alertFcrWorsening.
  ///
  /// In fr, this message translates to:
  /// **'Lot {batch} : IC en hausse deux fois de suite'**
  String alertFcrWorsening(String batch);

  /// No description provided for @alertGrowthStalled.
  ///
  /// In fr, this message translates to:
  /// **'Lot {batch} : pas de croissance depuis le dernier échantillonnage'**
  String alertGrowthStalled(String batch);

  /// No description provided for @alertMortalitySpike.
  ///
  /// In fr, this message translates to:
  /// **'{deaths} morts le {date}'**
  String alertMortalitySpike(String deaths, String date);

  /// No description provided for @alertWarningSignSeen.
  ///
  /// In fr, this message translates to:
  /// **'Signes d\'alerte : {signs}'**
  String alertWarningSignSeen(String signs);

  /// No description provided for @alertPhaseChange.
  ///
  /// In fr, this message translates to:
  /// **'Lot {batch} : passe en {phase}, changer d\'aliment et de nombre de repas'**
  String alertPhaseChange(String batch, String phase);

  /// No description provided for @alertSampleDue.
  ///
  /// In fr, this message translates to:
  /// **'Lot {batch} : échantillonnage à faire ({days} jours)'**
  String alertSampleDue(String batch, String days);

  /// No description provided for @alertWaterCheckDue.
  ///
  /// In fr, this message translates to:
  /// **'Relevé d\'eau à faire'**
  String get alertWaterCheckDue;

  /// No description provided for @alertQuarantineEnding.
  ///
  /// In fr, this message translates to:
  /// **'Lot {batch} : {days} jours de quarantaine, transfert conseillé avant le jour {recommended}'**
  String alertQuarantineEnding(String batch, String days, String recommended);

  /// No description provided for @alertPreHarvestFast.
  ///
  /// In fr, this message translates to:
  /// **'Lot {batch} : jeûne avant la récolte, ne pas nourrir'**
  String alertPreHarvestFast(String batch);

  /// No description provided for @alertPreHarvestFed.
  ///
  /// In fr, this message translates to:
  /// **'Lot {batch} : jeûne avant la récolte, mais de l\'aliment a été donné'**
  String alertPreHarvestFed(String batch);

  /// No description provided for @alertFeedStockLow.
  ///
  /// In fr, this message translates to:
  /// **'Stock d\'aliment : {days} jours restants'**
  String alertFeedStockLow(String days);

  /// No description provided for @alertFeedOld.
  ///
  /// In fr, this message translates to:
  /// **'Un lot d\'aliment vieillit : l\'utiliser en priorité'**
  String get alertFeedOld;

  /// No description provided for @alertFeedExpired.
  ///
  /// In fr, this message translates to:
  /// **'Un lot d\'aliment est trop vieux : ne pas l\'utiliser'**
  String get alertFeedExpired;

  /// No description provided for @moreFeed.
  ///
  /// In fr, this message translates to:
  /// **'Aliment'**
  String get moreFeed;

  /// No description provided for @harvestAction.
  ///
  /// In fr, this message translates to:
  /// **'Récolter'**
  String get harvestAction;

  /// No description provided for @harvestHasSales.
  ///
  /// In fr, this message translates to:
  /// **'Supprimez d\'abord les ventes de cette récolte'**
  String get harvestHasSales;

  /// No description provided for @harvestEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Corriger la récolte {batch}'**
  String harvestEditTitle(String batch);

  /// No description provided for @feedDeleteDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la livraison'**
  String get feedDeleteDelivery;

  /// No description provided for @sellAction.
  ///
  /// In fr, this message translates to:
  /// **'Vendre'**
  String get sellAction;

  /// No description provided for @harvestTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récolte {batch}'**
  String harvestTitle(String batch);

  /// No description provided for @harvestPond.
  ///
  /// In fr, this message translates to:
  /// **'Étang'**
  String get harvestPond;

  /// No description provided for @harvestDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de récolte'**
  String get harvestDate;

  /// No description provided for @harvestCount.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de poissons'**
  String get harvestCount;

  /// No description provided for @harvestWeight.
  ///
  /// In fr, this message translates to:
  /// **'Poids total'**
  String get harvestWeight;

  /// No description provided for @harvestPartial.
  ///
  /// In fr, this message translates to:
  /// **'Partielle'**
  String get harvestPartial;

  /// No description provided for @harvestFinal.
  ///
  /// In fr, this message translates to:
  /// **'Finale (l\'étang est vidé)'**
  String get harvestFinal;

  /// No description provided for @harvestEstimate.
  ///
  /// In fr, this message translates to:
  /// **'Estimé dans l\'étang : {count} poissons'**
  String harvestEstimate(String count);

  /// No description provided for @harvestMissing.
  ///
  /// In fr, this message translates to:
  /// **'{count} poissons non retrouvés (prédateurs, vol ou erreur de comptage)'**
  String harvestMissing(String count);

  /// No description provided for @harvestNoPond.
  ///
  /// In fr, this message translates to:
  /// **'Aucun étang de ce lot ne peut être récolté : il est vide ou isolé'**
  String get harvestNoPond;

  /// No description provided for @harvestsHeading.
  ///
  /// In fr, this message translates to:
  /// **'Récoltes et ventes'**
  String get harvestsHeading;

  /// No description provided for @harvestKindPartial.
  ///
  /// In fr, this message translates to:
  /// **'Récolte partielle'**
  String get harvestKindPartial;

  /// No description provided for @harvestKindFinal.
  ///
  /// In fr, this message translates to:
  /// **'Récolte finale'**
  String get harvestKindFinal;

  /// No description provided for @harvestLine.
  ///
  /// In fr, this message translates to:
  /// **'{date} · {kind} {pond} : {count} poissons · {kg}'**
  String harvestLine(
    String date,
    String kind,
    String pond,
    String count,
    String kg,
  );

  /// No description provided for @saleLine.
  ///
  /// In fr, this message translates to:
  /// **'{customer} · {form} · {kg}'**
  String saleLine(String customer, String form, String kg);

  /// No description provided for @saleTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vente {batch}'**
  String saleTitle(String batch);

  /// No description provided for @saleHarvest.
  ///
  /// In fr, this message translates to:
  /// **'Récolte'**
  String get saleHarvest;

  /// No description provided for @saleHarvestOption.
  ///
  /// In fr, this message translates to:
  /// **'{date} · {pond} · {kg}'**
  String saleHarvestOption(String date, String pond, String kg);

  /// No description provided for @saleCustomer.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get saleCustomer;

  /// No description provided for @saleNewCustomer.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau client'**
  String get saleNewCustomer;

  /// No description provided for @saleWeight.
  ///
  /// In fr, this message translates to:
  /// **'Poids vendu'**
  String get saleWeight;

  /// No description provided for @saleForm.
  ///
  /// In fr, this message translates to:
  /// **'Forme'**
  String get saleForm;

  /// No description provided for @saleDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de vente'**
  String get saleDate;

  /// No description provided for @saleNote.
  ///
  /// In fr, this message translates to:
  /// **'Bon de livraison (facultatif)'**
  String get saleNote;

  /// No description provided for @saleOverHarvest.
  ///
  /// In fr, this message translates to:
  /// **'Plus que le poids récolté pas encore vendu ({kg})'**
  String saleOverHarvest(String kg);

  /// No description provided for @formLive.
  ///
  /// In fr, this message translates to:
  /// **'Vivant'**
  String get formLive;

  /// No description provided for @formFresh.
  ///
  /// In fr, this message translates to:
  /// **'Frais'**
  String get formFresh;

  /// No description provided for @formFrozen.
  ///
  /// In fr, this message translates to:
  /// **'Congelé'**
  String get formFrozen;

  /// No description provided for @formSmoked.
  ///
  /// In fr, this message translates to:
  /// **'Fumé'**
  String get formSmoked;

  /// No description provided for @formDried.
  ///
  /// In fr, this message translates to:
  /// **'Séché'**
  String get formDried;

  /// No description provided for @moreSales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes'**
  String get moreSales;

  /// No description provided for @traceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Fiche de traçabilité'**
  String get traceTitle;

  /// No description provided for @traceBatch.
  ///
  /// In fr, this message translates to:
  /// **'Lot {code}'**
  String traceBatch(String code);

  /// No description provided for @traceIdentity.
  ///
  /// In fr, this message translates to:
  /// **'Identité'**
  String get traceIdentity;

  /// No description provided for @tracePonds.
  ///
  /// In fr, this message translates to:
  /// **'Étangs'**
  String get tracePonds;

  /// No description provided for @traceTreatments.
  ///
  /// In fr, this message translates to:
  /// **'Traitements'**
  String get traceTreatments;

  /// No description provided for @traceHarvests.
  ///
  /// In fr, this message translates to:
  /// **'Récoltes'**
  String get traceHarvests;

  /// No description provided for @traceSales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes'**
  String get traceSales;

  /// No description provided for @traceResults.
  ///
  /// In fr, this message translates to:
  /// **'Bilan'**
  String get traceResults;

  /// No description provided for @traceCycleFcr.
  ///
  /// In fr, this message translates to:
  /// **'IC du cycle'**
  String get traceCycleFcr;

  /// No description provided for @traceCycleOngoing.
  ///
  /// In fr, this message translates to:
  /// **'cycle en cours'**
  String get traceCycleOngoing;

  /// No description provided for @traceSurvival.
  ///
  /// In fr, this message translates to:
  /// **'Survie'**
  String get traceSurvival;

  /// No description provided for @traceUnaccounted.
  ///
  /// In fr, this message translates to:
  /// **'Poissons non retrouvés'**
  String get traceUnaccounted;

  /// No description provided for @traceFeed.
  ///
  /// In fr, this message translates to:
  /// **'Aliment donné'**
  String get traceFeed;

  /// No description provided for @traceStocked.
  ///
  /// In fr, this message translates to:
  /// **'Mis en étang'**
  String get traceStocked;

  /// No description provided for @traceHarvested.
  ///
  /// In fr, this message translates to:
  /// **'Récolté'**
  String get traceHarvested;

  /// No description provided for @traceLive.
  ///
  /// In fr, this message translates to:
  /// **'Encore en étang'**
  String get traceLive;

  /// No description provided for @traceAdvisedBy.
  ///
  /// In fr, this message translates to:
  /// **'conseillé par {who}'**
  String traceAdvisedBy(String who);

  /// No description provided for @salesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récoltes et ventes'**
  String get salesTitle;

  /// No description provided for @salesNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucune récolte enregistrée'**
  String get salesNone;

  /// No description provided for @customersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Clients'**
  String get customersTitle;

  /// No description provided for @customerNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau client'**
  String get customerNew;

  /// No description provided for @customerEdit.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get customerEdit;

  /// No description provided for @customerName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get customerName;

  /// No description provided for @customerType.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get customerType;

  /// No description provided for @customerContact.
  ///
  /// In fr, this message translates to:
  /// **'Contact (facultatif)'**
  String get customerContact;

  /// No description provided for @customerArchive.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de la liste'**
  String get customerArchive;

  /// No description provided for @customersNone.
  ///
  /// In fr, this message translates to:
  /// **'Aucun client'**
  String get customersNone;

  /// No description provided for @custMarket.
  ///
  /// In fr, this message translates to:
  /// **'Marché'**
  String get custMarket;

  /// No description provided for @custRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Restaurant'**
  String get custRestaurant;

  /// No description provided for @custSupermarket.
  ///
  /// In fr, this message translates to:
  /// **'Supermarché'**
  String get custSupermarket;

  /// No description provided for @custExporter.
  ///
  /// In fr, this message translates to:
  /// **'Exportateur'**
  String get custExporter;

  /// No description provided for @custIndividual.
  ///
  /// In fr, this message translates to:
  /// **'Particulier'**
  String get custIndividual;

  /// No description provided for @feedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Stock d\'aliment'**
  String get feedTitle;

  /// No description provided for @feedOnHand.
  ///
  /// In fr, this message translates to:
  /// **'En stock'**
  String get feedOnHand;

  /// No description provided for @feedDaysLeft.
  ///
  /// In fr, this message translates to:
  /// **'{days} jours de stock'**
  String feedDaysLeft(String days);

  /// No description provided for @feedNoUsage.
  ///
  /// In fr, this message translates to:
  /// **'Pas de consommation ces derniers jours'**
  String get feedNoUsage;

  /// No description provided for @feedOverdrawn.
  ///
  /// In fr, this message translates to:
  /// **'Plus d\'aliment donné que livré : {kg}'**
  String feedOverdrawn(String kg);

  /// No description provided for @feedExpiredStock.
  ///
  /// In fr, this message translates to:
  /// **'À ne pas utiliser : {kg}'**
  String feedExpiredStock(String kg);

  /// No description provided for @feedNoLots.
  ///
  /// In fr, this message translates to:
  /// **'Aucune livraison enregistrée'**
  String get feedNoLots;

  /// No description provided for @feedLotMade.
  ///
  /// In fr, this message translates to:
  /// **'Fabriqué le {date} · {days} jours'**
  String feedLotMade(String date, String days);

  /// No description provided for @feedLotOld.
  ///
  /// In fr, this message translates to:
  /// **'À utiliser en priorité'**
  String get feedLotOld;

  /// No description provided for @feedLotExpired.
  ///
  /// In fr, this message translates to:
  /// **'À ne pas utiliser'**
  String get feedLotExpired;

  /// No description provided for @feedDeliver.
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get feedDeliver;

  /// No description provided for @feedDeliveryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Livraison d\'aliment'**
  String get feedDeliveryTitle;

  /// No description provided for @feedPhase.
  ///
  /// In fr, this message translates to:
  /// **'Aliment pour'**
  String get feedPhase;

  /// No description provided for @feedWeight.
  ///
  /// In fr, this message translates to:
  /// **'Poids livré'**
  String get feedWeight;

  /// No description provided for @feedMadeOn.
  ///
  /// In fr, this message translates to:
  /// **'Date de fabrication'**
  String get feedMadeOn;

  /// No description provided for @feedDeliveredOn.
  ///
  /// In fr, this message translates to:
  /// **'Date de livraison'**
  String get feedDeliveredOn;

  /// No description provided for @feedPellet.
  ///
  /// In fr, this message translates to:
  /// **'Taille du granulé'**
  String get feedPellet;

  /// No description provided for @feedProtein.
  ///
  /// In fr, this message translates to:
  /// **'Protéines'**
  String get feedProtein;

  /// No description provided for @feedSupplier.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseur'**
  String get feedSupplier;

  /// No description provided for @feedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Marque sur les sacs'**
  String get feedLabel;

  /// No description provided for @feedDiscard.
  ///
  /// In fr, this message translates to:
  /// **'Jeter'**
  String get feedDiscard;

  /// No description provided for @feedDiscardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aliment jeté'**
  String get feedDiscardTitle;

  /// No description provided for @feedDiscardWeight.
  ///
  /// In fr, this message translates to:
  /// **'Poids jeté'**
  String get feedDiscardWeight;

  /// No description provided for @feedDiscardReason.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi'**
  String get feedDiscardReason;

  /// No description provided for @discardMould.
  ///
  /// In fr, this message translates to:
  /// **'Moisi'**
  String get discardMould;

  /// No description provided for @discardRancid.
  ///
  /// In fr, this message translates to:
  /// **'Rance'**
  String get discardRancid;

  /// No description provided for @discardClumped.
  ///
  /// In fr, this message translates to:
  /// **'En grumeaux'**
  String get discardClumped;

  /// No description provided for @discardOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get discardOther;

  /// No description provided for @feedLot.
  ///
  /// In fr, this message translates to:
  /// **'Lot d\'aliment'**
  String get feedLot;

  /// No description provided for @feedLotAuto.
  ///
  /// In fr, this message translates to:
  /// **'Le plus ancien (automatique)'**
  String get feedLotAuto;

  /// No description provided for @alertPrepDry.
  ///
  /// In fr, this message translates to:
  /// **'Séchage fini ? Vérifier les fissures, puis noter l\'assèchement'**
  String get alertPrepDry;

  /// No description provided for @alertPrepRest.
  ///
  /// In fr, this message translates to:
  /// **'Repos fini : l\'étang peut être déclaré prêt'**
  String get alertPrepRest;

  /// No description provided for @prepButton.
  ///
  /// In fr, this message translates to:
  /// **'Préparation'**
  String get prepButton;

  /// No description provided for @prepTitle.
  ///
  /// In fr, this message translates to:
  /// **'Préparation {pond}'**
  String prepTitle(String pond);

  /// No description provided for @prepStepDrain.
  ///
  /// In fr, this message translates to:
  /// **'Vidange et curage'**
  String get prepStepDrain;

  /// No description provided for @prepStepDry.
  ///
  /// In fr, this message translates to:
  /// **'Assèchement au soleil'**
  String get prepStepDry;

  /// No description provided for @prepStepTreat.
  ///
  /// In fr, this message translates to:
  /// **'Traitement (chaux vive ou chlore)'**
  String get prepStepTreat;

  /// No description provided for @prepStepFertilise.
  ///
  /// In fr, this message translates to:
  /// **'Fertilisation (fumier)'**
  String get prepStepFertilise;

  /// No description provided for @prepStepFill.
  ///
  /// In fr, this message translates to:
  /// **'Remplissage par l\'entrée grillagée'**
  String get prepStepFill;

  /// No description provided for @prepStepRest.
  ///
  /// In fr, this message translates to:
  /// **'Repos'**
  String get prepStepRest;

  /// No description provided for @prepDone.
  ///
  /// In fr, this message translates to:
  /// **'Fait'**
  String get prepDone;

  /// No description provided for @prepDoneOn.
  ///
  /// In fr, this message translates to:
  /// **'Fait le {date}'**
  String prepDoneOn(String date);

  /// No description provided for @prepDryUntil.
  ///
  /// In fr, this message translates to:
  /// **'Séchage : du {from} au {to}'**
  String prepDryUntil(String from, String to);

  /// No description provided for @prepRestUntil.
  ///
  /// In fr, this message translates to:
  /// **'Repos jusqu\'au {date}'**
  String prepRestUntil(String date);

  /// No description provided for @prepLimeDose.
  ///
  /// In fr, this message translates to:
  /// **'Chaux vive : {range} pour {surface}'**
  String prepLimeDose(String range, String surface);

  /// No description provided for @prepManureDose.
  ///
  /// In fr, this message translates to:
  /// **'Fumier : {range} pour {surface}'**
  String prepManureDose(String range, String surface);

  /// No description provided for @prepNoSurface.
  ///
  /// In fr, this message translates to:
  /// **'Sans la surface de l\'étang, pas de dose : renseignez sa longueur et sa largeur'**
  String get prepNoSurface;

  /// No description provided for @prepMarkReady.
  ///
  /// In fr, this message translates to:
  /// **'Prêt à empoissonner'**
  String get prepMarkReady;

  /// No description provided for @prepSkipped.
  ///
  /// In fr, this message translates to:
  /// **'Étapes non faites : {steps}'**
  String prepSkipped(String steps);

  /// No description provided for @prepRestShort.
  ///
  /// In fr, this message translates to:
  /// **'Le repos n\'est pas fini (jusqu\'au {date})'**
  String prepRestShort(String date);

  /// No description provided for @prepReadyConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Déclarer l\'étang prêt à empoissonner ?'**
  String get prepReadyConfirm;

  /// No description provided for @prepProductQuicklime.
  ///
  /// In fr, this message translates to:
  /// **'Chaux vive'**
  String get prepProductQuicklime;

  /// No description provided for @prepProductChlorine.
  ///
  /// In fr, this message translates to:
  /// **'Chlore'**
  String get prepProductChlorine;

  /// No description provided for @prepProductManure.
  ///
  /// In fr, this message translates to:
  /// **'Fumier'**
  String get prepProductManure;

  /// No description provided for @prepDoseUsed.
  ///
  /// In fr, this message translates to:
  /// **'Dose utilisée'**
  String get prepDoseUsed;

  /// No description provided for @doneDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get doneDate;

  /// No description provided for @alertDuplicateLog.
  ///
  /// In fr, this message translates to:
  /// **'Deux journaux pour le {date} : choisir lequel garder'**
  String alertDuplicateLog(String date);

  /// No description provided for @duplicateKeep.
  ///
  /// In fr, this message translates to:
  /// **'Garder celui-ci'**
  String get duplicateKeep;

  /// No description provided for @duplicateResolved.
  ///
  /// In fr, this message translates to:
  /// **'Résolu : un seul journal pour ce jour'**
  String get duplicateResolved;

  /// No description provided for @duplicateEnteredBy.
  ///
  /// In fr, this message translates to:
  /// **'Saisi par {name}'**
  String duplicateEnteredBy(String name);

  /// No description provided for @duplicateObservedBy.
  ///
  /// In fr, this message translates to:
  /// **'Vu par {name}'**
  String duplicateObservedBy(String name);

  /// No description provided for @duplicateOtherPhone.
  ///
  /// In fr, this message translates to:
  /// **'un autre téléphone'**
  String get duplicateOtherPhone;

  /// No description provided for @staleRecord.
  ///
  /// In fr, this message translates to:
  /// **'Ce journal a déjà été changé sur un autre téléphone'**
  String get staleRecord;

  /// No description provided for @rationToday.
  ///
  /// In fr, this message translates to:
  /// **'Ration du jour'**
  String get rationToday;

  /// No description provided for @lastWeighed.
  ///
  /// In fr, this message translates to:
  /// **'Dernière pesée : il y a {days} j'**
  String lastWeighed(String days);

  /// No description provided for @notSampledYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore échantillonné, empoissonné il y a {days} j'**
  String notSampledYet(String days);

  /// No description provided for @fcrValue.
  ///
  /// In fr, this message translates to:
  /// **'IC : {value}'**
  String fcrValue(String value);

  /// No description provided for @survivalValue.
  ///
  /// In fr, this message translates to:
  /// **'Survie : {pct} %'**
  String survivalValue(String pct);

  /// No description provided for @chartWeight.
  ///
  /// In fr, this message translates to:
  /// **'Poids moyen (g)'**
  String get chartWeight;

  /// No description provided for @chartDeaths.
  ///
  /// In fr, this message translates to:
  /// **'Morts par jour'**
  String get chartDeaths;

  /// No description provided for @chartFcr.
  ///
  /// In fr, this message translates to:
  /// **'IC par période'**
  String get chartFcr;

  /// No description provided for @chartEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de données'**
  String get chartEmpty;

  /// No description provided for @fcrStalled.
  ///
  /// In fr, this message translates to:
  /// **'pas de croissance'**
  String get fcrStalled;

  /// No description provided for @workerStopFeeding.
  ///
  /// In fr, this message translates to:
  /// **'Ne pas nourrir'**
  String get workerStopFeeding;

  /// No description provided for @workerReasonFast.
  ///
  /// In fr, this message translates to:
  /// **'Récolte bientôt'**
  String get workerReasonFast;

  /// No description provided for @workerReasonOxygen.
  ///
  /// In fr, this message translates to:
  /// **'Manque d\'oxygène'**
  String get workerReasonOxygen;

  /// No description provided for @workerReasonDistress.
  ///
  /// In fr, this message translates to:
  /// **'Poissons stressés'**
  String get workerReasonDistress;

  /// A label and its value on one line; French puts a space before the colon.
  ///
  /// In fr, this message translates to:
  /// **'{label} : {value}'**
  String labelValue(String label, String value);

  /// A label followed by a value shown in its own widget.
  ///
  /// In fr, this message translates to:
  /// **'{label} :'**
  String labelColon(String label);

  /// No description provided for @tabReports.
  ///
  /// In fr, this message translates to:
  /// **'Rapports'**
  String get tabReports;

  /// No description provided for @reportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rapport de visite'**
  String get reportTitle;

  /// No description provided for @reportsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun rapport pour l\'instant'**
  String get reportsEmpty;

  /// No description provided for @reportDraft.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon — à publier'**
  String get reportDraft;

  /// No description provided for @reportPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get reportPublish;

  /// No description provided for @reportShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get reportShare;

  /// No description provided for @reportCardTitle.
  ///
  /// In fr, this message translates to:
  /// **'{date} · {member}'**
  String reportCardTitle(String date, String member);

  /// No description provided for @reportPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Du {from} au {to}'**
  String reportPeriod(String from, String to);

  /// No description provided for @reportAuthor.
  ///
  /// In fr, this message translates to:
  /// **'Par {member}'**
  String reportAuthor(String member);

  /// No description provided for @reportAuthorGroup.
  ///
  /// In fr, this message translates to:
  /// **'Par {member} ({group})'**
  String reportAuthorGroup(String member, String group);

  /// No description provided for @reportPublishedOn.
  ///
  /// In fr, this message translates to:
  /// **'Publié le {date}'**
  String reportPublishedOn(String date);

  /// No description provided for @reportUpdateApp.
  ///
  /// In fr, this message translates to:
  /// **'Mettez l\'application à jour pour lire ce rapport.'**
  String get reportUpdateApp;

  /// No description provided for @reportSummary.
  ///
  /// In fr, this message translates to:
  /// **'Résumé'**
  String get reportSummary;

  /// No description provided for @reportAlerts.
  ///
  /// In fr, this message translates to:
  /// **'Alertes'**
  String get reportAlerts;

  /// No description provided for @reportHealth.
  ///
  /// In fr, this message translates to:
  /// **'Santé'**
  String get reportHealth;

  /// No description provided for @reportWater.
  ///
  /// In fr, this message translates to:
  /// **'Eau'**
  String get reportWater;

  /// No description provided for @reportGrowth.
  ///
  /// In fr, this message translates to:
  /// **'Croissance'**
  String get reportGrowth;

  /// No description provided for @reportFeed.
  ///
  /// In fr, this message translates to:
  /// **'Aliment'**
  String get reportFeed;

  /// No description provided for @reportNext.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get reportNext;

  /// No description provided for @reportObservations.
  ///
  /// In fr, this message translates to:
  /// **'Observations et photos'**
  String get reportObservations;

  /// No description provided for @reportNothing.
  ///
  /// In fr, this message translates to:
  /// **'Rien à signaler'**
  String get reportNothing;

  /// No description provided for @reportNoSummary.
  ///
  /// In fr, this message translates to:
  /// **'Pas de résumé'**
  String get reportNoSummary;

  /// No description provided for @reportNoReading.
  ///
  /// In fr, this message translates to:
  /// **'Aucun relevé'**
  String get reportNoReading;

  /// No description provided for @reportNoFish.
  ///
  /// In fr, this message translates to:
  /// **'Aucun poisson en étang'**
  String get reportNoFish;

  /// No description provided for @reportNoFeed.
  ///
  /// In fr, this message translates to:
  /// **'Aucun aliment noté sur la période'**
  String get reportNoFeed;

  /// No description provided for @reportFeedStockLater.
  ///
  /// In fr, this message translates to:
  /// **'Stock d\'aliment : non suivi (aucune livraison enregistrée)'**
  String get reportFeedStockLater;

  /// No description provided for @reportFeedOnHand.
  ///
  /// In fr, this message translates to:
  /// **'En stock : {kg}, {days} jours de stock'**
  String reportFeedOnHand(String kg, String days);

  /// No description provided for @reportFeedOnHandNoUsage.
  ///
  /// In fr, this message translates to:
  /// **'En stock : {kg}'**
  String reportFeedOnHandNoUsage(String kg);

  /// No description provided for @reportFeedLot.
  ///
  /// In fr, this message translates to:
  /// **'{lot} · {kg} · fabriqué le {date}'**
  String reportFeedLot(String lot, String kg, String date);

  /// No description provided for @reportNextDry.
  ///
  /// In fr, this message translates to:
  /// **'Séchage de {pond} fini ?'**
  String reportNextDry(String pond);

  /// No description provided for @reportNextRest.
  ///
  /// In fr, this message translates to:
  /// **'Repos de {pond} fini : prêt à empoissonner'**
  String reportNextRest(String pond);

  /// No description provided for @reportDeaths.
  ///
  /// In fr, this message translates to:
  /// **'{count} morts'**
  String reportDeaths(String count);

  /// No description provided for @reportObserverDeaths.
  ///
  /// In fr, this message translates to:
  /// **'{name} {count}'**
  String reportObserverDeaths(String name, String count);

  /// No description provided for @reportListSeparator.
  ///
  /// In fr, this message translates to:
  /// **' · '**
  String get reportListSeparator;

  /// No description provided for @reportUnknownPerson.
  ///
  /// In fr, this message translates to:
  /// **'inconnu'**
  String get reportUnknownPerson;

  /// No description provided for @reportSigns.
  ///
  /// In fr, this message translates to:
  /// **'{date} : {signs}'**
  String reportSigns(String date, String signs);

  /// No description provided for @reportTreatmentLine.
  ///
  /// In fr, this message translates to:
  /// **'{date} : {product}, {dose}'**
  String reportTreatmentLine(String date, String product, String dose);

  /// No description provided for @reportHealthEventLine.
  ///
  /// In fr, this message translates to:
  /// **'{date} : {details}'**
  String reportHealthEventLine(String date, String details);

  /// No description provided for @reportReadingOn.
  ///
  /// In fr, this message translates to:
  /// **'Relevé du {date}'**
  String reportReadingOn(String date);

  /// No description provided for @reportGrowthLine.
  ///
  /// In fr, this message translates to:
  /// **'{batch} · {weight} (pesé le {date})'**
  String reportGrowthLine(String batch, String weight, String date);

  /// No description provided for @reportBiomass.
  ///
  /// In fr, this message translates to:
  /// **'Biomasse'**
  String get reportBiomass;

  /// No description provided for @reportFish.
  ///
  /// In fr, this message translates to:
  /// **'Poissons'**
  String get reportFish;

  /// No description provided for @reportFcrShared.
  ///
  /// In fr, this message translates to:
  /// **'bassin partagé'**
  String get reportFcrShared;

  /// No description provided for @reportFcrNoSample.
  ///
  /// In fr, this message translates to:
  /// **'pas encore pesé'**
  String get reportFcrNoSample;

  /// No description provided for @reportTrendWorse.
  ///
  /// In fr, this message translates to:
  /// **'en hausse'**
  String get reportTrendWorse;

  /// No description provided for @reportTrendBetter.
  ///
  /// In fr, this message translates to:
  /// **'en baisse'**
  String get reportTrendBetter;

  /// No description provided for @reportTrendSame.
  ///
  /// In fr, this message translates to:
  /// **'stable'**
  String get reportTrendSame;

  /// No description provided for @reportFeedTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get reportFeedTotal;

  /// No description provided for @reportNextSample.
  ///
  /// In fr, this message translates to:
  /// **'Pesée de {batch}'**
  String reportNextSample(String batch);

  /// No description provided for @reportNextHarvest.
  ///
  /// In fr, this message translates to:
  /// **'Récolte de {batch}'**
  String reportNextHarvest(String batch);

  /// No description provided for @reportNextQuarantine.
  ///
  /// In fr, this message translates to:
  /// **'Fin de quarantaine de {batch}'**
  String reportNextQuarantine(String batch);

  /// No description provided for @reportAllOk.
  ///
  /// In fr, this message translates to:
  /// **'En ordre : {items}'**
  String reportAllOk(String items);

  /// No description provided for @photoAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get photoAdd;

  /// No description provided for @photoUpload.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer au serveur'**
  String get photoUpload;

  /// No description provided for @photoDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la photo'**
  String get photoDelete;

  /// No description provided for @photoFailed.
  ///
  /// In fr, this message translates to:
  /// **'La photo n\'a pas pu être prise. L\'enregistrement se fait sans elle.'**
  String get photoFailed;

  /// No description provided for @photoUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Photo pas encore disponible'**
  String get photoUnavailable;

  /// No description provided for @syncPhotosWaiting.
  ///
  /// In fr, this message translates to:
  /// **'Photos en attente d\'envoi : {count}'**
  String syncPhotosWaiting(int count);

  /// No description provided for @syncPhotoCap.
  ///
  /// In fr, this message translates to:
  /// **'Limite de photos atteinte : un administrateur peut la relever dans Réglages.'**
  String get syncPhotoCap;

  /// No description provided for @settingsPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Photos'**
  String get settingsPhotos;

  /// No description provided for @settingPhotoUploadCap.
  ///
  /// In fr, this message translates to:
  /// **'Photos envoyées au serveur, au plus'**
  String get settingPhotoUploadCap;

  /// No description provided for @photoDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette photo ? Elle sera effacée de ce téléphone.'**
  String get photoDeleteConfirm;

  /// No description provided for @paperTitle.
  ///
  /// In fr, this message translates to:
  /// **'Fiche journalière'**
  String get paperTitle;

  /// No description provided for @paperWeek.
  ///
  /// In fr, this message translates to:
  /// **'Semaine du {from} au {to}'**
  String paperWeek(String from, String to);

  /// No description provided for @paperWorker.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrier'**
  String get paperWorker;

  /// No description provided for @paperFeedKg.
  ///
  /// In fr, this message translates to:
  /// **'Aliment (kg)'**
  String get paperFeedKg;

  /// No description provided for @paperDay.
  ///
  /// In fr, this message translates to:
  /// **'Jour'**
  String get paperDay;

  /// No description provided for @paperHowTo.
  ///
  /// In fr, this message translates to:
  /// **'Cochez la case de ce que vous voyez.'**
  String get paperHowTo;

  /// No description provided for @paperNoPonds.
  ///
  /// In fr, this message translates to:
  /// **'Aucun étang actif.'**
  String get paperNoPonds;

  /// No description provided for @weekdayMon.
  ///
  /// In fr, this message translates to:
  /// **'lun.'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In fr, this message translates to:
  /// **'mar.'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In fr, this message translates to:
  /// **'mer.'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In fr, this message translates to:
  /// **'jeu.'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In fr, this message translates to:
  /// **'ven.'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In fr, this message translates to:
  /// **'sam.'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In fr, this message translates to:
  /// **'dim.'**
  String get weekdaySun;

  /// No description provided for @morePaper.
  ///
  /// In fr, this message translates to:
  /// **'Fiches papier'**
  String get morePaper;

  /// No description provided for @paperWeeksLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de semaines'**
  String get paperWeeksLabel;

  /// No description provided for @paperPondsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Étangs'**
  String get paperPondsLabel;

  /// No description provided for @paperPrint.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer'**
  String get paperPrint;

  /// No description provided for @paperShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager le PDF'**
  String get paperShare;

  /// No description provided for @transcriptionCellDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails du jour'**
  String get transcriptionCellDetails;

  /// No description provided for @exportRegisterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Registre de production'**
  String get exportRegisterTitle;

  /// No description provided for @exportWeeklyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Fiche de suivi hebdomadaire'**
  String get exportWeeklyTitle;

  /// No description provided for @exportPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Du {from} au {to}'**
  String exportPeriod(String from, String to);

  /// No description provided for @exportColDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get exportColDate;

  /// No description provided for @exportColPondBatch.
  ///
  /// In fr, this message translates to:
  /// **'Étang / Lot'**
  String get exportColPondBatch;

  /// No description provided for @exportColOrigin.
  ///
  /// In fr, this message translates to:
  /// **'Provenance alevins'**
  String get exportColOrigin;

  /// No description provided for @exportColFeedKg.
  ///
  /// In fr, this message translates to:
  /// **'Quantité aliment (kg)'**
  String get exportColFeedKg;

  /// No description provided for @exportColDeaths.
  ///
  /// In fr, this message translates to:
  /// **'Mortalité (nb)'**
  String get exportColDeaths;

  /// No description provided for @exportColSalesKg.
  ///
  /// In fr, this message translates to:
  /// **'Ventes (kg)'**
  String get exportColSalesKg;

  /// No description provided for @exportColObservations.
  ///
  /// In fr, this message translates to:
  /// **'Observations'**
  String get exportColObservations;

  /// No description provided for @exportColPond.
  ///
  /// In fr, this message translates to:
  /// **'Étang'**
  String get exportColPond;

  /// No description provided for @exportColWeekOf.
  ///
  /// In fr, this message translates to:
  /// **'Semaine du'**
  String get exportColWeekOf;

  /// No description provided for @exportColTemp.
  ///
  /// In fr, this message translates to:
  /// **'Temp. (°C)'**
  String get exportColTemp;

  /// No description provided for @exportColPh.
  ///
  /// In fr, this message translates to:
  /// **'pH'**
  String get exportColPh;

  /// No description provided for @exportColOxygen.
  ///
  /// In fr, this message translates to:
  /// **'Oxygène (mg/L)'**
  String get exportColOxygen;

  /// No description provided for @exportColFeedGivenKg.
  ///
  /// In fr, this message translates to:
  /// **'Aliment distribué (kg)'**
  String get exportColFeedGivenKg;

  /// No description provided for @exportColAvgWeight.
  ///
  /// In fr, this message translates to:
  /// **'Poids moyen échantillon (g)'**
  String get exportColAvgWeight;

  /// No description provided for @exportFishCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} poissons'**
  String exportFishCount(String count);

  /// No description provided for @exportTreatment.
  ///
  /// In fr, this message translates to:
  /// **'Traitement'**
  String get exportTreatment;

  /// No description provided for @exportHealth.
  ///
  /// In fr, this message translates to:
  /// **'Problème signalé'**
  String get exportHealth;

  /// No description provided for @exportThresholds.
  ///
  /// In fr, this message translates to:
  /// **'Seuils : température {temp} °C · pH {ph} · oxygène ≥ {oxygen} mg/L · renouvellement d\'eau {renewal} % par semaine si l\'eau devient trouble.'**
  String exportThresholds(
    String temp,
    String ph,
    String oxygen,
    String renewal,
  );

  /// No description provided for @moreExports.
  ///
  /// In fr, this message translates to:
  /// **'Exports'**
  String get moreExports;

  /// No description provided for @exportKindRegister.
  ///
  /// In fr, this message translates to:
  /// **'Registre de production (annexe A)'**
  String get exportKindRegister;

  /// No description provided for @exportKindWeekly.
  ///
  /// In fr, this message translates to:
  /// **'Suivi hebdomadaire (annexe B)'**
  String get exportKindWeekly;

  /// No description provided for @exportFrom.
  ///
  /// In fr, this message translates to:
  /// **'Du'**
  String get exportFrom;

  /// No description provided for @exportTo.
  ///
  /// In fr, this message translates to:
  /// **'Au'**
  String get exportTo;

  /// No description provided for @exportPond.
  ///
  /// In fr, this message translates to:
  /// **'Étang'**
  String get exportPond;

  /// No description provided for @exportAllPonds.
  ///
  /// In fr, this message translates to:
  /// **'Tous les étangs'**
  String get exportAllPonds;

  /// No description provided for @exportPdf.
  ///
  /// In fr, this message translates to:
  /// **'PDF'**
  String get exportPdf;

  /// No description provided for @exportCsv.
  ///
  /// In fr, this message translates to:
  /// **'CSV'**
  String get exportCsv;

  /// No description provided for @exportEndBeforeStart.
  ///
  /// In fr, this message translates to:
  /// **'La date de fin est avant la date de début.'**
  String get exportEndBeforeStart;

  /// No description provided for @exportWeeklyWholeWeeks.
  ///
  /// In fr, this message translates to:
  /// **'Semaines entières, du lundi au dimanche.'**
  String get exportWeeklyWholeWeeks;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @exportBuilding.
  ///
  /// In fr, this message translates to:
  /// **'Préparation du fichier…'**
  String get exportBuilding;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fr', 'mg'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppLocalizationsFr();
    case 'mg':
      return AppLocalizationsMg();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
