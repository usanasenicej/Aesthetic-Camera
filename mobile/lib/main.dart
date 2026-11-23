import 'package:flutter/material.dart';

import 'camera_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AestheticCameraApp());
}

class AestheticCameraApp extends StatelessWidget {
  const AestheticCameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aesthetic Camera',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD7B899),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF111111),
        useMaterial3: true,
      ),
      home: const CameraPage(),
    );
  }
}
