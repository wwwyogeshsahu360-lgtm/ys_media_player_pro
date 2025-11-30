// lib/features/settings/presentation/pages/settings_tab.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/services/accessibility_service.dart';
import '../../../../shared/services/locale_service.dart';
import '../../../../shared/services/theme_service.dart';
import '../../../../shared/services/log_service.dart';
// EQ screen (Day 18)
import '../../../audio_dsp/presentation/eq_screen.dart';
// NEW (Day 19): Streaming inspector
import '../../../streaming/presentation/stream_inspector_screen.dart';

/// SettingsTab
/// ===========
/// Day 16/17/18/19: settings hub for theme, language, accessibility, etc.
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final ThemeService _themeService = ThemeService.instance;
  final LocaleService _localeService = LocaleService.instance;
  final AccessibilityService _access = AccessibilityService.instance;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _buildHeader(context, l10n, cs),
        const SizedBox(height: 16),
        _buildAppearanceSection(context, l10n),
        const SizedBox(height: 16),
        _buildLanguageSection(context, l10n),
        const SizedBox(height: 16),
        _buildAccessibilitySection(context, l10n),
        const SizedBox(height: 16),
        _buildAdvancedSection(context, l10n),
        if (kDebugMode) ...<Widget>[
          const SizedBox(height: 24),
          _buildDebugSection(context),
        ],
      ],
    );
  }

  Widget _buildHeader(
      BuildContext context,
      AppLocalizations l10n,
      ColorScheme cs,
      ) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              Icons.settings_rounded,
              size: 48,
              color: cs.primary,
              semanticLabel: l10n.tabSettings,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.tr('settings_title'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.tr('settings_description_line1'),
          style: theme.textTheme.bodyMedium,
        ),
        Text(
          l10n.tr('settings_description_line2'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
      BuildContext context,
      String title,
      IconData icon,
      ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Row(
      children: <Widget>[
        Icon(icon, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(
      BuildContext context,
      AppLocalizations l10n,
      ) {
    final ThemeMode mode = _themeService.themeMode;
    final bool highContrast = _themeService.highContrast;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: _buildSectionTitle(
                context,
                l10n.tr('settings_section_appearance'),
                Icons.brightness_medium_rounded,
              ),
            ),
            const Divider(height: 20),
            ListTile(
              title: Text(l10n.tr('settings_theme_mode')),
              subtitle: Text(
                switch (mode) {
                  ThemeMode.system => l10n.tr('settings_theme_system'),
                  ThemeMode.light => l10n.tr('settings_theme_light'),
                  ThemeMode.dark => l10n.tr('settings_theme_dark'),
                },
              ),
            ),
            RadioListTile<ThemeMode>(
              title: Text(l10n.tr('settings_theme_system')),
              value: ThemeMode.system,
              groupValue: mode,
              onChanged: (ThemeMode? v) {
                if (v != null) {
                  _themeService.setThemeMode(v);
                  setState(() {});
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(l10n.tr('settings_theme_light')),
              value: ThemeMode.light,
              groupValue: mode,
              onChanged: (ThemeMode? v) {
                if (v != null) {
                  _themeService.setThemeMode(v);
                  setState(() {});
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(l10n.tr('settings_theme_dark')),
              value: ThemeMode.dark,
              groupValue: mode,
              onChanged: (ThemeMode? v) {
                if (v != null) {
                  _themeService.setThemeMode(v);
                  setState(() {});
                }
              },
            ),
            SwitchListTile(
              title: Text(l10n.tr('settings_theme_high_contrast')),
              value: highContrast,
              onChanged: (bool v) {
                _themeService.setHighContrast(v);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection(
      BuildContext context,
      AppLocalizations l10n,
      ) {
    final Locale current = _localeService.locale;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: _buildSectionTitle(
                context,
                l10n.tr('settings_section_language'),
                Icons.language_rounded,
              ),
            ),
            const Divider(height: 20),
            ListTile(
              title: Text(l10n.tr('settings_language_label')),
            ),
            RadioListTile<String>(
              title: Text(l10n.tr('settings_language_en')),
              value: 'en',
              groupValue: current.languageCode,
              onChanged: (String? code) {
                if (code != null) {
                  _localeService.setLocale(Locale(code));
                  setState(() {});
                }
              },
            ),
            RadioListTile<String>(
              title: Text(l10n.tr('settings_language_hi')),
              value: 'hi',
              groupValue: current.languageCode,
              onChanged: (String? code) {
                if (code != null) {
                  _localeService.setLocale(Locale(code));
                  setState(() {});
                }
              },
            ),
            RadioListTile<String>(
              title: Text(l10n.tr('settings_language_ar')),
              value: 'ar',
              groupValue: current.languageCode,
              onChanged: (String? code) {
                if (code != null) {
                  _localeService.setLocale(Locale(code));
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessibilitySection(
      BuildContext context,
      AppLocalizations l10n,
      ) {
    final TextScalePreset preset = _access.preset;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: _buildSectionTitle(
                context,
                l10n.tr('settings_section_accessibility'),
                Icons.accessibility_new_rounded,
              ),
            ),
            const Divider(height: 20),
            ListTile(
              title: Text(l10n.tr('settings_font_size')),
            ),
            RadioListTile<TextScalePreset>(
              title: Text(l10n.tr('settings_font_small')),
              value: TextScalePreset.small,
              groupValue: preset,
              onChanged: (TextScalePreset? v) {
                if (v != null) {
                  _access.setPreset(v);
                  setState(() {});
                }
              },
            ),
            RadioListTile<TextScalePreset>(
              title: Text(l10n.tr('settings_font_normal')),
              value: TextScalePreset.normal,
              groupValue: preset,
              onChanged: (TextScalePreset? v) {
                if (v != null) {
                  _access.setPreset(v);
                  setState(() {});
                }
              },
            ),
            RadioListTile<TextScalePreset>(
              title: Text(l10n.tr('settings_font_large')),
              value: TextScalePreset.large,
              groupValue: preset,
              onChanged: (TextScalePreset? v) {
                if (v != null) {
                  _access.setPreset(v);
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSection(
      BuildContext context,
      AppLocalizations l10n,
      ) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: _buildSectionTitle(
                context,
                l10n.tr('settings_section_advanced'),
                Icons.tune_rounded,
              ),
            ),
            const Divider(height: 20),

            // Audio & Equalizer entry (Day 18)
            ListTile(
              leading: const Icon(Icons.graphic_eq_rounded),
              title: Text(
                l10n.tr('settings_audio_eq'),
              ),
              subtitle: Text(
                l10n.tr('settings_audio_eq_subtitle'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                  theme.textTheme.bodySmall?.color?.withValues(alpha:0.8),
                ),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const EqScreen(),
                  ),
                );
              },
            ),

            // Quick actions (Day-16)
            ListTile(
              leading: const Icon(Icons.bolt_rounded),
              title: Text(l10n.tr('settings_quick_actions')),
              subtitle: Text(
                l10n.tr('settings_quick_actions_hint'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                  theme.textTheme.bodySmall?.color?.withValues(alpha:0.8),
                ),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Quick actions are automatically registered on compatible devices.',
                    ),
                  ),
                );
              },
            ),

            // Feedback
            ListTile(
              leading: const Icon(Icons.feedback_rounded),
              title: Text(l10n.tr('settings_feedback')),
              onTap: () {
                LogService.instance.log('[Settings] feedback tapped');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.tr('feedback_title'),
                    ),
                  ),
                );
              },
            ),

            // Day-17: Remote control (UI hook only)
            ListTile(
              leading: const Icon(Icons.cast_connected),
              title: Text(l10n.tr('settings_remote_control_title')),
              subtitle: Text(
                l10n.tr('settings_remote_control_subtitle'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                  theme.textTheme.bodySmall?.color?.withValues(alpha:0.8),
                ),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.tr('settings_remote_control_info'),
                    ),
                  ),
                );
              },
            ),

            // Day-17: Cloud sync (UI hook only)
            ListTile(
              leading: const Icon(Icons.cloud_sync_rounded),
              title: Text(l10n.tr('settings_cloud_sync_title')),
              subtitle: Text(
                l10n.tr('settings_cloud_sync_subtitle'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                  theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                ),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.tr('settings_cloud_sync_info'),
                    ),
                  ),
                );
              },
            ),

            // NEW (Day 19): Streaming inspector (debug only)
            if (kDebugMode)
              ListTile(
                leading: const Icon(Icons.waves_rounded),
                title: const Text('Streaming inspector (debug)'),
                subtitle: Text(
                  'Inspect HLS/DASH manifests and ABR decisions.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha:0.8),
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const StreamInspectorScreen(),
                    ),
                  );
                },
              ),

            // Clear diagnostics
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded),
              title: Text(l10n.tr('settings_clear_diagnostics')),
              onTap: () => _confirmClearDiagnostics(context, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearDiagnostics(
      BuildContext context,
      AppLocalizations l10n,
      ) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            l10n.tr('settings_clear_diagnostics_confirm_title'),
          ),
          content: Text(
            l10n.tr('settings_clear_diagnostics_confirm_body'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                l10n.tr('settings_clear_diagnostics_confirm_no'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                l10n.tr('settings_clear_diagnostics_confirm_yes'),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      LogService.instance.log('[Settings] clear diagnostics requested');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diagnostics cleared (mock).'),
          ),
        );
      }
    }
  }

  Widget _buildDebugSection(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha:0.5),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: ListTile(
          leading: Icon(Icons.bug_report_rounded),
          title: Text('Debug: Telemetry / Crash info (placeholder)'),
          subtitle: Text(
            'In debug builds, you can expose telemetry buffer & crash files.',
          ),
        ),
      ),
    );
  }
}
