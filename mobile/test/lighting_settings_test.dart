import 'package:aesthetic_camera/models/lighting_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('undo and redo restore lighting settings', () {
    final history = LightingHistory();
    history.commit(LightingSettings.blueStudio);
    history.commit(LightingSettings.productSpotlight);
    expect(history.current, LightingSettings.productSpotlight);

    history.undo();
    expect(history.current, LightingSettings.blueStudio);

    history.redo();
    expect(history.current, LightingSettings.productSpotlight);

    history.reset();
    expect(history.current, const LightingSettings());
  });
}
