import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import '../../../providers/editor_provider.dart';
import '../../../widgets/common/checkered_background.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/background_options_sheet.dart';
import '../widgets/export_sheet.dart';

class EditorScreen extends ConsumerWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final currentImage = editorState.currentImage;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor'),
        actions: [
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
      ),
      body: Column(
        children: [
          Expanded(
            child: currentImage.hasDisplay
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      const CheckeredBackground(),
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
          EditorToolbar(
            hasOriginalImage: currentImage.hasOriginal,
            hasProcessedImage: currentImage.hasProcessed,
            isProcessing: currentImage.isProcessing,
            onRemoveBackground: () {
              ref.read(editorProvider.notifier).removeBackground();
            },
            onBackgroundOptions: () {
              _showBackgroundOptionsSheet(context);
            },
            onExport: () {
              _showExportSheet(context);
            },
          ),
        ],
      ),
    );
  }

  void _showBackgroundOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const BackgroundOptionsSheet(),
    );
  }

  void _showExportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const ExportSheet(),
    );
  }
}
