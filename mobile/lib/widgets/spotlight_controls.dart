import 'package:flutter/material.dart';

import '../models/lighting_settings.dart';
import '../theme.dart';
import 'color_picker.dart';
import 'lighting_slider.dart';

class SpotlightControls extends StatelessWidget {
  const SpotlightControls({
    super.key,
    required this.settings,
    required this.onLiveChange,
    required this.onCommit,
  });

  final LightingSettings settings;
  final ValueChanged<LightingSettings> onLiveChange;
  final ValueChanged<LightingSettings> onCommit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Color',
          style: TextStyle(color: StudioTheme.muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        LightingColorPicker(
          selected: settings.color,
          onSelected: (swatch) {
            onCommit(settings.copyWith(color: swatch.color, clearPreset: true));
          },
        ),
        LightingSlider(
          label: 'Intensity',
          value: settings.intensity,
          onChanged: (value) {
            onLiveChange(settings.copyWith(intensity: value, clearPreset: true));
          },
          onChangeEnd: (value) {
            onCommit(settings.copyWith(intensity: value, clearPreset: true));
          },
        ),
        LightingSlider(
          label: 'Size',
          value: settings.radius,
          min: 0.12,
          max: 0.95,
          onChanged: (value) {
            onLiveChange(settings.copyWith(radius: value, clearPreset: true));
          },
          onChangeEnd: (value) {
            onCommit(settings.copyWith(radius: value, clearPreset: true));
          },
        ),
        LightingSlider(
          label: 'Softness',
          value: settings.softness,
          onChanged: (value) {
            onLiveChange(settings.copyWith(softness: value, clearPreset: true));
          },
          onChangeEnd: (value) {
            onCommit(settings.copyWith(softness: value, clearPreset: true));
          },
        ),
      ],
    );
  }
}
