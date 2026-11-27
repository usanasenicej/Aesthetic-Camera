import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/lighting_settings.dart';
import '../theme.dart';
import '../widgets/spotlight_overlay.dart';
import 'editor_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, this.startWithTorch = false});

  final bool startWithTorch;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  Future<void>? _initFuture;
  bool _busy = false;
  bool _torchOn = false;
  bool _torchSupported = false;
  bool _showGuide = false;
  LightingSettings _guide = LightingSettings.warmPortrait;
  Offset? _focusMark;
  XFile? _lastShot;

  @override
  void initState() {
    super.initState();
    _torchOn = widget.startWithTorch;
    _initFuture = _setupCamera();
  }

  Future<void> _setupCamera({int? preferredIndex}) async {
    final cameraStatus = await Permission.camera.request();
    await Permission.photos.request();
    if (!cameraStatus.isGranted) {
      throw Exception('Camera permission is required.');
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No camera found on this device.');
    }

    final index = (preferredIndex ?? _preferredRearIndex(cameras)).clamp(0, cameras.length - 1);
    await _bindCamera(cameras, index);
  }

  int _preferredRearIndex(List<CameraDescription> cameras) {
    final rear = cameras.indexWhere((camera) => camera.lensDirection == CameraLensDirection.back);
    return rear >= 0 ? rear : 0;
  }

  Future<void> _bindCamera(List<CameraDescription> cameras, int index) async {
    final previous = _controller;
    _controller = null;
    await previous?.dispose();

    final description = cameras[index];
    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller.initialize();
    await controller.setFocusMode(FocusMode.auto);
    await controller.setExposureMode(ExposureMode.auto);

    var torchSupported = description.lensDirection == CameraLensDirection.back;
    var torchOn = _torchOn && torchSupported;
    if (torchOn) {
      try {
        await controller.setFlashMode(FlashMode.torch);
      } catch (_) {
        torchSupported = false;
        torchOn = false;
      }
    } else {
      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {
        torchSupported = false;
      }
    }

    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _cameras = cameras;
      _cameraIndex = index;
      _controller = controller;
      _torchSupported = torchSupported;
      _torchOn = torchOn;
      _focusMark = null;
    });
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _busy) return;
    setState(() {
      _initFuture = _bindCamera(_cameras, (_cameraIndex + 1) % _cameras.length);
    });
    await _initFuture;
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || !_torchSupported) {
      return;
    }
    final next = !_torchOn;
    try {
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      setState(() => _torchOn = next);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _torchSupported = false;
        _torchOn = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Torch is not available on this camera: $error')),
      );
    }
  }

  Future<void> _onTapPreview(TapUpDetails details, BoxConstraints constraints) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final point = Offset(
      (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0),
      (details.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0),
    );
    setState(() => _focusMark = details.localPosition);
    try {
      await controller.setFocusPoint(point);
      await controller.setExposurePoint(point);
      await controller.setFocusMode(FocusMode.auto);
    } catch (_) {
      // Some devices expose preview but not manual focus points.
    }
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
        SnackBar(
          content: const Text('Original saved. Customize lighting next.'),
          action: SnackBarAction(label: 'Edit', onPressed: _openEditor),
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

  Future<void> _openEditor() async {
    final shot = _lastShot;
    if (shot == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditorScreen(imagePath: shot.path, initialSettings: _guide),
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

          return LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTapUp: (details) => _onTapPreview(details, constraints),
                    child: CameraPreview(controller),
                  ),
                  const _Vignette(),
                  if (_showGuide) SpotlightOverlay(settings: _guide),
                  if (_focusMark != null)
                    Positioned(
                      left: _focusMark!.dx - 22,
                      top: _focusMark!.dy - 22,
                      child: IgnorePointer(
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            border: Border.all(color: StudioTheme.sand, width: 1.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
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
                                tooltip: _showGuide ? 'Hide lighting guide' : 'Show lighting guide',
                                onPressed: () => setState(() => _showGuide = !_showGuide),
                                icon: Icon(
                                  Icons.auto_awesome_outlined,
                                  color: _showGuide ? StudioTheme.sand : StudioTheme.cream,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Switch camera',
                                onPressed: _cameras.length > 1 ? _switchCamera : null,
                                icon: const Icon(Icons.cameraswitch_outlined, color: StudioTheme.cream),
                              ),
                              IconButton(
                                tooltip: _torchSupported
                                    ? 'Toggle flashlight'
                                    : 'No flashlight on this camera',
                                onPressed: _torchSupported ? _toggleTorch : null,
                                icon: Icon(
                                  _torchOn ? Icons.flash_on : Icons.flash_off,
                                  color: !_torchSupported
                                      ? StudioTheme.muted
                                      : (_torchOn ? StudioTheme.sand : StudioTheme.cream),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_showGuide)
                          SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              children: [
                                for (final preset in LightingSettings.presets)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(preset.presetName ?? ''),
                                      selected: _guide.presetName == preset.presetName,
                                      onSelected: (_) => setState(() => _guide = preset),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        Text(
                          _torchSupported
                              ? 'Tap to focus. Torch stays white; color is added in the editor.'
                              : 'Tap to focus. This camera has no torch — use Physical lighting or the rear camera.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: StudioTheme.cream, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
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
