import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme.dart';
import 'editor_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, this.startWithTorch = false});

  final bool startWithTorch;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;
  bool _busy = false;
  bool _torchOn = false;
  XFile? _lastShot;

  @override
  void initState() {
    super.initState();
    _torchOn = widget.startWithTorch;
    _initFuture = _setupCamera();
  }

  Future<void> _setupCamera() async {
    final cameraStatus = await Permission.camera.request();
    await Permission.photos.request();
    if (!cameraStatus.isGranted) {
      throw Exception('Camera permission is required.');
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
    if (_torchOn) {
      await controller.setFlashMode(FlashMode.torch);
    }
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() => _controller = controller);
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final next = !_torchOn;
    await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
    setState(() => _torchOn = next);
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _busy) {
      return;
    }

    setState(() => _busy = true);
    try {
      final shot = await controller.takePicture();
      await Gal.putImage(shot.path, album: 'Lighting Studio');
      if (!mounted) return;
      setState(() => _lastShot = shot);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to your photo gallery.')),
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

  Future<void> _openEditor() async {
    final shot = _lastShot;
    if (shot == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditorScreen(imagePath: shot.path),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudioTheme.ink,
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString(),
              onRetry: () {
                setState(() => _initFuture = _setupCamera());
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
                      padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back, color: StudioTheme.cream),
                          ),
                          const Text(
                            'CAPTURE',
                            style: TextStyle(
                              color: StudioTheme.cream,
                              letterSpacing: 4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _toggleTorch,
                            icon: Icon(
                              _torchOn ? Icons.flash_on : Icons.flash_off,
                              color: _torchOn ? StudioTheme.sand : StudioTheme.cream,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (_lastShot != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: _openEditor,
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_lastShot!.path),
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Edit lighting',
                                style: TextStyle(color: StudioTheme.cream, fontSize: 12),
                              ),
                            ],
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
                            border: Border.all(color: StudioTheme.cream, width: 4),
                          ),
                          child: Center(
                            child: _busy
                                ? const SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: StudioTheme.sand,
                                    ),
                                  )
                                : Container(
                                    width: 58,
                                    height: 58,
                                    decoration: const BoxDecoration(
                                      color: StudioTheme.cream,
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
            style: const TextStyle(color: StudioTheme.cream),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
