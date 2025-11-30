// lib/core/localization/app_localizations.dart
import 'package:flutter/material.dart';

/// Simple, code-based localization for YS Media Player Pro.
/// Locales: English (en), Hindi (hi), Arabic placeholder (ar).

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ar'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    ) ??
        AppLocalizations(const Locale('en'));
  }

  static final Map<String, Map<String, String>> _localizedValues =
  <String, Map<String, String>>{
    'en': {
      // General
      'app_name': 'YS Media Player Pro',

      // Tabs
      'tab_videos': 'Videos',
      'tab_folders': 'Folders',
      'tab_playlists': 'Playlists',
      'tab_settings': 'Settings',

      // Videos tab
      'videos_allow_access_title': 'Allow access to your videos',
      'videos_allow_access_body':
      'YS Media Player Pro needs permission to access your device videos.',
      'videos_grant_permission': 'Grant Permission',
      'videos_header_all': 'All videos',
      'videos_sort_title': 'Title (A–Z)',
      'videos_sort_date': 'Date added (newest first)',
      'videos_sort_duration': 'Duration (longest first)',
      'videos_search_hint': 'Search videos...',
      'videos_scanning': 'Scanning videos...',
      'videos_unable_load': 'Unable to load videos',
      'videos_retry': 'Retry',
      'videos_none_found': 'No videos found',
      'videos_no_match': 'No videos match your search',
      'videos_download_only_remote':
      'Download is only available for online videos (HTTP/HTTPS).',
      'videos_download_already': 'Download already in this state:',
      'videos_download_added': 'Download added to queue',

      // Settings
      'settings_title': 'Settings',
      'settings_description_line1':
      'Control your YS Media Player Pro experience.',
      'settings_description_line2': 'Playback, themes, language & more.',
      'settings_section_appearance': 'Appearance',
      'settings_section_language': 'Language',
      'settings_section_accessibility': 'Accessibility',
      'settings_section_advanced': 'Advanced',
      'settings_theme_mode': 'Theme mode',
      'settings_theme_system': 'Use system theme',
      'settings_theme_light': 'Light',
      'settings_theme_dark': 'Dark',
      'settings_theme_high_contrast': 'High contrast',
      'settings_language_label': 'App language',
      'settings_language_en': 'English',
      'settings_language_hi': 'Hindi',
      'settings_language_ar': 'Arabic (RTL demo)',
      'settings_font_size': 'Font size',
      'settings_font_small': 'Small',
      'settings_font_normal': 'Normal',
      'settings_font_large': 'Large',
      'settings_high_contrast_label': 'High contrast mode',
      'settings_quick_actions': 'Quick actions',
      'settings_quick_actions_hint':
      'Home-screen shortcuts for library, downloads, recent.',
      'settings_clear_diagnostics': 'Clear diagnostics & telemetry',
      'settings_clear_diagnostics_confirm_title': 'Clear diagnostics?',
      'settings_clear_diagnostics_confirm_body':
      'This will remove locally stored logs and telemetry events.',
      'settings_clear_diagnostics_confirm_yes': 'Clear',
      'settings_clear_diagnostics_confirm_no': 'Cancel',
      'settings_feedback': 'Send feedback',

      // Feedback (hook only, UI may exist elsewhere)
      'feedback_title': 'Send feedback',
      'feedback_message_hint': 'Describe your issue or suggestion...',
      'feedback_include_logs': 'Include diagnostic logs',
      'feedback_submit': 'Submit',
      'feedback_thanks': 'Thanks for your feedback!',
    },
    'hi': {
      'app_name': 'YS मीडिया प्लेयर प्रो',

      'tab_videos': 'वीडियो',
      'tab_folders': 'फोल्डर',
      'tab_playlists': 'प्लेलिस्ट',
      'tab_settings': 'सेटिंग्स',

      'videos_allow_access_title': 'अपने वीडियो तक पहुँच की अनुमति दें',
      'videos_allow_access_body':
      'YS मीडिया प्लेयर प्रो को आपके डिवाइस के वीडियो देखने की अनुमति चाहिए।',
      'videos_grant_permission': 'अनुमति दें',
      'videos_header_all': 'सभी वीडियो',
      'videos_sort_title': 'शीर्षक (A–Z)',
      'videos_sort_date': 'तारीख (नए पहले)',
      'videos_sort_duration': 'अवधि (सबसे लंबा पहले)',
      'videos_search_hint': 'वीडियो खोजें...',
      'videos_scanning': 'वीडियो स्कैन हो रहे हैं...',
      'videos_unable_load': 'वीडियो लोड नहीं हो पाए',
      'videos_retry': 'फिर से कोशिश करें',
      'videos_none_found': 'कोई वीडियो नहीं मिला',
      'videos_no_match': 'इस खोज के लिए कोई वीडियो नहीं मिला',
      'videos_download_only_remote':
      'डाउनलोड केवल ऑनलाइन (HTTP/HTTPS) वीडियो के लिए उपलब्ध है।',
      'videos_download_already': 'डाउनलोड पहले से इस स्थिति में है:',
      'videos_download_added': 'डाउनलोड कतार में जोड़ दिया गया',

      'settings_title': 'सेटिंग्स',
      'settings_description_line1':
      'अपने YS मीडिया प्लेयर प्रो अनुभव को नियंत्रित करें।',
      'settings_description_line2': 'प्लेबैक, थीम, भाषा और बहुत कुछ।',
      'settings_section_appearance': 'दिखावट (Appearance)',
      'settings_section_language': 'भाषा',
      'settings_section_accessibility': 'एक्सेसिबिलिटी',
      'settings_section_advanced': 'एडवांस्ड',
      'settings_theme_mode': 'थीम मोड',
      'settings_theme_system': 'सिस्टम थीम का उपयोग करें',
      'settings_theme_light': 'लाइट',
      'settings_theme_dark': 'डार्क',
      'settings_theme_high_contrast': 'हाई कॉन्ट्रास्ट',
      'settings_language_label': 'ऐप भाषा',
      'settings_language_en': 'अंग्रेज़ी',
      'settings_language_hi': 'हिन्दी',
      'settings_language_ar': 'अरबी (RTL डेमो)',
      'settings_font_size': 'फ़ॉन्ट साइज',
      'settings_font_small': 'छोटा',
      'settings_font_normal': 'सामान्य',
      'settings_font_large': 'बड़ा',
      'settings_high_contrast_label': 'हाई कॉन्ट्रास्ट मोड',
      'settings_quick_actions': 'क्विक एक्शन',
      'settings_quick_actions_hint':
      'होम-स्क्रीन शॉर्टकट: लाइब्रेरी, डाउनलोड, हाल के।',
      'settings_clear_diagnostics': 'डायग्नोस्टिक्स व टेलीमेट्री साफ करें',
      'settings_clear_diagnostics_confirm_title': 'डायग्नोस्टिक्स साफ करें?',
      'settings_clear_diagnostics_confirm_body':
      'यह लोकल लॉग्स व टेलीमेट्री डेटा हटा देगा।',
      'settings_clear_diagnostics_confirm_yes': 'साफ करें',
      'settings_clear_diagnostics_confirm_no': 'रद्द करें',
      'settings_feedback': 'फीडबैक भेजें',

      'feedback_title': 'फीडबैक भेजें',
      'feedback_message_hint': 'अपनी समस्या या सुझाव लिखें...',
      'feedback_include_logs': 'डायग्नोस्टिक लॉग जोड़ें',
      'feedback_submit': 'भेजें',
      'feedback_thanks': 'फीडबैक के लिए धन्यवाद!',
    },
    'ar': {
      // Arabic placeholder – using English strings but RTL layout will apply.
      'app_name': 'YS Media Player Pro (AR)',

      'tab_videos': 'Videos',
      'tab_folders': 'Folders',
      'tab_playlists': 'Playlists',
      'tab_settings': 'Settings',

      'videos_allow_access_title': 'Allow access to your videos',
      'videos_allow_access_body':
      'YS Media Player Pro needs permission to access your device videos.',
      'videos_grant_permission': 'Grant Permission',
      'videos_header_all': 'All videos',
      'videos_sort_title': 'Title (A–Z)',
      'videos_sort_date': 'Date added (newest first)',
      'videos_sort_duration': 'Duration (longest first)',
      'videos_search_hint': 'Search videos...',
      'videos_scanning': 'Scanning videos...',
      'videos_unable_load': 'Unable to load videos',
      'videos_retry': 'Retry',
      'videos_none_found': 'No videos found',
      'videos_no_match': 'No videos match your search',
      'videos_download_only_remote':
      'Download is only available for online videos (HTTP/HTTPS).',
      'videos_download_already': 'Download already in this state:',
      'videos_download_added': 'Download added to queue',

      'settings_title': 'Settings',
      'settings_description_line1':
      'Control your YS Media Player Pro experience.',
      'settings_description_line2': 'Playback, themes, language & more.',
      'settings_section_appearance': 'Appearance',
      'settings_section_language': 'Language',
      'settings_section_accessibility': 'Accessibility',
      'settings_section_advanced': 'Advanced',
      'settings_theme_mode': 'Theme mode',
      'settings_theme_system': 'Use system theme',
      'settings_theme_light': 'Light',
      'settings_theme_dark': 'Dark',
      'settings_theme_high_contrast': 'High contrast',
      'settings_language_label': 'App language',
      'settings_language_en': 'English',
      'settings_language_hi': 'Hindi',
      'settings_language_ar': 'Arabic (RTL demo)',
      'settings_font_size': 'Font size',
      'settings_font_small': 'Small',
      'settings_font_normal': 'Normal',
      'settings_font_large': 'Large',
      'settings_high_contrast_label': 'High contrast mode',
      'settings_quick_actions': 'Quick actions',
      'settings_quick_actions_hint':
      'Home-screen shortcuts for library, downloads, recent.',
      'settings_clear_diagnostics': 'Clear diagnostics & telemetry',
      'settings_clear_diagnostics_confirm_title': 'Clear diagnostics?',
      'settings_clear_diagnostics_confirm_body':
      'This will remove locally stored logs and telemetry events.',
      'settings_clear_diagnostics_confirm_yes': 'Clear',
      'settings_clear_diagnostics_confirm_no': 'Cancel',
      'settings_feedback': 'Send feedback',

      'feedback_title': 'Send feedback',
      'feedback_message_hint': 'Describe your issue or suggestion...',
      'feedback_include_logs': 'Include diagnostic logs',
      'feedback_submit': 'Submit',
      'feedback_thanks': 'Thanks for your feedback!',
    },
  };

  String _t(String key) {
    final lang = locale.languageCode;
    return _localizedValues[lang]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  // Short helpers for frequently used strings.
  String get appName => _t('app_name');

  String get tabVideos => _t('tab_videos');
  String get tabFolders => _t('tab_folders');
  String get tabPlaylists => _t('tab_playlists');
  String get tabSettings => _t('tab_settings');

  String tr(String key) => _t(key);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales
          .map((e) => e.languageCode)
          .contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant _AppLocalizationsDelegate old) => false;
}
