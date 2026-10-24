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
