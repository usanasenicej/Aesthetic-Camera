import 'dart:io';

class ApiConfig {
  /// Optional hardcoded LAN URL, e.g. `http://192.168.1.10:8000`.
  /// Prefer `--dart-define=API_BASE_URL=http://YOUR_PC_IP:8000` when using a real phone.
  static const String? lanOverride = null;

  static String get baseUrl {
    const fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }
    if (lanOverride != null) {
      return lanOverride!;
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }
}
