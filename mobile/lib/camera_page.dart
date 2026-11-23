import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

import 'photo_api.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  Future<void>? _initFuture;
  String? _error;
  bool _busy = false;
  bool _uploadToBackend = true;
  XFile? _lastShot;

  @override
  void initState() {
    super.initState();
    _initFuture = _setupCamera();
  }

  Future<void> _setupCamera() async {
    final cameraStatus = await Permission.camera.request();
    final photosStatus = await Permission.photos.request();
    if (!cameraStatus.isGranted) {
      throw Exception('Camera permission is required.');
    }
    if (!photosStatus.isGranted && !photosStatus.isLimited) {
      // Saving still works on many devices with add-only access.
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No camera found on this device.');
    }

    final rear = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      rear,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
    });
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _busy) {
      return;
    }

    setState(() => _busy = true);
    try {
      final shot = await controller.takePicture();
      await Gal.putImage(shot.path, album: 'Aesthetic Camera');
      if (_uploadToBackend) {
        await PhotoApi().upload(File(shot.path));
      }
      if (!mounted) return;
      setState(() => _lastShot = shot);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _uploadToBackend
                ? 'Saved on this phone and uploaded.'
                : 'Saved to your photo gallery.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save photo: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            _error = snapshot.error.toString();
            return _ErrorView(
              message: _error!,
              onRetry: () {
                setState(() {
                  _initFuture = _setupCamera();
                });
              },
            );
          }

          final controller = _controller;
          if (controller == null || !controller.value.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller),
              const _Vignette(),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          const Text(
                            'AESTHETIC',
                            style: TextStyle(
                              color: Color(0xFFF4EDE4),
                              letterSpacing: 4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          FilterChip(
                            selected: _uploadToBackend,
                            label: const Text('Upload'),
                            onSelected: (value) {
                              setState(() => _uploadToBackend = value);
                            },
                            selectedColor: const Color(0xFFD7B899),
                            backgroundColor: Colors.black54,
                            labelStyle: TextStyle(
                              color: _uploadToBackend
                                  ? const Color(0xFF111111)
                                  : const Color(0xFFF4EDE4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (_lastShot != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_lastShot!.path),
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: GestureDetector(
                        onTap: _busy ? null : _takePicture,
                        child: Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFF4EDE4),
                              width: 4,
                            ),
                          ),
                          child: Center(
                            child: _busy
                                ? const SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFD7B899),
                                    ),
                                  )
                                : Container(
                                    width: 58,
                                    height: 58,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF4EDE4),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Vignette extends StatelessWidget {
  const _Vignette();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.45),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.55),
            ],
            stops: const [0, 0.35, 1],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFF4EDE4)),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
