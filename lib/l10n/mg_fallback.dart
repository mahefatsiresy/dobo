import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Flutter ships no Material, Cupertino or Widgets localizations for Malagasy.
/// These delegates serve the French ones when the app runs in `mg`.
const List<LocalizationsDelegate<dynamic>> mgFallbackDelegates = [
  _MgFallbackMaterialDelegate(),
  _MgFallbackCupertinoDelegate(),
  _MgFallbackWidgetsDelegate(),
];

const _french = Locale('fr');

bool _isMalagasy(Locale locale) => locale.languageCode == 'mg';

class _MgFallbackMaterialDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _MgFallbackMaterialDelegate();

  @override
  bool isSupported(Locale locale) => _isMalagasy(locale);

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(_french);

  @override
  bool shouldReload(_MgFallbackMaterialDelegate old) => false;
}

class _MgFallbackCupertinoDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _MgFallbackCupertinoDelegate();

  @override
  bool isSupported(Locale locale) => _isMalagasy(locale);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(_french);

  @override
  bool shouldReload(_MgFallbackCupertinoDelegate old) => false;
}

class _MgFallbackWidgetsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _MgFallbackWidgetsDelegate();

  @override
  bool isSupported(Locale locale) => _isMalagasy(locale);

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(_french);

  @override
  bool shouldReload(_MgFallbackWidgetsDelegate old) => false;
}
