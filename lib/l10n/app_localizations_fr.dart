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
}
