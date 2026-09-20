import 'package:flutter/material.dart';

/// Reactive provider managing active application locale (English & Hindi).
class LocaleProvider extends ValueNotifier<Locale> {
  LocaleProvider._() : super(defaultLocale);

  static final LocaleProvider instance = LocaleProvider._();

  static const Locale defaultLocale = Locale('en');
  static const Locale hindiLocale = Locale('hi');

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
  ];

  bool get isHindi => value.languageCode == 'hi';
  bool get isEnglish => value.languageCode == 'en';

  void setLocale(Locale newLocale) {
    if (value != newLocale) {
      value = newLocale;
      notifyListeners();
    }
  }

  void toggleLocale() {
    if (isHindi) {
      setLocale(defaultLocale);
    } else {
      setLocale(hindiLocale);
    }
  }
}
