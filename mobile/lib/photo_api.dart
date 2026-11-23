import 'dart:io';

import 'package:http/http.dart' as http;

import 'config.dart';

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
}
