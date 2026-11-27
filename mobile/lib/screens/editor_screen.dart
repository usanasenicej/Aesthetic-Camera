import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/lighting_settings.dart';
import '../services/image_service.dart';
import '../services/photo_api.dart';
import '../theme.dart';
import '../widgets/spotlight_controls.dart';
import '../widgets/spotlight_overlay.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.imagePath,
    this.initialSettings,
  });

  final String imagePath;
  final LightingSettings? initialSettings;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final LightingHistory _history =
      LightingHistory(widget.initialSettings ?? LightingSettings.warmPortrait);
  final _images = ImageService();
  final _api = PhotoApi();
  bool _busy = false;
  bool _useServer = false;
  Offset? _dragStartCenter;

  LightingSettings get _settings => _history.current;

  void _live(LightingSettings next) {
    setState(() => _history.updateLive(next));
  }

  void _commit(LightingSettings next) {
    setState(() => _history.commit(next));
  }

  Future<void> _export({required bool share}) async {
    setState(() => _busy = true);
    try {
      File output;
      if (_useServer) {
        final directory = await getTemporaryDirectory();
        output = await _api.processOnServer(
          photo: File(widget.imagePath),
          settings: _settings,
          outputPath: '${directory.path}/server_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } else {
        output = await _images.bakeLighting(
          sourcePath: widget.imagePath,
          settings: _settings,
        );
      }
      await _images.saveToGallery(output.path);
      if (share) {
        await _images.shareFile(output.path);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            share
                ? 'Saved a new copy and opened share.'
                : 'Saved a new copy. The original photo is unchanged.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not export: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital lighting'),
        actions: [
          IconButton(
            tooltip: 'Undo',
            onPressed: _history.canUndo
                ? () => setState(_history.undo)
                : null,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Redo',
            onPressed: _history.canRedo
                ? () => setState(_history.redo)
                : null,
            icon: const Icon(Icons.redo),
          ),
          IconButton(
            tooltip: 'Reset',
            onPressed: () => setState(_history.reset),
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onPanStart: (details) {
                        _dragStartCenter = _settings.center;
                      },
                      onPanUpdate: (details) {
                        final dx = details.delta.dx / constraints.maxWidth;
                        final dy = details.delta.dy / constraints.maxHeight;
                        _live(
                          _settings.copyWith(
                            center: Offset(
                              (_settings.center.dx + dx).clamp(0.0, 1.0),
                              (_settings.center.dy + dy).clamp(0.0, 1.0),
                            ),
                            clearPreset: true,
                          ),
                        );
                      },
                      onPanEnd: (_) {
                        final start = _dragStartCenter;
                        _dragStartCenter = null;
                        if (start != null) {
                          _commit(_settings);
                        }
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(File(widget.imagePath), fit: BoxFit.cover),
                          SpotlightOverlay(settings: _settings),
                          const Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Text(
                                'Drag to move the spotlight',
                                style: TextStyle(color: StudioTheme.cream, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Presets', style: TextStyle(color: StudioTheme.muted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final preset in LightingSettings.presets)
                        ChoiceChip(
                          label: Text(preset.presetName ?? ''),
                          selected: _settings.presetName == preset.presetName,
                          onSelected: (_) => _commit(preset),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SpotlightControls(
                    settings: _settings,
                    onLiveChange: _live,
                    onCommit: _commit,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Process on Python backend'),
                    subtitle: const Text('Optional. Local export still works offline.'),
                    value: _useServer,
                    onChanged: (value) => setState(() => _useServer = value),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _busy ? null : () => _export(share: false),
                          child: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save copy'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : () => _export(share: true),
                          child: const Text('Share'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
