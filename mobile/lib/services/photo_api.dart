import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/lighting_settings.dart';

class PhotoApi {
  Future<void> upload(File photo) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/photos'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', photo.path));

    final response = await request.send().timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Upload failed (${response.statusCode})');
    }
  }

  Future<File> processOnServer({
    required File photo,
    required LightingSettings settings,
    required String outputPath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/lighting/process'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', photo.path));
    request.fields.addAll({
      'center_x': settings.center.dx.toString(),
      'center_y': settings.center.dy.toString(),
      'radius': settings.radius.toString(),
      'intensity': settings.intensity.toString(),
      'softness': settings.softness.toString(),
      'color_r': _byte(settings.color.r).toString(),
      'color_g': _byte(settings.color.g).toString(),
      'color_b': _byte(settings.color.b).toString(),
    });

    final streamed = await request.send().timeout(const Duration(seconds: 45));
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw HttpException('Processing failed (${streamed.statusCode})');
    }
    final bytes = await streamed.stream.toBytes();
    final file = File(outputPath);
    await file.writeAsBytes(bytes);
    return file;
  }
}

int _byte(double channel) => (channel * 255.0).round().clamp(0, 255);
