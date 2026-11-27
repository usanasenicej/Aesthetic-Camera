import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/flashlight_service.dart';
import '../theme.dart';
import 'camera_screen.dart';

class PhysicalLightingScreen extends StatefulWidget {
  const PhysicalLightingScreen({super.key});

  @override
  State<PhysicalLightingScreen> createState() => _PhysicalLightingScreenState();
}

class _PhysicalLightingScreenState extends State<PhysicalLightingScreen> {
  final _flashlight = FlashlightService();
  bool _ready = false;
  bool _hasTorch = false;
  bool _supportsIntensity = false;
  bool _on = false;
  double _intensity = 0.8;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final hasTorch = await _flashlight.hasTorch();
      final supportsIntensity = hasTorch && await _flashlight.supportsIntensity();
      if (!mounted) return;
      setState(() {
        _hasTorch = hasTorch;
        _supportsIntensity = supportsIntensity;
        _ready = true;
        _error = hasTorch ? null : 'This phone does not expose a controllable flashlight.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _ready = true;
        _error = 'Could not access the flashlight: $error';
      });
    }
  }

  Future<void> _setEnabled(bool enabled) async {
    setState(() => _on = enabled);
    try {
      await _flashlight.setEnabled(enabled);
      if (enabled && _supportsIntensity) {
        await _flashlight.setIntensity(_intensity);
      }
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() => _on = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Could not toggle the flashlight.')),
      );
    }
  }

  Future<void> _setIntensity(double value) async {
    setState(() => _intensity = value);
    if (!_on) return;
    try {
      await _flashlight.setIntensity(value);
    } on PlatformException {
      // Some devices accept on/off only.
    }
  }

  @override
  void dispose() {
    _flashlight.turnOff();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Physical lighting')),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _on
                              ? Color.lerp(StudioTheme.sand, Colors.white, _intensity)
                              : const Color(0xFF2A2A2A),
                          boxShadow: _on
                              ? [
                                  BoxShadow(
                                    color: StudioTheme.sand.withValues(alpha: 0.35 + _intensity * 0.4),
                                    blurRadius: 48 + _intensity * 40,
                                  ),
                                ]
                              : const [],
                        ),
                        child: Icon(
                          _on ? Icons.flashlight_on : Icons.flashlight_off,
                          size: 64,
                          color: _on ? StudioTheme.ink : StudioTheme.muted,
                        ),
                      ),
                    ),
                  ),
                  if (_error != null)
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: StudioTheme.muted),
                    ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Flashlight'),
                    subtitle: const Text('Hold the phone to light a subject'),
                    value: _on,
                    onChanged: _hasTorch ? _setEnabled : null,
                  ),
                  if (_supportsIntensity) ...[
                    Row(
                      children: [
                        const Text('Brightness', style: TextStyle(color: StudioTheme.muted)),
                        Expanded(
                          child: Slider(
                            value: _intensity,
                            onChanged: _setIntensity,
                          ),
                        ),
                      ],
                    ),
                  ] else if (_hasTorch)
                    const Text(
                      'This device can turn the torch on or off, but not change its brightness.',
                      style: TextStyle(color: StudioTheme.muted, fontSize: 12),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'The LED stays white. Colored lighting is applied later in Digital lighting — a phone cannot become an RGB studio light.',
                    style: TextStyle(color: StudioTheme.muted, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await _flashlight.turnOff();
                        if (!context.mounted) return;
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CameraScreen(startWithTorch: true),
                          ),
                        );
                      },
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Open camera with torch'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
