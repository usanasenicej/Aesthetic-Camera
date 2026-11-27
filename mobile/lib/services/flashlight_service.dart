import 'package:flutter/services.dart';

class FlashlightService {
  FlashlightService();

  static const _channel = MethodChannel('aesthetic_camera/flashlight');

  Future<bool> hasTorch() async {
    try {
      return await _channel.invokeMethod<bool>('hasTorch') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> supportsIntensity() async {
    try {
      return await _channel.invokeMethod<bool>('supportsIntensity') ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> setEnabled(bool enabled) {
    return _channel.invokeMethod('setEnabled', {'enabled': enabled});
  }

  Future<void> setIntensity(double intensity) {
    return _channel.invokeMethod('setIntensity', {
      'intensity': intensity.clamp(0.05, 1.0),
    });
  }

  Future<void> turnOff() async {
    try {
      await setEnabled(false);
    } on PlatformException {
      // Best-effort cleanup when leaving the screen.
    }
  }
}
