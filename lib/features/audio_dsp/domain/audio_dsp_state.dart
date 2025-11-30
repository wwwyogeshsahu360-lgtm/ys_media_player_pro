// lib/features/audio_dsp/domain/audio_dsp_state.dart
import 'package:equatable/equatable.dart';

/// Snapshot of the current DSP / meter state.
///
/// This is published on IAudioDspEngine.stateStream and is consumed by
/// VU / visualizer widgets and other UI.
class AudioDspState extends Equatable {
  final double leftRms;
  final double rightRms;
  final double leftPeak;
  final double rightPeak;

  /// Normalized spectrum magnitudes 0..1 (e.g. 32 or 64 bins).
  final List<double> spectrum;

  final String? presetId;
  final String? presetName;

  final bool isProcessing;
  final bool limiterEnabled;
  final DateTime timestamp;

  const AudioDspState({
    required this.leftRms,
    required this.rightRms,
    required this.leftPeak,
    required this.rightPeak,
    required this.spectrum,
    required this.isProcessing,
    required this.limiterEnabled,
    required this.timestamp,
    this.presetId,
    this.presetName,
  });

  factory AudioDspState.initial() => AudioDspState(
    leftRms: 0,
    rightRms: 0,
    leftPeak: 0,
    rightPeak: 0,
    spectrum: const <double>[],
    isProcessing: false,
    limiterEnabled: false,
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
  );

  AudioDspState copyWith({
    double? leftRms,
    double? rightRms,
    double? leftPeak,
    double? rightPeak,
    List<double>? spectrum,
    String? presetId,
    String? presetName,
    bool? isProcessing,
    bool? limiterEnabled,
    DateTime? timestamp,
  }) {
    return AudioDspState(
      leftRms: leftRms ?? this.leftRms,
      rightRms: rightRms ?? this.rightRms,
      leftPeak: leftPeak ?? this.leftPeak,
      rightPeak: rightPeak ?? this.rightPeak,
      spectrum: spectrum ?? this.spectrum,
      presetId: presetId ?? this.presetId,
      presetName: presetName ?? this.presetName,
      isProcessing: isProcessing ?? this.isProcessing,
      limiterEnabled: limiterEnabled ?? this.limiterEnabled,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'leftRms': leftRms,
    'rightRms': rightRms,
    'leftPeak': leftPeak,
    'rightPeak': rightPeak,
    'spectrum': spectrum,
    'presetId': presetId,
    'presetName': presetName,
    'isProcessing': isProcessing,
    'limiterEnabled': limiterEnabled,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory AudioDspState.fromJson(Map<String, dynamic> json) => AudioDspState(
    leftRms: (json['leftRms'] as num?)?.toDouble() ?? 0,
    rightRms: (json['rightRms'] as num?)?.toDouble() ?? 0,
    leftPeak: (json['leftPeak'] as num?)?.toDouble() ?? 0,
    rightPeak: (json['rightPeak'] as num?)?.toDouble() ?? 0,
    spectrum: (json['spectrum'] as List<dynamic>?)
        ?.map((dynamic v) => (v as num).toDouble())
        .toList() ??
        const <double>[],
    presetId: json['presetId'] as String?,
    presetName: json['presetName'] as String?,
    isProcessing: json['isProcessing'] as bool? ?? false,
    limiterEnabled: json['limiterEnabled'] as bool? ?? false,
    timestamp: DateTime.fromMillisecondsSinceEpoch(
      json['timestamp'] as int? ?? 0,
    ),
  );

  @override
  List<Object?> get props => <Object?>[
    leftRms,
    rightRms,
    leftPeak,
    rightPeak,
    spectrum,
    presetId,
    presetName,
    isProcessing,
    limiterEnabled,
    timestamp,
  ];
}
