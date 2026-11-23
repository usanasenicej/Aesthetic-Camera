import 'dart:io';

class ApiConfig {
  /// Set this to your computer's LAN IP when testing on a real phone, e.g.
  /// `http://192.168.1.10:8000`
  static const String? lanOverride = null;

  static String get baseUrl {
    if (lanOverride != null) {
      return lanOverride!;
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }
}
