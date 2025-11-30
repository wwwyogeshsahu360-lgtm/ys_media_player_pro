import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/config/app_config.dart';
import 'core/errors/global_error_handler.dart';
import 'core/localization/app_localizations.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/services/log_service.dart';
import 'shared/services/theme_service.dart';
import 'shared/services/locale_service.dart';
import 'shared/services/accessibility_service.dart';
import 'shared/services/quick_actions_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final LogService logService = LogService.instance;
  final AppConfig appConfig = AppConfig.instance;

  // Initialize global error handling before anything else.
  GlobalErrorHandler.initialize(logService: logService);

  // Initialize core singletons that impact app root.
  await Future.wait(<Future<void>>[
    ThemeService.instance.init(),
    LocaleService.instance.init(),
    AccessibilityService.instance.init(),
    QuickActionsService.instance.init(),
  ]);

  // Log basic startup info.
  logService.log('Starting YS Media Player Pro...');
  logService.log('Environment: ${appConfig.environment}');
  logService.log('Initial theme mode (AppConfig): ${appConfig.themeMode}');
  logService.log(
      'ThemeService mode: ${ThemeService.instance.themeMode}, locale: ${LocaleService.instance.locale}');

  runZonedGuarded(
        () {
      runApp(const YSApp());
    },
        (Object error, StackTrace stackTrace) {
      logService.logError('Uncaught zone error: $error', stackTrace);
    },
  );
}

/// Root widget for the entire YS Media Player Pro app.
class YSApp extends StatefulWidget {
  const YSApp({super.key});

  @override
  State<YSApp> createState() => _YSAppState();
}

class _YSAppState extends State<YSApp> {
  final ThemeService _themeService = ThemeService.instance;
  final LocaleService _localeService = LocaleService.instance;
  final AccessibilityService _accessibilityService =
      AccessibilityService.instance;

  @override
  void initState() {
    super.initState();
    _themeService.addListener(_onThemeOrLocaleChanged);
    _localeService.addListener(_onThemeOrLocaleChanged);
    _accessibilityService.addListener(_onThemeOrLocaleChanged);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeOrLocaleChanged);
    _localeService.removeListener(_onThemeOrLocaleChanged);
    _accessibilityService.removeListener(_onThemeOrLocaleChanged);
    super.dispose();
  }

  void _onThemeOrLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ThemeMode themeMode = _themeService.themeMode;
    final Locale locale = _localeService.locale;
    final double textScale =
        _accessibilityService.textScaleFactor;

    // Choose actual theme based on high-contrast flag (if used by Settings)
    final bool highContrast = _themeService.highContrast;
    final ThemeData light = highContrast
        ? AppTheme.highContrastLight
        : AppTheme.lightTheme;
    final ThemeData dark = highContrast
        ? AppTheme.highContrastDark
        : AppTheme.darkTheme;

    return MediaQuery(
      // Apply user text scale preset on top of system scaling.
      data: MediaQueryData.fromWindow(WidgetsBinding.instance.window)
          .copyWith(textScaleFactor: textScale),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: AppRouter.router,
        theme: light,
        darkTheme: dark,
        themeMode: themeMode,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
