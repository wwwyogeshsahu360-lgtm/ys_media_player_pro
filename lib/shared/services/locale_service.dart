// lib/shared/services/locale_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/localization/app_localizations.dart';
import 'log_service.dart';

/// LocaleService
/// =============
/// Stores and exposes the current app Locale.
class LocaleService extends ChangeNotifier {
  LocaleService._internal();

  static final LocaleService instance = LocaleService._internal();

  static const String _kLocaleCodeKey = 'ys_locale_code';

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? code = prefs.getString(_kLocaleCodeKey);
      if (code != null) {
        _locale = Locale(code);
      } else {
        _locale = const Locale('en');
      }
      LogService.instance.log('[LocaleService] init locale=$_locale');
    } catch (e, st) {
      LogService.instance
          .logError('[LocaleService] init error: $e', st);
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!AppLocalizations.supportedLocales
        .map((e) => e.languageCode)
        .contains(locale.languageCode)) {
      return;
    }
    _locale = locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLocaleCodeKey, locale.languageCode);
      LogService.instance.log('[LocaleService] setLocale=$locale');
    } catch (e, st) {
      LogService.instance
          .logError('[LocaleService] setLocale error: $e', st);
    }
  }
}
