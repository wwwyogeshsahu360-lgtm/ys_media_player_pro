// lib/features/audio_dsp/presentation/widgets/vu_widget.dart
import 'package:flutter/material.dart';

import '../../domain/audio_dsp_state.dart';

/// Simple stereo VU meter.
class VUWidget extends StatelessWidget {
  const VUWidget({
    super.key,
    required this.state,
  });

  final AudioDspState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Semantics(
      label: 'Audio level meter',
      value:
      'Left ${(state.leftRms * 100).toStringAsFixed(0)} percent, Right ${(state.rightRms * 100).toStringAsFixed(0)} percent',
      child: Row(
        children: <Widget>[
          Expanded(
            child: _buildBar(
              context,
              label: 'L',
              rms: state.leftRms,
              peak: state.leftPeak,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildBar(
              context,
              label: 'R',
              rms: state.rightRms,
              peak: state.rightPeak,
              color: cs.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(
      BuildContext context, {
        required String label,
        required double rms,
        required double peak,
        required Color color,
      }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$label ${(rms * 100).toStringAsFixed(0)}%',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 16,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              FractionallySizedBox(
                widthFactor: rms.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              // Peak marker:
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: peak.clamp(0.0, 1.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 2,
                      height: 16,
                      color: cs.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
