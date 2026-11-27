import 'package:flutter/material.dart';

class LightingSwatch {
  const LightingSwatch(this.name, this.color);

  final String name;
  final Color color;

  static const palette = [
    LightingSwatch('White', Color(0xFFFFFFFF)),
    LightingSwatch('Warm', Color(0xFFFFE0B2)),
    LightingSwatch('Orange', Color(0xFFFF9800)),
    LightingSwatch('Red', Color(0xFFFF5252)),
    LightingSwatch('Blue', Color(0xFF448AFF)),
    LightingSwatch('Purple', Color(0xFFB388FF)),
    LightingSwatch('Pink', Color(0xFFFF80AB)),
    LightingSwatch('Green', Color(0xFF69F0AE)),
  ];
}

class LightingSettings {
  const LightingSettings({
    this.center = const Offset(0.5, 0.42),
    this.radius = 0.45,
    this.intensity = 0.55,
    this.softness = 0.6,
    this.color = const Color(0xFFFFE0B2),
    this.presetName,
  });

  final Offset center;
  final double radius;
  final double intensity;
  final double softness;
  final Color color;
  final String? presetName;

  LightingSettings copyWith({
    Offset? center,
    double? radius,
    double? intensity,
    double? softness,
    Color? color,
    String? presetName,
    bool clearPreset = false,
  }) {
    return LightingSettings(
      center: center ?? this.center,
      radius: radius ?? this.radius,
      intensity: intensity ?? this.intensity,
      softness: softness ?? this.softness,
      color: color ?? this.color,
      presetName: clearPreset ? null : (presetName ?? this.presetName),
    );
  }

  static const warmPortrait = LightingSettings(
    center: Offset(0.5, 0.38),
    radius: 0.55,
    intensity: 0.58,
    softness: 0.72,
    color: Color(0xFFFFE0B2),
    presetName: 'Warm Portrait',
  );

  static const blueStudio = LightingSettings(
    center: Offset(0.5, 0.5),
    radius: 0.7,
    intensity: 0.46,
    softness: 0.52,
    color: Color(0xFF448AFF),
    presetName: 'Blue Studio',
  );

  static const productSpotlight = LightingSettings(
    center: Offset(0.5, 0.42),
    radius: 0.32,
    intensity: 0.78,
    softness: 0.34,
    color: Color(0xFFFFFFFF),
    presetName: 'Product Spotlight',
  );

  static const presets = [warmPortrait, blueStudio, productSpotlight];

  @override
  bool operator ==(Object other) {
    return other is LightingSettings &&
        other.center == center &&
        other.radius == radius &&
        other.intensity == intensity &&
        other.softness == softness &&
        other.color == color &&
        other.presetName == presetName;
  }

  @override
  int get hashCode => Object.hash(
        center,
        radius,
        intensity,
        softness,
        color,
        presetName,
      );
}

class LightingHistory {
  LightingHistory([LightingSettings? initial])
      : current = initial ?? const LightingSettings();

  LightingSettings current;
  final List<LightingSettings> _undo = [];
  final List<LightingSettings> _redo = [];

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void updateLive(LightingSettings next) {
    current = next;
  }

  void commit(LightingSettings next) {
    if (next == current) {
      return;
    }
    _undo.add(current);
    current = next;
    _redo.clear();
  }

  void undo() {
    if (!canUndo) return;
    _redo.add(current);
    current = _undo.removeLast();
  }

  void redo() {
    if (!canRedo) return;
    _undo.add(current);
    current = _redo.removeLast();
  }

  void reset() {
    commit(const LightingSettings());
  }
}
