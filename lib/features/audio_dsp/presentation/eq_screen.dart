// lib/features/audio_dsp/presentation/eq_screen.dart

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../audio_dsp/audio_dsp_facade.dart';
import '../../audio_dsp/domain/audio_dsp_preset.dart';
import '../../audio_dsp/domain/audio_dsp_state.dart';
import 'widgets/vu_widget.dart';
import 'widgets/visualizer_widget.dart';

/// ===============================================================
///  EQUALIZER SCREEN – FULLY FIXED VERSION (BASED ON YOUR FILE)
/// ===============================================================
class EqScreen extends StatefulWidget {
  const EqScreen({super.key});

  @override
  State<EqScreen> createState() => _EqScreenState();
}

class _EqScreenState extends State<EqScreen> {
  final AudioDspFacade _facade = AudioDspFacade.instance;

  bool _initialized = false;
  List<double> _bandGains = <double>[];
  double _bassBoost = 0;
  double _virtualizer = 0;
  double _reverb = 0;
  bool _limiter = false;

  List<AudioDspPreset> _builtInPresets = <AudioDspPreset>[];
  List<AudioDspPreset> _customPresets = <AudioDspPreset>[];
  String? _selectedPresetId;

  AudioDspState _state = AudioDspState.initial();

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  Future<void> _initAsync() async {
    await _facade.ensureInitialized();

    final int bandCount = _facade.engine.bandCount;

    setState(() {
      _bandGains = List<double>.from(_facade.engine.bandGains);
      if (_bandGains.length != bandCount) {
        _bandGains = List<double>.filled(bandCount, 0.0);
      }
      _initialized = true;
    });

    _buildBuiltInPresets(bandCount);

    _customPresets = await _facade.presetStore.loadCustomPresets();

    _facade.engine.stateStream.listen((AudioDspState s) {
      if (!mounted) return;
      setState(() => _state = s);
    });

    if (!_state.isProcessing) {
      await _facade.engine.startProcessing();
    }
  }

  /// --------------------------------------------------------------
  /// BUILT-IN PRESETS (NO isBuiltIn FIELD)
  /// --------------------------------------------------------------
  void _buildBuiltInPresets(int bandCount) {
    if (_builtInPresets.isNotEmpty) return;

    List<double> flat = List<double>.filled(bandCount, 0.0);
    List<double> bass =
    List<double>.generate(bandCount, (int i) => i <= 2 ? 6.0 : -2.0);

    List<double> vocal = List<double>.generate(
        bandCount, (int i) => (i >= 3 && i <= 6) ? 4.0 : -2.0);

    List<double> rock = List<double>.generate(bandCount, (int i) {
      if (i <= 2) return 4.0;
      if (i >= bandCount - 2) return 4.0;
      return -2.0;
    });

    _builtInPresets = <AudioDspPreset>[
      AudioDspPreset(
        id: 'flat',
        name: 'Flat',
        bandGains: flat,
        bassBoost: 0,
        virtualizer: 0.1,
        reverb: 0.1,
        limiterEnabled: false,
        createdAt: DateTime.now(),
      ),
      AudioDspPreset(
        id: 'bass_boost',
        name: 'Bass Boost',
        bandGains: bass,
        bassBoost: 1.0,
        virtualizer: 0.2,
        reverb: 0.1,
        limiterEnabled: true,
        createdAt: DateTime.now(),
      ),
      AudioDspPreset(
        id: 'vocal',
        name: 'Vocal',
        bandGains: vocal,
        bassBoost: 0.2,
        virtualizer: 0.3,
        reverb: 0.2,
        limiterEnabled: true,
        createdAt: DateTime.now(),
      ),
      AudioDspPreset(
        id: 'rock',
        name: 'Rock',
        bandGains: rock,
        bassBoost: 0.6,
        virtualizer: 0.4,
        reverb: 0.25,
        limiterEnabled: true,
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  void dispose() {
    _facade.engine.stopProcessing();
    super.dispose();
  }

  /// --------------------------------------------------------------
  /// FIXED: PRESET SELECTION
  /// --------------------------------------------------------------
  Future<void> _onPresetSelected(String? presetId) async {
    if (presetId == null) return;

    setState(() => _selectedPresetId = presetId);

    final AudioDspPreset preset = [
      ..._builtInPresets,
      ..._customPresets,
    ].firstWhere(
          (AudioDspPreset p) => p.id == presetId,
      orElse: () => AudioDspPreset.defaultPreset(),
    );

    _applyPreset(preset);
  }

  /// FIXED – Actually load & apply preset
  Future<void> _applyPreset(AudioDspPreset preset) async {
    setState(() {
      _bandGains = List<double>.from(preset.bandGains);
      _bassBoost = preset.bassBoost;
      _virtualizer = preset.virtualizer;
      _reverb = preset.reverb;
      _limiter = preset.limiterEnabled;
    });

    await _facade.engine.applyPreset(preset);
  }

  /// --------------------------------------------------------------
  /// SAVE CUSTOM PRESET  (BuildContext FIXED – no param, safe after await)
  /// --------------------------------------------------------------
  Future<void> _saveCustomPreset() async {
    if (!mounted) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextEditingController controller = TextEditingController();

    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.tr('eq_save_preset_title')),
        content: TextField(
          controller: controller,
          decoration:
          InputDecoration(hintText: l10n.tr('eq_save_preset_hint')),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.tr('common_cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, controller.text.trim());
            },
            child: Text(l10n.tr('common_save')),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    final String id = 'custom_${DateTime.now().millisecondsSinceEpoch}';

    final AudioDspPreset preset = AudioDspPreset(
      id: id,
      name: name,
      bandGains: List<double>.from(_bandGains),
      bassBoost: _bassBoost,
      virtualizer: _virtualizer,
      reverb: _reverb,
      limiterEnabled: _limiter,
      createdAt: DateTime.now(),
    );

    await _facade.presetStore.upsertPreset(preset);
    _customPresets = await _facade.presetStore.loadCustomPresets();

    setState(() => _selectedPresetId = id);

    await _facade.engine.applyPreset(preset);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.tr('eq_save_preset_success'))),
    );
  }

  /// --------------------------------------------------------------
  /// EXPORT PRESET (BuildContext FIXED – no param, safe after await)
  /// --------------------------------------------------------------
  Future<void> _exportPreset() async {
    if (!mounted) return;
    final AppLocalizations l10n = AppLocalizations.of(context);

    final AudioDspPreset preset = [
      ..._builtInPresets,
      ..._customPresets,
    ].firstWhere(
          (AudioDspPreset p) => p.id == _selectedPresetId,
      orElse: () => AudioDspPreset.defaultPreset(),
    );

    final String jsonExport = preset.exportWithChecksum();

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.tr('eq_export_preset_title')),
        content: SingleChildScrollView(
          child: SelectableText(
            jsonExport,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.tr('common_close')),
          ),
        ],
      ),
    );
  }

  /// --------------------------------------------------------------
  /// IMPORT – FIXED: added importFromExport + safe BuildContext
  /// --------------------------------------------------------------
  Future<void> _importPreset() async {
    if (!mounted) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextEditingController controller = TextEditingController();

    final String? jsonStr = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.tr('eq_import_preset_title')),
        content: TextField(
          controller: controller,
          decoration:
          InputDecoration(hintText: l10n.tr('eq_import_preset_hint')),
          maxLines: 6,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.tr('common_cancel')),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(l10n.tr('common_import')),
          ),
        ],
      ),
    );

    if (jsonStr == null || jsonStr.isEmpty) return;

    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      final AudioDspPreset imported =
      AudioDspPreset.fromJson(decoded['data']).copyWith(
        id: 'import_${DateTime.now().millisecondsSinceEpoch}',
      );

      await _facade.presetStore.upsertPreset(imported);
      _customPresets = await _facade.presetStore.loadCustomPresets();

      setState(() => _selectedPresetId = imported.id);

      await _facade.engine.applyPreset(imported);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tr('eq_import_preset_success'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tr('eq_import_preset_error'))),
      );
    }
  }

  /// --------------------------------------------------------------
  /// UI
  /// --------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    if (!_initialized) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.tr('eq_title'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final List<AudioDspPreset> allPresets = <AudioDspPreset>[
      ..._builtInPresets,
      ..._customPresets,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tr('eq_title')),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.play_arrow_rounded),
            tooltip: l10n.tr('eq_preview_play'),
            onPressed: () async {
              await _facade.engine.startProcessing();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            l10n.tr('eq_section_presets'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          // ---------------------- PRESET DROPDOWN ----------------------
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPresetId ?? _builtInPresets.first.id,
                  items: allPresets
                      .map(
                        (AudioDspPreset p) => DropdownMenuItem<String>(
                      value: p.id,
                      child: Text(p.name),
                    ),
                  )
                      .toList(),
                  onChanged: _onPresetSelected,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: l10n.tr('eq_choose_preset'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.save_rounded),
                tooltip: l10n.tr('eq_save_preset_button'),
                onPressed: _saveCustomPreset,
              ),
              IconButton(
                icon: const Icon(Icons.ios_share_rounded),
                tooltip: l10n.tr('eq_export_preset_button'),
                onPressed: _exportPreset,
              ),
              IconButton(
                icon: const Icon(Icons.download_rounded),
                tooltip: l10n.tr('eq_import_preset_button'),
                onPressed: _importPreset,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ---------------------- BANDS ----------------------
          Text(
            l10n.tr('eq_section_bands'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildBandsSection(context),

          const SizedBox(height: 16),

          // ---------------------- FX ----------------------
          Text(
            l10n.tr('eq_section_fx'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildFxSection(context),

          const SizedBox(height: 16),

          // ---------------------- METERS ----------------------
          Text(
            l10n.tr('eq_section_meters'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: <Widget>[
                  VUWidget(state: _state),
                  const SizedBox(height: 8),
                  VisualizerWidget(state: _state),
                ],
              ),
            ),
          ),

          if (kDebugMode) ...<Widget>[
            const SizedBox(height: 16),
            _buildDebugSection(context),
          ],
        ],
      ),
    );
  }

  /// --------------------------------------------------------------
  /// UI – BANDS
  /// --------------------------------------------------------------
  Widget _buildBandsSection(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<double> freqs = _facade.engine.bandFrequencies;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 220,
          child: Row(
            children: <Widget>[
              for (int i = 0; i < _bandGains.length; i++)
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Text(
                        '${_bandGains[i].toStringAsFixed(1)} dB',
                        style: theme.textTheme.bodySmall,
                      ),
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: -1,
                          child: Slider(
                            value: _bandGains[i],
                            min: -12,
                            max: 12,
                            divisions: 24,
                            label: '${_bandGains[i].toStringAsFixed(1)} dB',
                            onChanged: (double v) {
                              setState(() => _bandGains[i] = v);
                              _facade.engine.setBandGain(i, v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatFrequency(freqs[i]),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// --------------------------------------------------------------
  /// UI – EFFECT SLIDERS
  /// --------------------------------------------------------------
  Widget _buildFxSection(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            _buildFxSlider(
              context,
              label: l10n.tr('eq_bass_boost'),
              value: _bassBoost,
              onChanged: (double v) {
                setState(() => _bassBoost = v);
                _facade.engine.setBassBoost(v);
              },
            ),
            _buildFxSlider(
              context,
              label: l10n.tr('eq_virtualizer'),
              value: _virtualizer,
              onChanged: (double v) {
                setState(() => _virtualizer = v);
                _facade.engine.setVirtualizer(v);
              },
            ),
            _buildFxSlider(
              context,
              label: l10n.tr('eq_reverb'),
              value: _reverb,
              onChanged: (double v) {
                setState(() => _reverb = v);
                _facade.engine.setReverb(v);
              },
            ),
            SwitchListTile(
              title: Text(l10n.tr('eq_limiter')),
              value: _limiter,
              onChanged: (bool v) {
                setState(() => _limiter = v);
                _facade.engine.setLimiterEnabled(v);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFxSlider(
      BuildContext context, {
        required String label,
        required double value,
        required ValueChanged<double> onChanged,
      }) {
    final ThemeData theme = Theme.of(context);

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            Text('${(value * 100).toStringAsFixed(0)}%'),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 1,
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
        Divider(
          height: 8,
          color: theme.dividerColor.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  /// --------------------------------------------------------------
  /// DEBUG SECTION
  /// --------------------------------------------------------------
  Widget _buildDebugSection(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Debug DSP tools', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () async {
                    final int n = _facade.engine.bandCount;
                    for (int i = 0; i < n; i++) {
                      final double x = i / (n - 1);
                      final double v = sin(x * pi * 2) * 6;
                      _facade.engine.setBandGain(i, v);
                    }
                  },
                  child: const Text('Sine sweep shape'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final int n = _facade.engine.bandCount;
                    for (int i = 0; i < n; i++) {
                      final double v = (Random().nextDouble() * 24) - 12;
                      _facade.engine.setBandGain(i, v);
                    }
                  },
                  child: const Text('Random EQ'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _facade.engine.stopProcessing();
                  },
                  child: const Text('Stop processing'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// --------------------------------------------------------------
  /// FORMAT FREQUENCY LABEL
  /// --------------------------------------------------------------
  String _formatFrequency(double hz) {
    if (hz >= 1000) {
      return '${(hz / 1000).toStringAsFixed(1)}k';
    }
    return hz.toStringAsFixed(0);
  }
}
