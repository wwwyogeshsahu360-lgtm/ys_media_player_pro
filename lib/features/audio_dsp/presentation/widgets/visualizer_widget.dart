// lib/features/audio_dsp/presentation/widgets/visualizer_widget.dart
import 'package:flutter/material.dart';

import '../../domain/audio_dsp_state.dart';

/// Simple spectrum visualizer drawing a polyline of magnitudes.
///
/// This is purposely light – no heavy gradients or shadows – to keep
/// performance friendly.
class VisualizerWidget extends StatelessWidget {
  const VisualizerWidget({
    super.key,
    required this.state,
  });

  final AudioDspState state;

  @override
  Widget build(BuildContext context) {
    final List<double> spectrum = state.spectrum;
    if (spectrum.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text('No signal')),
      );
    }

    return Semantics(
      label: 'Audio spectrum visualizer',
      child: SizedBox(
        height: 100,
        child: CustomPaint(
          painter: _SpectrumPainter(spectrum: spectrum),
        ),
      ),
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  _SpectrumPainter({required this.spectrum});

  final List<double> spectrum;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    for (int i = 0; i < spectrum.length; i++) {
      final double t = i / (spectrum.length - 1);
      final double x = t * size.width;
      final double mag = spectrum[i].clamp(0.0, 1.0);
      final double y = size.height * (1 - mag);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SpectrumPainter oldDelegate) {
    return oldDelegate.spectrum != spectrum;
  }
}
