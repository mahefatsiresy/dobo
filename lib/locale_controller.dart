import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() => const Locale('fr');

  void set(Locale locale) => state = locale;
}
