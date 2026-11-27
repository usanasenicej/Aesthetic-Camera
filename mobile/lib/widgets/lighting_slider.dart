import 'package:flutter/material.dart';

import '../theme.dart';

class LightingSlider extends StatelessWidget {
  const LightingSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.min = 0,
    this.max = 1,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(color: StudioTheme.muted, fontSize: 12)),
            const Spacer(),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(color: StudioTheme.cream, fontSize: 12),
            ),
          ],
        ),
        Slider(
          min: min,
          max: max,
          value: value.clamp(min, max),
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ],
    );
  }
}
