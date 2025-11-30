import 'package:flutter/material.dart';

/// shared/widgets
/// ==============
/// Reusable UI components used across multiple features.
/// This is a very simple example button for Day 1.
class YSPrimaryButton extends StatelessWidget {
  const YSPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
