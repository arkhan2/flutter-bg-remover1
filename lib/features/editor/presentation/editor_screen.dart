import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import '../../../core/services/color_sampler.dart';
import '../../../providers/editor_provider.dart';
import '../../../providers/gallery_provider.dart';
import '../../../widgets/common/checkered_background.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/background_options_sheet.dart';
import '../widgets/export_sheet.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  bool _isEyedropping = false;
  ColorPickField? _eyedropField;
  BackgroundOptionsDraft? _eyedropDraft;
  ColorSampler? _sampler;
  Color? _hoverColor;
  Offset? _hoverPosition;

  void _showBackgroundOptionsSheet([BackgroundOptionsDraft? draft]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => BackgroundOptionsSheet(
        draft: draft,
        onPickFromImage: _startEyedropper,
      ),
    );
  }

  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const ExportSheet(),
    );
  }

  Future<void> _saveToGallery() async {
    final image = ref.read(editorProvider).currentImage;
    final project = await ref.read(galleryProvider.notifier).saveFromEditedImage(image);
    if (!mounted) return;
    if (project == null) {
      final error = ref.read(galleryProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Could not save to gallery')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to this session’s gallery')),
    );
  }

  void _startEyedropper(ColorPickField field, BackgroundOptionsDraft draft) {
    final currentImage = ref.read(editorProvider).currentImage;
    final displayBytes = currentImage.displayBytes ?? currentImage.originalBytes;
    if (displayBytes == null) return;

    setState(() {
      _isEyedropping = true;
      _eyedropField = field;
      _eyedropDraft = draft;
      _hoverColor = null;
      _hoverPosition = null;
      _sampler = ColorSampler.fromBytes(
        displayBytes: displayBytes,
        originalBytes: currentImage.originalBytes,
      );
    });
  }

  void _cancelEyedropper() {
    final draft = _eyedropDraft;
    setState(() {
      _isEyedropping = false;
      _eyedropField = null;
      _eyedropDraft = null;
      _sampler = null;
      _hoverColor = null;
      _hoverPosition = null;
    });
    if (draft != null) {
      _showBackgroundOptionsSheet(draft);
    }
  }

  void _updateHover(Offset local, Size boxSize) {
    final color = _sampler?.colorAtDisplayPoint(local, boxSize);
    setState(() {
      _hoverColor = color;
      _hoverPosition = local;
    });
  }

  void _commitEyedrop(Offset local, Size boxSize) {
    final field = _eyedropField;
    final draft = _eyedropDraft;
    final color = _sampler?.colorAtDisplayPoint(local, boxSize);
    if (field == null || draft == null || color == null) return;

    setState(() {
      _isEyedropping = false;
      _eyedropField = null;
      _eyedropDraft = null;
      _sampler = null;
      _hoverColor = null;
      _hoverPosition = null;
    });

    _showBackgroundOptionsSheet(draft.withPickedColor(field, color));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Picked ${colorToHex(color)} from image')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider);
    final currentImage = editorState.currentImage;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEyedropping ? 'Pick a color' : 'Editor'),
        actions: [
          if (_isEyedropping)
            TextButton(
              onPressed: _cancelEyedropper,
              child: const Text('Cancel'),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: editorState.canUndo
                  ? () => ref.read(editorProvider.notifier).undo()
                  : null,
              tooltip: 'Undo',
            ),
            IconButton(
              icon: const Icon(Icons.redo),
              onPressed: editorState.canRedo
                  ? () => ref.read(editorProvider.notifier).redo()
                  : null,
              tooltip: 'Redo',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (_isEyedropping)
            Material(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.colorize, color: colorScheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Click the image to sample a color',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    if (_hoverColor != null) ...[
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _hoverColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: colorScheme.outline),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        colorToHex(_hoverColor!),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          Expanded(
            child: currentImage.hasDisplay
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      const CheckeredBackground(),
                      if (_isEyedropping)
                        _buildEyedropperLayer(currentImage.displayBytes!)
                      else
                        PhotoView(
                          imageProvider: MemoryImage(currentImage.displayBytes!),
                          backgroundDecoration: const BoxDecoration(
                            color: Colors.transparent,
                          ),
                          minScale: PhotoViewComputedScale.contained * 0.5,
                          maxScale: PhotoViewComputedScale.covered * 3,
                        ),
                      if (currentImage.isProcessing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  'Processing...',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          size: 64,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No image loaded',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (currentImage.errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: colorScheme.errorContainer,
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentImage.errorMessage!,
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      ref.read(editorProvider.notifier).clearError();
                    },
                  ),
                ],
              ),
            ),
          if (!_isEyedropping)
            EditorToolbar(
              hasOriginalImage: currentImage.hasOriginal,
              hasProcessedImage: currentImage.hasProcessed,
              isProcessing: currentImage.isProcessing,
              onRemoveBackground: () {
                ref.read(editorProvider.notifier).removeBackground();
              },
              onBackgroundOptions: () {
                _showBackgroundOptionsSheet();
              },
              onExport: _showExportSheet,
              onSaveToGallery: _saveToGallery,
            ),
        ],
      ),
    );
  }

  Widget _buildEyedropperLayer(Uint8List displayBytes) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = Size(constraints.maxWidth, constraints.maxHeight);
        return MouseRegion(
          cursor: SystemMouseCursors.precise,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerHover: (event) => _updateHover(event.localPosition, boxSize),
            onPointerMove: (event) => _updateHover(event.localPosition, boxSize),
            onPointerDown: (event) => _commitEyedrop(event.localPosition, boxSize),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(
                  displayBytes,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
                if (_hoverColor != null && _hoverPosition != null)
                  Positioned(
                    left: (_hoverPosition!.dx + 16).clamp(0.0, boxSize.width - 72),
                    top: (_hoverPosition!.dy - 40).clamp(0.0, boxSize.height - 36),
                    child: IgnorePointer(
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _hoverColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
