import 'package:aesthetic_camera/models/lighting_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('palette includes the SRS lighting colors', () {
    expect(
      LightingSwatch.palette.map((swatch) => swatch.name).toList(),
      ['White', 'Warm', 'Orange', 'Red', 'Blue', 'Purple', 'Pink', 'Green'],
    );
  });

  test('MVP presets match the SRS names', () {
    expect(
      LightingSettings.presets.map((preset) => preset.presetName).toList(),
      ['Warm Portrait', 'Blue Studio', 'Product Spotlight'],
    );
  });

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
