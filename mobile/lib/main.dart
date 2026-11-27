import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AestheticCameraApp());
}

class AestheticCameraApp extends StatelessWidget {
  const AestheticCameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lighting Studio',
      debugShowCheckedModeBanner: false,
      theme: StudioTheme.dark(),
      home: const HomeScreen(),
    );
  }
}
