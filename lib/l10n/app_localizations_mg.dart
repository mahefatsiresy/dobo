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
  String get setupTitle => 'Fametrahana';

  @override
  String get setupSiteName => 'Anaran\'ny toerana';

  @override
  String get setupLocationNote => 'Toerana (tsy voatery)';

  @override
  String get setupStart => 'Hanomboka';

  @override
  String get tabPonds => 'Dobo';

  @override
  String get tabMore => 'Hafa';

  @override
  String get fieldRequired => 'Ilaina';

  @override
  String get estimated => 'tombana';

  @override
  String get pondStatusEmpty => 'Foana';

  @override
  String get pondStatusPreparing => 'Am-panomanana';

  @override
  String get pondStatusReady => 'Vonona';

  @override
  String get pondStatusStocked => 'Misy trondro';

  @override
  String get pondStatusIsolated => 'Natokana';

  @override
  String get structureEarth => 'Dobo tany';

  @override
  String get structureTank => 'Fitoeran-drano';

  @override
  String get structureCage => 'Tranom-trondro mitsinkafona';

  @override
  String get roleBreeding => 'Fiterahana';

  @override
  String get roleNursery => 'Fitaizana zana-trondro';

  @override
  String get rolePregrow => 'Fampitomboana voalohany';

  @override
  String get roleGrowout => 'Fampitomboana';

  @override
  String get roleHolding => 'Fitehirizana alohan\'ny fivarotana';

  @override
  String get roleQuarantine => 'Fitokanana';

  @override
  String get supplyBarrage => 'Tohodrano';

  @override
  String get supplyDerivation => 'Lakandrano mivily';

  @override
  String get supplyMarsh => 'Honahona';

  @override
  String get colourBlue => 'Manga';

  @override
  String get colourGreen => 'Maitso';

  @override
  String get colourYellow => 'Mavo';

  @override
  String get colourOrange => 'Volomboasary';

  @override
  String get colourRed => 'Mena';

  @override
  String get colourPurple => 'Volomparasy';

  @override
  String get colourBrown => 'Volontany';

  @override
  String get colourBlack => 'Mainty';

  @override
  String get batchStatusQuarantine => 'Fitokanana';

  @override
  String get batchStatusActive => 'Mandeha';

  @override
  String get batchStatusHarvesting => 'Am-pijonoana';

  @override
  String get batchStatusClosed => 'Vita';

  @override
  String get phaseFry => 'Zana-trondro';

  @override
  String get phasePregrow => 'Fampitomboana voalohany';

  @override
  String get phaseGrowout => 'Fampitomboana';

  @override
  String get phaseFinishing => 'Famaranana';

  @override
  String get densityBelow => 'Vitsy loatra ny trondro';

  @override
  String get densityWithin => 'Ampy tsara ny trondro';

  @override
  String get densityAbove => 'Be loatra ny trondro';

  @override
  String warnSurfaceTooSmall(String min, String max) {
    return 'Velarana latsaky ny $min m² (soso-kevitra : $min ka hatramin\'ny $max m²)';
  }

  @override
  String warnSurfaceTooLarge(String min, String max) {
    return 'Velarana mihoatra ny $max m² (soso-kevitra : $min ka hatramin\'ny $max m²)';
  }

  @override
  String warnNotElongated(String min, String max) {
    return 'Tsy dia lava ny dobo (soso-kevitra : lava $min ka hatramin\'ny $max heny noho ny sakany)';
  }

  @override
  String warnTooElongated(String min, String max) {
    return 'Lava loatra ny dobo (soso-kevitra : lava $min ka hatramin\'ny $max heny noho ny sakany)';
  }

  @override
  String warnTooShallow(String min) {
    return 'Halalina salanisa latsaky ny $min m';
  }

  @override
  String get morePeople => 'Olona';

  @override
  String get moreBatches => 'Andiany';

  @override
  String get personName => 'Anarana';

  @override
  String get personPhone => 'Finday';

  @override
  String get personNote => 'Fanamarihana';

  @override
  String get personActive => 'Mavitrika';

  @override
  String personOfMember(String name) {
    return '$name (mpikambana)';
  }

  @override
  String personOfWorker(String name) {
    return '$name (mpiasa)';
  }

  @override
  String get personRenameFromAdmin =>
      'Ovay ny anarana ao amin\'ny Admin › Mpikambana';

  @override
  String get personInactive => 'Tsy mavitrika';

  @override
  String get save => 'Tehirizo';

  @override
  String get add => 'Ampio';

  @override
  String get peopleEmpty => 'Tsy misy olona : ampio ny mpiasa sy ny mpikambana';

  @override
  String get pondAdd => 'Hanampy dobo';

  @override
  String get pondsEmpty => 'Tsy misy dobo : ampio ny voalohany';

  @override
  String get pondCode => 'Kaody';

  @override
  String get pondColourLabel => 'Loko';

  @override
  String get pondStructure => 'Karazana';

  @override
  String get pondRoleLabel => 'Anjara asa';

  @override
  String get pondWaterSupply => 'Loharano';

  @override
  String get notSpecified => 'Tsy voalaza';

  @override
  String get pondLength => 'Halavany';

  @override
  String get pondWidth => 'Sakany';

  @override
  String get pondSurfaceOverride => 'Velarana norefesina (tsy voatery)';

  @override
  String get pondDepthInlet => 'Halalina eo am-pidirana';

  @override
  String get pondDepthOutlet => 'Halalina eo am-pivoahana';

  @override
  String get pondStatusLabel => 'Toetra';

  @override
  String get duplicateCode => 'Efa misy io kaody io';

  @override
  String get pondFish => 'Trondro';

  @override
  String get pondBiomass => 'Lanjan\'ny trondro rehetra';

  @override
  String get pondDensity => 'Hakitroky';

  @override
  String get pondSurface => 'Velarana';

  @override
  String get inconsistent => 'Hamarinina';

  @override
  String get pondStock => 'Hametraka trondro';

  @override
  String get pondTransfer => 'Hamindra';

  @override
  String get edit => 'Ovaina';

  @override
  String get archive => 'Arahina';

  @override
  String get cancel => 'Aoka ihany';

  @override
  String get avgWeight => 'Lanja salanisa';

  @override
  String get pondNoFish => 'Tsy misy trondro';

  @override
  String get adultFeed => 'sakafon\'ny lehibe';

  @override
  String pondSurfaceComputed(String surface) {
    return 'Velarana voakajy : $surface';
  }

  @override
  String densityValue(String density) {
    return '$density /m²';
  }

  @override
  String archiveConfirm(String code) {
    return 'Harahina ve ny dobo $code ? Tsy hiseho amin\'ny lisitra intsony izy.';
  }

  @override
  String feedingGuide(String protein, String pellet, String meals) {
    return 'Sakafo : proteinina $protein, voany $pellet, in-$meals isan\'andro';
  }

  @override
  String get stockTitle => 'Hametraka trondro';

  @override
  String get batchCode => 'Kaodin\'ny andiany';

  @override
  String get stockDate => 'Daty nametrahana';

  @override
  String get stockCount => 'Isan\'ny zana-trondro';

  @override
  String get strain => 'Karazany (oh. GIFT)';

  @override
  String get hatchery => 'Toeram-pamokarana zana-trondro';

  @override
  String get certificate => 'Laharan\'ny taratasy fahasalamana';

  @override
  String get monosex => 'Lahy avokoa';

  @override
  String get yes => 'Eny';

  @override
  String get no => 'Tsia';

  @override
  String get unknown => 'Tsy fantatra';

  @override
  String get plannedHarvest => 'Fijonoana kasaina (tsy voatery)';

  @override
  String get pickPond => 'Dobo';

  @override
  String get warnPondIsolated => 'Dobo natokana : aleo halaviriana';

  @override
  String get warnDensityBelow =>
      'Ambany noho ny farany ambany soso-kevitra ny hakitroky';

  @override
  String get warnDensityAbove =>
      'Ambony noho ny farany ambony soso-kevitra ny hakitroky';

  @override
  String get batchesEmpty =>
      'Tsy misy andiany : mametraha trondro amin\'ny pejin\'ny dobo iray';

  @override
  String get history => 'Tantara';

  @override
  String get eventStocking => 'Fametrahana trondro';

  @override
  String get eventTransfer => 'Famindrana';

  @override
  String get correct => 'Hanitsy';

  @override
  String get delete => 'Fafana';

  @override
  String get deleteConfirm => 'Hofafana ve ity firaketana ity ?';

  @override
  String get fishPerPond => 'Trondro isaky ny dobo';

  @override
  String get batchEdit => 'Hanova ny andiany';

  @override
  String get correctionTitle => 'Hanitsy';

  @override
  String acclimatised(String min, String max) {
    return 'Nampahazatra $min ka hatramin\'ny $max min';
  }

  @override
  String acclimatiseReminder(String min, String max) {
    return 'Avelao hitsinkafona eo ambonin\'ny dobo mandritra ny $min ka hatramin\'ny $max min ny kitapo mihidy alohan\'ny handefasana ny zana-trondro.';
  }

  @override
  String densityResult(String density, String min, String max) {
    return 'Hakitroky aorian\'ny fametrahana : $density /m² (soso-kevitra : $min ka hatramin\'ny $max)';
  }

  @override
  String warnPondNotReady(String status) {
    return 'Tsy voamarika ho vonona ny dobo ($status)';
  }

  @override
  String warnWeightOutsideRange(String min, String max) {
    return 'Lanja salanisa ivelan\'ny $min ka hatramin\'ny $max g soso-kevitra';
  }

  @override
  String stockedOn(String date) {
    return 'Napetraka tamin\'ny $date';
  }

  @override
  String initialStock(String count, String weight, String date) {
    return 'Fanombohana : zana-trondro $count mavesatra $weight, tamin\'ny $date';
  }

  @override
  String plannedHarvestOn(String date) {
    return 'Fijonoana kasaina amin\'ny $date';
  }

  @override
  String get toPond => 'Mankany amin\'ny dobo';

  @override
  String get transferCount => 'Isan\'ny trondro';

  @override
  String get transferDate => 'Daty namindrana';

  @override
  String get avgWeightOptional => 'Lanja salanisa (tsy voatery)';

  @override
  String get warnDestIsolated => 'Natokana ny dobo halehana';

  @override
  String get isolatedSource =>
      'Dobo natokana : tsy tokony hisy trondro hivoaka';

  @override
  String transferTitle(String code, String pond) {
    return 'Hamindra $code avy amin\'ny $pond';
  }

  @override
  String estimateIn(String count, String pond) {
    return '≈ $count ao amin\'ny $pond';
  }

  @override
  String warnAboveEstimate(String count) {
    return 'Mihoatra ny tombana ($count)';
  }

  @override
  String destDensity(String pond, String density, String min, String max) {
    return 'Hakitroky ao amin\'ny $pond aorian\'ny famindrana : $density /m² (soso-kevitra : $min ka hatramin\'ny $max)';
  }

  @override
  String get pondNotEmpty =>
      'Mbola misy trondro ity dobo ity : afindrao aloha izy ireo.';

  @override
  String get signNoAppetite => 'Tsy mihinana';

  @override
  String get signSurfaceSwimming => 'Milomano ambony';

  @override
  String get signNearBanks => 'Eny amoron-drano';

  @override
  String get signErraticOrCircling => 'Mihodinkodina';

  @override
  String get signAbnormalColour => 'Loko hafahafa';

  @override
  String get signSkinLesions => 'Ratra amin\'ny hoditra';

  @override
  String get signPaleOrSwollenGills => 'Mivonto na hatsatra ny akorandoha';

  @override
  String get signGroupedDeaths => 'Maty maromaro';

  @override
  String get signRubbing => 'Mikosokosoka';

  @override
  String get signExcessMucus => 'Be lalotra';

  @override
  String get signWhiteSpots => 'Teboka fotsy';

  @override
  String get signBulgingEyes => 'Maso mivonto';

  @override
  String get signFinBleeding => 'Elatra mandeha ra';

  @override
  String get leftoverNone => 'Lany daholo';

  @override
  String get leftoverSome => 'Misy sisa kely';

  @override
  String get leftoverLots => 'Be sisa';

  @override
  String get ateFast => 'Lany haingana';

  @override
  String get waterClear => 'Mangarahara';

  @override
  String get waterLightGreen => 'Maitso mavana';

  @override
  String get waterMediumGreen => 'Maitso';

  @override
  String get waterDarkGreen => 'Maitso matroka';

  @override
  String get waterBrownTurbid => 'Volontany, manjavozavo';

  @override
  String get obsDike => 'Fefiloha';

  @override
  String get obsInletScreen => 'Harato eo am-pidirana';

  @override
  String get obsPredatorNets => 'Harato fiarovana amin\'ny mpihaza';

  @override
  String get obsFence => 'Fefy';

  @override
  String get obsGrass => 'Ahitra';

  @override
  String get obsPredators => 'Mpihaza';

  @override
  String get obsTheft => 'Halatra';

  @override
  String get obsOther => 'Hafa';

  @override
  String get workerMode => 'Fomba fiasan\'ny mpiasa';

  @override
  String get workerToday => 'Androany';

  @override
  String get workerExit => 'Hiala';

  @override
  String get dailyLog => 'Diarin\'ny andro';

  @override
  String get feedGiven => 'Sakafo nomena';

  @override
  String get feedings => 'Impiry nanome sakafo';

  @override
  String get leftovers => 'Sisa';

  @override
  String get deaths => 'Maty';

  @override
  String get deathAppearance => 'Endriky ny maty';

  @override
  String get signsSeen => 'Famantarana';

  @override
  String get waterColourLabel => 'Loko ny rano';

  @override
  String get addNote => 'Fanamarihana';

  @override
  String get noteLabel => 'Fanamarihana';

  @override
  String get saved => 'Voatahiry';

  @override
  String get pondIsolatedBanner => 'Dobo mitokana';

  @override
  String rationHint(String amount) {
    return '≈ $amount';
  }

  @override
  String get waterReading => 'Fandrefesana rano';

  @override
  String get sampling => 'Fandanjana santionany';

  @override
  String get temperature => 'Hafanana';

  @override
  String get ph => 'pH';

  @override
  String get oxygen => 'Oksizena levona';

  @override
  String get renewedPct => 'Rano novaina';

  @override
  String get readingTime => 'Ora nandrefesana';

  @override
  String get sampleFish => 'Trondro nolanjaina';

  @override
  String get sampleWeight => 'Lanja iraisana';

  @override
  String get sampleDate => 'Daty nandanjana';

  @override
  String get renewWater => 'Loko : ovay ny rano';

  @override
  String targetRange(String min, String max, String unit) {
    return 'tanjona $min ka hatramin\'ny $max $unit';
  }

  @override
  String targetMin(String min, String unit) {
    return 'tanjona $min $unit na mihoatra';
  }

  @override
  String lastReading(String date) {
    return 'Fandrefesana farany, tamin\'ny $date :';
  }

  @override
  String smallSample(String min) {
    return 'Santionany kely (latsaky ny trondro $min)';
  }

  @override
  String sampleAverage(String weight) {
    return 'Lanja salanisa : $weight';
  }

  @override
  String get transcription => 'Fandikana ny taratasy';

  @override
  String get sheetOf => 'Taratasin\'i';

  @override
  String get previousWeek => 'Herinandro teo aloha';

  @override
  String get nextWeek => 'Herinandro manaraka';

  @override
  String get feedMissing =>
      'Asio ny sakafo isaky ny efajoro feno (0 raha tsy nisy nomena).';

  @override
  String weekOfLabel(String date) {
    return 'Herinandro manomboka ny $date';
  }

  @override
  String get reportProblem => 'Hilaza olana';

  @override
  String get suspectedIssue => 'Olana ahiana (tsy voatery)';

  @override
  String get isolatePond => 'Hanokana ny dobo';

  @override
  String get technicianCalled =>
      'Nantsoina ny teknisianina na ny dokotera biby';

  @override
  String get healthResponse =>
      'Atokàny ny dobo, aza mamindra trondro na rano mankany amin\'ny dobo hafa, antsoy ny teknisianina na ny dokotera biby alohan\'ny fitsaboana rehetra.';

  @override
  String get healthInfoTitle => 'Fampahalalana, tsy fitiliana';

  @override
  String get diseaseStrepto => 'Streptococcose';

  @override
  String get diseaseStreptoSigns =>
      'milomano tsy milamina, maso mivonto, maty haingana ; mahalala azy ny hakitroky be sy ny hafanana.';

  @override
  String get diseaseAeromonas => 'Aeromonas';

  @override
  String get diseaseAeromonasSigns =>
      'fery amin\'ny hoditra, elatra mandeha ra ; avy amin\'ny rano ratsy na ratra noho ny fikarakarana.';

  @override
  String get diseaseParasites => 'Katsentsitra ivelany (Trichodina, Ich)';

  @override
  String get diseaseParasitesSigns =>
      'mikosokosoka amin\'ny rindrina na ny fanambany, be lalotra, teboka fotsy.';

  @override
  String get releaseIsolation => 'Hanaisotra ny fitokanana';

  @override
  String get treatment => 'Fitsaboana';

  @override
  String get product => 'Vokatra';

  @override
  String get dose => 'Fatra';

  @override
  String get advisedBy => 'Nanoro hevitra';

  @override
  String get treatmentDate => 'Daty nitsaboana';

  @override
  String get healthHistory => 'Fahasalamana';

  @override
  String get actionIsolated => 'natokana';

  @override
  String get actionTechnician => 'nantsoina ny teknisianina';

  @override
  String get actionReleased => 'nesorina ny fitokanana';

  @override
  String get batchOptional => 'Andiany (tsy voatery)';

  @override
  String releaseConfirm(String code) {
    return 'Hesorina ve ny fitokanana an\'i $code ? Afaka hivoaka indray ny trondro.';
  }

  @override
  String get tabVisit => 'Fitsidihana';

  @override
  String get startVisit => 'Hanomboka fitsidihana';

  @override
  String get sectionWater => 'Rano';

  @override
  String get sectionSamples => 'Santionany';

  @override
  String get sectionConditions => 'Toetry ny dobo';

  @override
  String get sectionBiosecurity => 'Fiarovana ara-pahasalamana';

  @override
  String get sectionObservations => 'Fanamarihana';

  @override
  String get summary => 'Famintinana';

  @override
  String get allDone => 'Vita daholo';

  @override
  String get endVisit => 'Hamarana ny fitsidihana';

  @override
  String get endVisitConfirm =>
      'Hamarana ny fitsidihana ve ? Ny tatitra dia homanina avy amin\'izay voasoratra.';

  @override
  String get visitEnded => 'vita';

  @override
  String get visitOngoing => 'mbola mandeha';

  @override
  String get addObservation => 'Hanampy fanamarihana';

  @override
  String get observationText => 'Fanamarihana';

  @override
  String get category => 'Sokajy';

  @override
  String get conditionOk => 'Tsara';

  @override
  String get conditionProblem => 'Olana';

  @override
  String get pastVisits => 'Fitsidihana teo aloha';

  @override
  String get noVisits => 'Mbola tsy misy fitsidihana';

  @override
  String get bioDisinfect =>
      'Harato, siny ary harato kely voadio isaky ny dobo (klôro voaharoharo, avy eo sasana)';

  @override
  String get bioToolsPerPond =>
      'Fitaovana iray andiany isaky ny dobo raha azo atao';

  @override
  String get bioFootbath => 'Fanasana tongotra na baoty madio eo am-pidirana';

  @override
  String get bioAnimals => 'Gana sy biby hafa ampitaina lavitra';

  @override
  String get bioPredators =>
      'Harato fiarovana amin\'ny mpihaza sy fefy kely voapetraka';

  @override
  String get bioProtection =>
      'Fonon-tanana sy baoty ho an\'ny sokay sy ny klôro';

  @override
  String get bioNotAlone =>
      'Tsy misy miasa irery mandritra ny fanariana rano na jono lehibe';

  @override
  String visitOpenSince(String time) {
    return 'Fitsidihana mandeha nanomboka tamin\'ny $time';
  }

  @override
  String sampleOfIn(String batch, String pond) {
    return '$batch ao amin\'ny $pond';
  }

  @override
  String conditionsOf(String pond) {
    return 'Toetry ny $pond';
  }

  @override
  String visitLine(String date, String state) {
    return '$date · $state';
  }

  @override
  String get welcomeTitle => 'Tongasoa';

  @override
  String get welcomeMember => 'Hiditra (mpikambana)';

  @override
  String get welcomeWorker => 'Mpiasa aho';

  @override
  String get loginTitle => 'Fidirana';

  @override
  String get loginEmail => 'Adiresy mailaka';

  @override
  String get loginPassword => 'Teny miafina';

  @override
  String get loginUsername => 'Anarana fidirana';

  @override
  String get loginPin => 'Kaody PIN (isa 6)';

  @override
  String get loginSubmit => 'Hiditra';

  @override
  String get errorOffline => 'Mila tambajotra';

  @override
  String get errorBadLogin => 'Diso ny anarana na ny teny miafina';

  @override
  String get errorOtherAssociation =>
      'Misy angon\'ny fikambanana hafa ato amin\'ity telefaonina ity. Ataovy aloha ny tahiry.';

  @override
  String get errorNoMember => 'Tsy mandeha io kaonty io';

  @override
  String get errorNoSite => 'Mbola tsy misy toerana ny fikambanana.';

  @override
  String get errorTaken => 'Efa misy mampiasa io anarana io';

  @override
  String errorFailed(String code) {
    return 'Tsy nety : $code';
  }

  @override
  String get passwordTooShort => 'Litera 8 farafahakeliny';

  @override
  String get pinSixDigits => 'Isa 6';

  @override
  String get moreAccount => 'Kaonty';

  @override
  String get accountSignOut => 'Hivoaka';

  @override
  String get accountSignOutQuestion => 'Hivoaka amin\'ity finday ity ve ?';

  @override
  String accountSignOutPending(int count) {
    return 'Firaketana $count mbola tsy lasa. Mijanona ao amin\'ity finday ity izy ireo ary handeha amin\'ny fampifanarahana manaraka.';
  }

  @override
  String get accountRole => 'Anjara';

  @override
  String get roleMember => 'Mpikambana';

  @override
  String get roleWorker => 'Mpiasa';

  @override
  String get roleAdmin => 'Mpitantana';

  @override
  String get roleSales => 'Fivarotana';

  @override
  String get moreSync => 'Fampifanarahana';

  @override
  String syncLast(String at) {
    return 'Fampifanarahana farany : $at';
  }

  @override
  String get syncNever => 'Mbola tsy nampifanarahana mihitsy';

  @override
  String syncPending(int count) {
    return 'Miandry handefasana : $count';
  }

  @override
  String syncRejectedCount(int count) {
    return 'Nolavina : $count';
  }

  @override
  String get syncNow => 'Alefaso';

  @override
  String get syncRetry => 'Andramo indray ireo nolavina';

  @override
  String get syncRelogin => 'Hiditra indray';

  @override
  String get syncStateRunning => 'Am-pampifanarahana…';

  @override
  String get syncStateOffline =>
      'Tsy misy fifandraisana : mijanona ao amin\'ny finday ny angona.';

  @override
  String get syncStateSignedOut =>
      'Tapitra ny fidirana : midira indray mba handefasana ny angona.';

  @override
  String get syncStateUnlinked =>
      'Tsy mifandray amin\'ny kaonty ity finday ity.';

  @override
  String get syncStateNotConfigured =>
      'Tsy misy mpizara amin\'ity dikan-teny ity : mijanona ao amin\'ny finday ny angona.';

  @override
  String syncStateFailed(String error) {
    return 'Tsy nahomby ny fampifanarahana : $error';
  }

  @override
  String get rejectRole =>
      'Tsy mahazo manao io firaketana io ianao noho ny anjaranao';

  @override
  String get rejectLastAdmin =>
      'Tsy maintsy misy mpitantana iray farafahakeliny';

  @override
  String rejectOther(String reason) {
    return 'Nolavina : $reason';
  }

  @override
  String get tableDailyLogs => 'Diary';

  @override
  String get tableWaterReadings => 'Fandrefesana rano';

  @override
  String get tableSamples => 'Fandanjana santionany';

  @override
  String get tableObservations => 'Fanamarihana';

  @override
  String get tableHealthEvents => 'Olana ara-pahasalamana';

  @override
  String get tableTreatments => 'Fitsaboana';

  @override
  String get tableStockings => 'Fametrahana trondro';

  @override
  String get tableTransfers => 'Famindrana';

  @override
  String get tablePonds => 'Dobo';

  @override
  String get tableBatches => 'Andiany';

  @override
  String get tablePeople => 'Olona';

  @override
  String get tableSites => 'Toerana';

  @override
  String get tableVisits => 'Fitsidihana';

  @override
  String get tableGroups => 'Sampana';

  @override
  String get tableMembers => 'Mpikambana';

  @override
  String get tableSettingOverrides => 'Fikirana';

  @override
  String get backupExport => 'Hamoaka tahiry';

  @override
  String get backupImport => 'Hampiditra tahiry';

  @override
  String backupImported(int added, int updated) {
    return 'Voaray $added, novaina $updated';
  }

  @override
  String get backupNotABackup => 'Tsy tahiry Dobo io rakitra io';

  @override
  String get backupOtherAssociation => 'An\'ny fikambanana hafa io tahiry io';

  @override
  String get moreAdmin => 'Fitantanana';

  @override
  String get moreLanguage => 'Fiteny';

  @override
  String get languageFrench => 'Frantsay';

  @override
  String get languageMalagasy => 'Malagasy';

  @override
  String get adminMembers => 'Mpikambana';

  @override
  String get adminGroups => 'Sampana';

  @override
  String get memberNew => 'Kaonty vaovao';

  @override
  String get memberName => 'Anarana';

  @override
  String get memberGroup => 'Sampana';

  @override
  String get memberNoGroup => 'Tsy misy sampana';

  @override
  String get memberActive => 'Mavitrika';

  @override
  String get resetPassword => 'Teny miafina vaovao';

  @override
  String get resetPin => 'Kaody PIN vaovao';

  @override
  String get resetHint =>
      'Omeo mivantana ilay olona izany. Mijanona ho mifandray ireo findainy efa niditra.';

  @override
  String get resetConfirm => 'Ovay';

  @override
  String get resetPasswordDone => 'Voaova ny teny miafina';

  @override
  String get resetPinDone => 'Voaova ny kaody PIN';

  @override
  String get consoleTitle => 'Dobo — console';

  @override
  String get consoleNavAssociation => 'Fikambanana';

  @override
  String get consoleNavGroups => 'Sampana';

  @override
  String get consoleNavMembers => 'Mpikambana';

  @override
  String get consoleNavPeople => 'Olona';

  @override
  String get consoleSignOut => 'Hivoaka';

  @override
  String get consoleAdminsOnly => 'Ho an\'ny mpitantana ihany ny console.';

  @override
  String get consoleIdleNotice =>
      'Nivoaka rehefa tsy nisy hetsika nandritra ny 30 minitra.';

  @override
  String get consoleSignInTitle => 'Hiditra ao amin\'ny console';

  @override
  String get consoleFoundLink => 'Hanorina fikambanana';

  @override
  String get consoleFoundTitle => 'Hanorina ny fikambanana';

  @override
  String get consoleFoundIntro =>
      'Indray mandeha monja, ataon\'ilay ho mpitantana voalohany. Nomena anao niaraka tamin\'ny adiresin\'ny console ny kaody fanorenana.';

  @override
  String get consoleFoundCode => 'Kaody fanorenana';

  @override
  String get consoleFoundAssociation => 'Anaran\'ny fikambanana';

  @override
  String get consoleFoundGroup => 'Anaran\'ny sampanao';

  @override
  String get consoleFoundName => 'Ny anaranao';

  @override
  String get consoleFoundPasswordAgain => 'Teny miafina, indray mandeha indray';

  @override
  String get consolePasswordsDiffer => 'Tsy mitovy ireo teny miafina roa';

  @override
  String get consoleFoundSubmit => 'Hanorina';

  @override
  String get consoleBadCode => 'Diso na efa nampiasaina ny kaody fanorenana';

  @override
  String consoleRefused(String code) {
    return 'Nolavin\'ny mpizara : $code';
  }

  @override
  String get memberPerson => 'Taratasin\'ny mpiasa (tsy voatery)';

  @override
  String get memberNone => 'Tsy misy';

  @override
  String get memberInactive => 'Tsy mavitrika';

  @override
  String get groupName => 'Anaran\'ny sampana';

  @override
  String get groupsEmpty => 'Tsy misy sampana';

  @override
  String get adminSettings => 'Fikirana';

  @override
  String get settingsIntro =>
      'Avelao ho foana raha hitazona ny sandan\'ny boky fiompiana.';

  @override
  String get settingMin => 'min';

  @override
  String get settingMax => 'max';

  @override
  String settingDefault(String value) {
    return 'Boky : $value';
  }

  @override
  String get settingsSaved => 'Voatahiry ny fikirana';

  @override
  String get cfgFryMaxG => 'Fiafaran\'ny dingana zana-trondro (g)';

  @override
  String get cfgPregrowMaxG => 'Fiafaran\'ny fampitomboana voalohany (g)';

  @override
  String get cfgGrowoutMaxG => 'Fiafaran\'ny fampitomboana (g)';

  @override
  String get cfgRationRateFry =>
      'Anjara sakafo amin\'ny zana-trondro (ampahany amin\'ny lanja)';

  @override
  String get cfgRationRatePregrow =>
      'Anjara sakafo amin\'ny fampitomboana voalohany (ampahany amin\'ny lanja)';

  @override
  String get cfgRationRateGrowout =>
      'Anjara sakafo amin\'ny fampitomboana (ampahany amin\'ny lanja)';

  @override
  String get cfgRationRateFinishing =>
      'Anjara sakafo amin\'ny famaranana (ampahany amin\'ny lanja)';

  @override
  String get cfgMaxRationRate =>
      'Anjara sakafo ambony indrindra (ampahany amin\'ny lanja)';

  @override
  String get cfgLeftoverReduction => 'Fihenana raha misy sisa (ampahany)';

  @override
  String get cfgAteFastIncrease => 'Fitomboana raha lany haingana (ampahany)';

  @override
  String get cfgDensityPerM2Earth =>
      'Hakitroky amin\'ny dobo tany (trondro/m²)';

  @override
  String get cfgDensityPerM2Tank =>
      'Hakitroky amin\'ny fitoeran-drano (trondro/m²)';

  @override
  String get cfgDensityPerM2Cage =>
      'Hakitroky amin\'ny tranom-trondro (trondro/m²)';

  @override
  String get cfgTemperatureC => 'Hafanana (°C)';

  @override
  String get cfgPh => 'pH';

  @override
  String get cfgMinOxygenMgL => 'Oksizena farany ambany (mg/L)';

  @override
  String get cfgWaterRenewalPctPerWeek =>
      'Fanavaozana rano (% isan-kerinandro)';

  @override
  String get cfgSampleIntervalDays => 'Andro elanelan\'ny fandanjana roa';

  @override
  String get cfgSampleMinFish => 'Trondro lanjaina, farafahakeliny';

  @override
  String get cfgSampleMaxFish => 'Trondro lanjaina, farafahabetsany';

  @override
  String get cfgWaterCheckIntervalDays =>
      'Andro elanelan\'ny fandrefesana rano roa';

  @override
  String get cfgFcrTarget => 'IC kendrena';

  @override
  String get cfgFeedAgeWarnDays =>
      'Sakafo efa antitra : fampitandremana (andro)';

  @override
  String get cfgFeedAgeDangerDays => 'Sakafo antitra loatra (andro)';

  @override
  String get cfgLowStockDays => 'Tahiry ambany (andro sisa)';

  @override
  String get cfgFeedUsageDays => 'Fanjifana salanisa mandritra ny (andro)';

  @override
  String get cfgMortalitySpikeShare =>
      'Fahafatesana tampoka : ampahan\'ny trondro';

  @override
  String get cfgMortalitySpikeMultiplier =>
      'Fahafatesana tampoka : heny noho ny salanisa';

  @override
  String get cfgMortalitySpikeMinDeaths =>
      'Fahafatesana tampoka : maty farafahakeliny';

  @override
  String get cfgMortalityTrailingDays =>
      'Fahafatesana tampoka : andro ikajiana ny salanisa';

  @override
  String get cfgWarningSignLookbackDays =>
      'Famantarana loza vao haingana (andro)';

  @override
  String get cfgMortalityLookbackDays => 'Fahafatesana tampoka aseho (andro)';

  @override
  String get cfgStopFeedingSignDays =>
      'Aza manome sakafo aorian\'ny famantarana tebiteby (andro)';

  @override
  String get cfgQuarantineDays => 'Fitokanana (andro)';

  @override
  String get cfgDryingDays => 'Fanamainana (andro)';

  @override
  String get cfgRestDays => 'Fialan-tsasatra aorian\'ny famenoana (andro)';

  @override
  String get cfgPreHarvestFastHours =>
      'Tsy fanomezan-tsakafo alohan\'ny fijonoana (ora)';

  @override
  String get cfgHarvestHour => 'Ora anombohan\'ny fijonoana';

  @override
  String get cfgLimeKgPerM2 => 'Sokay (kg/m²)';

  @override
  String get cfgManureKgPerM2 => 'Zezika (kg/m²)';

  @override
  String get cfgPondSurfaceM2 => 'Velaran\'ny dobo iray (m²)';

  @override
  String get cfgPondLengthWidthRatio => 'Fifandanjan\'ny halavany sy ny sakany';

  @override
  String get cfgMinDepthM => 'Halalina farany ambany (m)';

  @override
  String get cfgStockingWeightG => 'Lanja amin\'ny fametrahana (g)';

  @override
  String get cfgAcclimatisationMinutes => 'Fampahazarana (minitra)';

  @override
  String get cfgSectionPhases => 'Dingana';

  @override
  String get cfgSectionFeeding => 'Fanomezan-tsakafo';

  @override
  String get cfgSectionPonds => 'Dobo';

  @override
  String get cfgSectionWaterQuality => 'Kalitaon\'ny rano';

  @override
  String get cfgSectionSampling => 'Fandanjana santionany';

  @override
  String get cfgSectionAlertRules => 'Fampitandremana';

  @override
  String get cfgSectionFormulas => 'Kajy';

  @override
  String get cfgSectionFeedStock => 'Tahiry sakafo';

  @override
  String get cfgSectionSpeciesAndFingerlings => 'Zana-trondro';

  @override
  String get cfgSectionPondPreparation => 'Fanomanana ny dobo';

  @override
  String get cfgSectionHarvestAndDelivery => 'Fijonoana';

  @override
  String get takeoverTitle => 'Haverina ity telefaonina ity';

  @override
  String get takeoverHint =>
      'Ho an\'ny mpitantana ihany. Hivoaka ny mpiasa; mijanona ato amin\'ny telefaonina izay rehetra voasoratany.';

  @override
  String takeoverUnsent(int count) {
    return '$count mbola tsy lasa. Ampifandraiso amin\'ny tambajotra ny telefaonina dia andramo indray.';
  }

  @override
  String get errorNotAdmin => 'Tsy mpitantana io kaonty io.';

  @override
  String get tabAlerts => 'Fampitandremana';

  @override
  String get alertsEmpty => 'Tsy misy fampitandremana, tsy misy atao';

  @override
  String get alertsAll => 'Rehetra';

  @override
  String alertWaterLow(String param, String value) {
    return '$param ambany loatra : $value';
  }

  @override
  String alertWaterHigh(String param, String value) {
    return '$param ambony loatra : $value';
  }

  @override
  String get alertWaterColour =>
      'Maitso loatra na manjavozavo ny rano : ovay ny rano';

  @override
  String alertFcrWorsening(String batch) {
    return 'Andiany $batch : niakatra indroa nisesy ny IC';
  }

  @override
  String alertGrowthStalled(String batch) {
    return 'Andiany $batch : tsy nitombo hatramin\'ny fandanjana farany';
  }

  @override
  String alertMortalitySpike(String deaths, String date) {
    return 'Maty $deaths tamin\'ny $date';
  }

  @override
  String alertWarningSignSeen(String signs) {
    return 'Famantarana loza : $signs';
  }

  @override
  String alertPhaseChange(String batch, String phase) {
    return 'Andiany $batch : miditra amin\'ny $phase, ovay ny sakafo sy ny isan\'ny fanomezana';
  }

  @override
  String alertSampleDue(String batch, String days) {
    return 'Andiany $batch : tokony handanjana ($days andro)';
  }

  @override
  String get alertWaterCheckDue => 'Tokony handrefesana ny rano';

  @override
  String alertQuarantineEnding(String batch, String days, String recommended) {
    return 'Andiany $batch : $days andro fitokanana, tsara afindra alohan\'ny andro $recommended';
  }

  @override
  String alertPreHarvestFast(String batch) {
    return 'Andiany $batch : tsy fanomezan-tsakafo alohan\'ny fijonoana, aza omena sakafo';
  }

  @override
  String alertPreHarvestFed(String batch) {
    return 'Andiany $batch : tsy fanomezan-tsakafo alohan\'ny fijonoana, nefa nisy sakafo nomena';
  }

  @override
  String alertFeedStockLow(String days) {
    return 'Tahiry sakafo : andro $days sisa';
  }

  @override
  String get alertFeedOld =>
      'Efa antitra ny andiana sakafo iray : ampiasao aloha';

  @override
  String get alertFeedExpired =>
      'Antitra loatra ny andiana sakafo iray : aza ampiasaina';

  @override
  String get moreFeed => 'Sakafo';

  @override
  String get harvestAction => 'Hanjono';

  @override
  String get harvestHasSales =>
      'Fafao aloha ny fivarotana tamin\'ity fijonoana ity';

  @override
  String harvestEditTitle(String batch) {
    return 'Hanitsy ny fijonoana $batch';
  }

  @override
  String get feedDeleteDelivery => 'Hamafa ny fanaterana';

  @override
  String get sellAction => 'Hivarotra';

  @override
  String harvestTitle(String batch) {
    return 'Fijonoana $batch';
  }

  @override
  String get harvestPond => 'Dobo';

  @override
  String get harvestDate => 'Daty nanjonoana';

  @override
  String get harvestCount => 'Isan\'ny trondro';

  @override
  String get harvestWeight => 'Lanja iraisana';

  @override
  String get harvestPartial => 'Ampahany';

  @override
  String get harvestFinal => 'Farany (foana ny dobo)';

  @override
  String harvestEstimate(String count) {
    return 'Tombana ao amin\'ny dobo : trondro $count';
  }

  @override
  String harvestMissing(String count) {
    return 'Trondro $count tsy hita (mpihaza, halatra na diso fanisana)';
  }

  @override
  String get harvestNoPond =>
      'Tsy misy dobo ahafahana manjono ity andiany ity : foana na natokana';

  @override
  String get harvestsHeading => 'Fijonoana sy fivarotana';

  @override
  String get harvestKindPartial => 'Fijonoana ampahany';

  @override
  String get harvestKindFinal => 'Fijonoana farany';

  @override
  String harvestLine(
    String date,
    String kind,
    String pond,
    String count,
    String kg,
  ) {
    return '$date · $kind $pond : trondro $count · $kg';
  }

  @override
  String saleLine(String customer, String form, String kg) {
    return '$customer · $form · $kg';
  }

  @override
  String saleTitle(String batch) {
    return 'Fivarotana $batch';
  }

  @override
  String get saleHarvest => 'Fijonoana';

  @override
  String saleHarvestOption(String date, String pond, String kg) {
    return '$date · $pond · $kg';
  }

  @override
  String get saleCustomer => 'Mpanjifa';

  @override
  String get saleNewCustomer => 'Mpanjifa vaovao';

  @override
  String get saleWeight => 'Lanja namidy';

  @override
  String get saleForm => 'Endrika';

  @override
  String get saleDate => 'Daty nivarotana';

  @override
  String get saleNote => 'Taratasy fanaterana (tsy voatery)';

  @override
  String saleOverHarvest(String kg) {
    return 'Mihoatra ny lanja nojonoina mbola tsy lafo ($kg)';
  }

  @override
  String get formLive => 'Velona';

  @override
  String get formFresh => 'Vaovao';

  @override
  String get formFrozen => 'Nangatsiahina';

  @override
  String get formSmoked => 'Nalaina setroka';

  @override
  String get formDried => 'Maina';

  @override
  String get moreSales => 'Fivarotana';

  @override
  String get traceTitle => 'Taratasy fanarahana ny andiany';

  @override
  String traceBatch(String code) {
    return 'Andiany $code';
  }

  @override
  String get traceIdentity => 'Mombamomba';

  @override
  String get tracePonds => 'Dobo';

  @override
  String get traceTreatments => 'Fitsaboana';

  @override
  String get traceHarvests => 'Fijonoana';

  @override
  String get traceSales => 'Fivarotana';

  @override
  String get traceResults => 'Vokatra';

  @override
  String get traceCycleFcr => 'IC amin\'ny tsingerina';

  @override
  String get traceCycleOngoing => 'mbola mandeha ny tsingerina';

  @override
  String get traceSurvival => 'Velona tavela';

  @override
  String get traceUnaccounted => 'Trondro tsy hita';

  @override
  String get traceFeed => 'Sakafo nomena';

  @override
  String get traceStocked => 'Napetraka tao anaty dobo';

  @override
  String get traceHarvested => 'Nojonoina';

  @override
  String get traceLive => 'Mbola ao anaty dobo';

  @override
  String traceAdvisedBy(String who) {
    return 'nanoroan\'i $who hevitra';
  }

  @override
  String get salesTitle => 'Fijonoana sy fivarotana';

  @override
  String get salesNone => 'Tsy misy fijonoana voasoratra';

  @override
  String get customersTitle => 'Mpanjifa';

  @override
  String get customerNew => 'Mpanjifa vaovao';

  @override
  String get customerEdit => 'Mpanjifa';

  @override
  String get customerName => 'Anarana';

  @override
  String get customerType => 'Karazana';

  @override
  String get customerContact => 'Fifandraisana (tsy voatery)';

  @override
  String get customerArchive => 'Esory amin\'ny lisitra';

  @override
  String get customersNone => 'Tsy misy mpanjifa';

  @override
  String get custMarket => 'Tsena';

  @override
  String get custRestaurant => 'Trano fisakafoanana';

  @override
  String get custSupermarket => 'Fivarotana lehibe';

  @override
  String get custExporter => 'Mpanondrana';

  @override
  String get custIndividual => 'Olon-tsotra';

  @override
  String get feedTitle => 'Tahiry sakafo';

  @override
  String get feedOnHand => 'Ao amin\'ny tahiry';

  @override
  String feedDaysLeft(String days) {
    return 'Tahiry ho an\'ny andro $days';
  }

  @override
  String get feedNoUsage => 'Tsy nisy fanjifana tato ho ato';

  @override
  String feedOverdrawn(String kg) {
    return 'Sakafo nomena mihoatra noho ny natolotra : $kg';
  }

  @override
  String feedExpiredStock(String kg) {
    return 'Tsy azo ampiasaina : $kg';
  }

  @override
  String get feedNoLots => 'Tsy misy fanaterana voasoratra';

  @override
  String feedLotMade(String date, String days) {
    return 'Natao tamin\'ny $date · $days andro';
  }

  @override
  String get feedLotOld => 'Ampiasao aloha';

  @override
  String get feedLotExpired => 'Aza ampiasaina';

  @override
  String get feedDeliver => 'Fanaterana';

  @override
  String get feedDeliveryTitle => 'Fanaterana sakafo';

  @override
  String get feedPhase => 'Sakafo ho an\'ny';

  @override
  String get feedWeight => 'Lanja natolotra';

  @override
  String get feedMadeOn => 'Daty nanamboarana';

  @override
  String get feedDeliveredOn => 'Daty nanaterana';

  @override
  String get feedPellet => 'Haben\'ny voany';

  @override
  String get feedProtein => 'Proteinina';

  @override
  String get feedSupplier => 'Mpamatsy';

  @override
  String get feedLabel => 'Marika eo amin\'ny gony';

  @override
  String get feedDiscard => 'Hanary';

  @override
  String get feedDiscardTitle => 'Sakafo nariana';

  @override
  String get feedDiscardWeight => 'Lanja nariana';

  @override
  String get feedDiscardReason => 'Antony';

  @override
  String get discardMould => 'Bobongolo';

  @override
  String get discardRancid => 'Maimbo';

  @override
  String get discardClumped => 'Nitambatra';

  @override
  String get discardOther => 'Hafa';

  @override
  String get feedLot => 'Andiana sakafo';

  @override
  String get feedLotAuto => 'Ny tranainy indrindra (ho azy)';

  @override
  String get alertPrepDry =>
      'Vita ve ny fanamainana ? Jereo ny triatra, avy eo soraty ny fanamainana';

  @override
  String get alertPrepRest =>
      'Vita ny fialan-tsasatra : azo ambara ho vonona ny dobo';

  @override
  String get prepButton => 'Fanomanana';

  @override
  String prepTitle(String pond) {
    return 'Fanomanana $pond';
  }

  @override
  String get prepStepDrain => 'Fanariana rano sy fanadiovana fotaka';

  @override
  String get prepStepDry => 'Fanamainana amin\'ny masoandro';

  @override
  String get prepStepTreat => 'Fitsaboana (sokay velona na klôro)';

  @override
  String get prepStepFertilise => 'Fanomezana zezika';

  @override
  String get prepStepFill => 'Famenoana amin\'ny fidirana misy harato';

  @override
  String get prepStepRest => 'Fialan-tsasatra';

  @override
  String get prepDone => 'Vita';

  @override
  String prepDoneOn(String date) {
    return 'Vita tamin\'ny $date';
  }

  @override
  String prepDryUntil(String from, String to) {
    return 'Fanamainana : $from ka hatramin\'ny $to';
  }

  @override
  String prepRestUntil(String date) {
    return 'Fialan-tsasatra hatramin\'ny $date';
  }

  @override
  String prepLimeDose(String range, String surface) {
    return 'Sokay velona : $range ho an\'ny $surface';
  }

  @override
  String prepManureDose(String range, String surface) {
    return 'Zezika : $range ho an\'ny $surface';
  }

  @override
  String get prepNoSurface =>
      'Raha tsy misy ny velaran\'ny dobo dia tsy misy fatra : asio ny halavany sy ny sakany';

  @override
  String get prepMarkReady => 'Vonona hametrahana trondro';

  @override
  String prepSkipped(String steps) {
    return 'Dingana tsy natao : $steps';
  }

  @override
  String prepRestShort(String date) {
    return 'Tsy mbola vita ny fialan-tsasatra (hatramin\'ny $date)';
  }

  @override
  String get prepReadyConfirm =>
      'Ambara ho vonona hametrahana trondro ve ny dobo ?';

  @override
  String get prepProductQuicklime => 'Sokay velona';

  @override
  String get prepProductChlorine => 'Klôro';

  @override
  String get prepProductManure => 'Zezika';

  @override
  String get prepDoseUsed => 'Fatra nampiasaina';

  @override
  String get doneDate => 'Daty';

  @override
  String alertDuplicateLog(String date) {
    return 'Diary roa tamin\'ny $date : safidio izay hotazonina';
  }

  @override
  String get duplicateKeep => 'Tazomy ity';

  @override
  String get duplicateResolved =>
      'Voavaha : diary iray monja ho an\'io andro io';

  @override
  String duplicateEnteredBy(String name) {
    return 'Nosoratan\'i $name';
  }

  @override
  String duplicateObservedBy(String name) {
    return 'Hitan\'i $name';
  }

  @override
  String get duplicateOtherPhone => 'finday hafa';

  @override
  String get staleRecord => 'Efa novaina tamin\'ny finday hafa ity diary ity';

  @override
  String get rationToday => 'Sakafo anio';

  @override
  String lastWeighed(String days) {
    return 'Fandanjana farany : $days andro lasa izay';
  }

  @override
  String notSampledYet(String days) {
    return 'Mbola tsy nolanjaina, napetraka $days andro lasa izay';
  }

  @override
  String fcrValue(String value) {
    return 'IC : $value';
  }

  @override
  String survivalValue(String pct) {
    return 'Velona tavela : $pct %';
  }

  @override
  String get chartWeight => 'Lanja salanisa (g)';

  @override
  String get chartDeaths => 'Maty isan\'andro';

  @override
  String get chartFcr => 'IC isaky ny vanim-potoana';

  @override
  String get chartEmpty => 'Mbola tsy misy angona';

  @override
  String get fcrStalled => 'tsy mitombo';

  @override
  String get workerStopFeeding => 'Aza omena sakafo';

  @override
  String get workerReasonFast => 'Hojonoina tsy ho ela';

  @override
  String get workerReasonOxygen => 'Tsy ampy rivotra ny rano';

  @override
  String get workerReasonDistress => 'Tsy salama ny trondro';

  @override
  String labelValue(String label, String value) {
    return '$label : $value';
  }

  @override
  String labelColon(String label) {
    return '$label :';
  }

  @override
  String get tabReports => 'Tatitra';

  @override
  String get reportTitle => 'Tatitry ny fitsidihana';

  @override
  String get reportsEmpty => 'Mbola tsy misy tatitra';

  @override
  String get reportDraft => 'Drafitra — mbola havoaka';

  @override
  String get reportPublish => 'Havoaka';

  @override
  String get reportShare => 'Hizara';

  @override
  String reportCardTitle(String date, String member) {
    return '$date · $member';
  }

  @override
  String reportPeriod(String from, String to) {
    return 'Nanomboka ny $from ka hatramin\'ny $to';
  }

  @override
  String reportAuthor(String member) {
    return 'Nataon\'i $member';
  }

  @override
  String reportAuthorGroup(String member, String group) {
    return 'Nataon\'i $member ($group)';
  }

  @override
  String reportPublishedOn(String date) {
    return 'Navoaka tamin\'ny $date';
  }

  @override
  String get reportUpdateApp =>
      'Havaozy ny fampiharana mba hamakiana ity tatitra ity.';

  @override
  String get reportSummary => 'Famintinana';

  @override
  String get reportAlerts => 'Fampitandremana';

  @override
  String get reportHealth => 'Fahasalamana';

  @override
  String get reportWater => 'Rano';

  @override
  String get reportGrowth => 'Fitomboana';

  @override
  String get reportFeed => 'Sakafo';

  @override
  String get reportNext => 'Ho avy';

  @override
  String get reportObservations => 'Fanamarihana sy sary';

  @override
  String get reportNothing => 'Tsy misy holazaina';

  @override
  String get reportNoSummary => 'Tsy misy famintinana';

  @override
  String get reportNoReading => 'Tsy misy fandrefesana';

  @override
  String get reportNoFish => 'Tsy misy trondro anaty dobo';

  @override
  String get reportNoFeed =>
      'Tsy nisy sakafo voasoratra nandritra io fotoana io';

  @override
  String get reportFeedStockLater =>
      'Tahiry sakafo : tsy arahina (tsy misy fanaterana voasoratra)';

  @override
  String reportFeedOnHand(String kg, String days) {
    return 'Ao amin\'ny tahiry : $kg, tahiry ho an\'ny andro $days';
  }

  @override
  String reportFeedOnHandNoUsage(String kg) {
    return 'Ao amin\'ny tahiry : $kg';
  }

  @override
  String reportFeedLot(String lot, String kg, String date) {
    return '$lot · $kg · natao tamin\'ny $date';
  }

  @override
  String reportNextDry(String pond) {
    return 'Vita ve ny fanamainana ny $pond ?';
  }

  @override
  String reportNextRest(String pond) {
    return 'Vita ny fialan-tsasatry ny $pond : vonona hametrahana trondro';
  }

  @override
  String reportDeaths(String count) {
    return 'Maty $count';
  }

  @override
  String reportObserverDeaths(String name, String count) {
    return '$name $count';
  }

  @override
  String get reportListSeparator => ' · ';

  @override
  String get reportUnknownPerson => 'tsy fantatra';

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
    return 'Fandrefesana tamin\'ny $date';
  }

  @override
  String reportGrowthLine(String batch, String weight, String date) {
    return '$batch · $weight (nolanjaina tamin\'ny $date)';
  }

  @override
  String get reportBiomass => 'Lanjan\'ny trondro rehetra';

  @override
  String get reportFish => 'Trondro';

  @override
  String get reportFcrShared => 'dobo iombonana';

  @override
  String get reportFcrNoSample => 'mbola tsy nolanjaina';

  @override
  String get reportTrendWorse => 'miakatra';

  @override
  String get reportTrendBetter => 'midina';

  @override
  String get reportTrendSame => 'tsy miova';

  @override
  String get reportFeedTotal => 'Totaly';

  @override
  String reportNextSample(String batch) {
    return 'Fandanjana ny $batch';
  }

  @override
  String reportNextHarvest(String batch) {
    return 'Fijonoana ny $batch';
  }

  @override
  String reportNextQuarantine(String batch) {
    return 'Fiafaran\'ny fitokanana ny $batch';
  }

  @override
  String reportAllOk(String items) {
    return 'Milamina : $items';
  }

  @override
  String get photoAdd => 'Hanampy sary';

  @override
  String get photoUpload => 'Halefa any amin\'ny mpizara';

  @override
  String get photoDelete => 'Hamafa ny sary';

  @override
  String get photoFailed =>
      'Tsy azo nalaina ny sary. Voatahiry tsy misy azy ny firaketana.';

  @override
  String get photoUnavailable => 'Mbola tsy misy ny sary';

  @override
  String syncPhotosWaiting(int count) {
    return 'Sary miandry handefasana : $count';
  }

  @override
  String get syncPhotoCap =>
      'Tratra ny fetran\'ny sary : afaka mampiakatra azy ao amin\'ny Fikirana ny mpitantana.';

  @override
  String get settingsPhotos => 'Sary';

  @override
  String get settingPhotoUploadCap =>
      'Sary alefa any amin\'ny mpizara, farafahabetsany';

  @override
  String get photoDeleteConfirm =>
      'Hofafana ve ity sary ity ? Ho voafafa amin\'ity finday ity izy.';

  @override
  String get paperTitle => 'Taratasy isan\'andro';

  @override
  String paperWeek(String from, String to) {
    return 'Herinandro $from – $to';
  }

  @override
  String get paperWorker => 'Mpiasa';

  @override
  String get paperFeedKg => 'Sakafo (kg)';

  @override
  String get paperDay => 'Andro';

  @override
  String get paperHowTo => 'Asio marika ny efajoro raha hitanao izany.';

  @override
  String get paperNoPonds => 'Tsy misy dobo miasa.';

  @override
  String get weekdayMon => 'Alatsinainy';

  @override
  String get weekdayTue => 'Talata';

  @override
  String get weekdayWed => 'Alarobia';

  @override
  String get weekdayThu => 'Alakamisy';

  @override
  String get weekdayFri => 'Zoma';

  @override
  String get weekdaySat => 'Asabotsy';

  @override
  String get weekdaySun => 'Alahady';

  @override
  String get morePaper => 'Taratasy hosoratana';

  @override
  String get paperWeeksLabel => 'Isan\'ny herinandro';

  @override
  String get paperPondsLabel => 'Dobo';

  @override
  String get paperPrint => 'Hanonta';

  @override
  String get paperShare => 'Hizara ny PDF';

  @override
  String get transcriptionCellDetails => 'Antsipirian\'ny andro';

  @override
  String get exportRegisterTitle => 'Rejisitra famokarana';

  @override
  String get exportWeeklyTitle => 'Taratasy fanaraha-maso isan-kerinandro';

  @override
  String exportPeriod(String from, String to) {
    return 'Nanomboka ny $from ka hatramin\'ny $to';
  }

  @override
  String get exportColDate => 'Daty';

  @override
  String get exportColPondBatch => 'Dobo / Andiany';

  @override
  String get exportColOrigin => 'Niavian\'ny zana-trondro';

  @override
  String get exportColFeedKg => 'Sakafo (kg)';

  @override
  String get exportColDeaths => 'Maty (isa)';

  @override
  String get exportColSalesKg => 'Namidy (kg)';

  @override
  String get exportColObservations => 'Fanamarihana';

  @override
  String get exportColPond => 'Dobo';

  @override
  String get exportColWeekOf => 'Herinandro manomboka ny';

  @override
  String get exportColTemp => 'Hafanana (°C)';

  @override
  String get exportColPh => 'pH';

  @override
  String get exportColOxygen => 'Oksizena (mg/L)';

  @override
  String get exportColFeedGivenKg => 'Sakafo nomena (kg)';

  @override
  String get exportColAvgWeight => 'Lanja salanisa (g)';

  @override
  String exportFishCount(String count) {
    return 'trondro $count';
  }

  @override
  String get exportTreatment => 'Fitsaboana';

  @override
  String get exportHealth => 'Olana voalaza';

  @override
  String exportThresholds(
    String temp,
    String ph,
    String oxygen,
    String renewal,
  ) {
    return 'Fetra : hafanana $temp °C · pH $ph · oksizena ≥ $oxygen mg/L · fanavaozana rano $renewal % isan-kerinandro raha manjavozavo ny rano.';
  }

  @override
  String get moreExports => 'Fanondranana';

  @override
  String get exportKindRegister => 'Rejisitra famokarana (tovana A)';

  @override
  String get exportKindWeekly => 'Fanaraha-maso isan-kerinandro (tovana B)';

  @override
  String get exportFrom => 'Nanomboka ny';

  @override
  String get exportTo => 'Hatramin\'ny';

  @override
  String get exportPond => 'Dobo';

  @override
  String get exportAllPonds => 'Dobo rehetra';

  @override
  String get exportPdf => 'PDF';

  @override
  String get exportCsv => 'CSV';

  @override
  String get exportEndBeforeStart =>
      'Mialoha ny daty fanombohana ny daty farany.';

  @override
  String get exportWeeklyWholeWeeks =>
      'Herinandro feno, Alatsinainy ka hatramin\'ny Alahady.';

  @override
  String get close => 'Hidio';

  @override
  String get exportBuilding => 'Am-panomanana ny rakitra…';
}
