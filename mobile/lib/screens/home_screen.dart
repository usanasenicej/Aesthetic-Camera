import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme.dart';
import 'camera_screen.dart';
import 'editor_screen.dart';
import 'physical_lighting_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _importPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditorScreen(imagePath: file.path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LIGHTING STUDIO',
                style: TextStyle(
                  color: StudioTheme.cream,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Studio-inspired lighting with the phone you already have.',
                style: TextStyle(color: StudioTheme.muted, height: 1.4),
              ),
              const SizedBox(height: 28),
              _ModeCard(
                title: 'Physical lighting',
                subtitle: 'Use the flashlight as a portable lamp. Adjust brightness when the phone allows it.',
                icon: Icons.flashlight_on_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PhysicalLightingScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              _ModeCard(
                title: 'Digital lighting',
                subtitle: 'Import a photo, then add a colored spotlight, presets, and soft falloff.',
                icon: Icons.auto_awesome_outlined,
                onTap: () => _importPhoto(context),
              ),
              const SizedBox(height: 14),
              _ModeCard(
                title: 'Capture studio',
                subtitle: 'Take a photo with torch fill, then refine it in the editor.',
                icon: Icons.photo_camera_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CameraScreen(),
                    ),
                  );
                },
              ),
              const Spacer(),
              const Text(
                'Photos stay on this phone. Export writes a new copy and leaves the original alone. '
                'The LED cannot become a colored lamp — color is digital, after capture.',
                style: TextStyle(color: StudioTheme.muted, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StudioTheme.panel,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: StudioTheme.sand.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: StudioTheme.sand),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: StudioTheme.cream,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: StudioTheme.muted, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
