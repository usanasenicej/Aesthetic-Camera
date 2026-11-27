import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/lighting_settings.dart';

class ImageService {
  Future<ui.Image> loadImage(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<File> bakeLighting({
    required String sourcePath,
    required LightingSettings settings,
  }) async {
    final image = await loadImage(sourcePath);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(image.width.toDouble(), image.height.toDouble());
    canvas.drawImage(image, Offset.zero, Paint());
    _paintSpotlight(canvas, size, settings);

    final picture = recorder.endRecording();
    final baked = await picture.toImage(image.width, image.height);
    final bytes = await baked.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      throw StateError('Could not encode the edited photo.');
    }

    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/lighting_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes.buffer.asUint8List());
    image.dispose();
    baked.dispose();
    return file;
  }

  void paintPreview(Canvas canvas, Size size, LightingSettings settings) {
    _paintSpotlight(canvas, size, settings);
  }

  Future<void> saveToGallery(String path) {
    return Gal.putImage(path, album: 'Lighting Studio');
  }

  Future<void> shareFile(String path) {
    return Share.shareXFiles([XFile(path)], text: 'Lighting Studio photo');
  }

  void _paintSpotlight(Canvas canvas, Size size, LightingSettings settings) {
    final center = Offset(
      settings.center.dx * size.width,
      settings.center.dy * size.height,
    );
    final radius = settings.radius * math.max(size.width, size.height);
    final midStop = (1 - settings.softness).clamp(0.08, 0.9);
    final paint = Paint()
      ..blendMode = BlendMode.screen
      ..shader = RadialGradient(
        colors: [
          settings.color.withValues(alpha: settings.intensity),
          settings.color.withValues(alpha: settings.intensity * 0.42),
          settings.color.withValues(alpha: 0),
        ],
        stops: [0, midStop, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawRect(Offset.zero & size, paint);
  }
}
