import 'package:flutter/material.dart';

import '../models/lighting_settings.dart';
import '../services/image_service.dart';

class SpotlightOverlay extends StatelessWidget {
  const SpotlightOverlay({super.key, required this.settings});

  final LightingSettings settings;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _SpotlightPainter(settings),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter(this.settings);

  final LightingSettings settings;
  final ImageService _images = ImageService();

  @override
  void paint(Canvas canvas, Size size) {
    _images.paintPreview(canvas, size, settings);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.settings != settings;
  }
}
