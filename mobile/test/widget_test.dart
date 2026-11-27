import 'package:aesthetic_camera/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home offers physical and digital lighting', (tester) async {
    await tester.pumpWidget(const AestheticCameraApp());
    expect(find.text('LIGHTING STUDIO'), findsOneWidget);
    expect(find.text('Physical lighting'), findsOneWidget);
    expect(find.text('Digital lighting'), findsOneWidget);
    expect(find.text('Capture studio'), findsOneWidget);
  });
}
