import 'package:flutter/material.dart';

class EditorToolbar extends StatelessWidget {
  final bool hasOriginalImage;
  final bool hasProcessedImage;
  final bool isProcessing;
  final VoidCallback onRemoveBackground;
  final VoidCallback onBackgroundOptions;
  final VoidCallback onExport;

  const EditorToolbar({
    super.key,
    required this.hasOriginalImage,
    required this.hasProcessedImage,
    required this.isProcessing,
    required this.onRemoveBackground,
    required this.onBackgroundOptions,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!hasProcessedImage && hasOriginalImage)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isProcessing ? null : onRemoveBackground,
                  icon: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_fix_high),
                  label: Text(
                    isProcessing ? 'Removing Background...' : 'Remove Background',
                  ),
                ),
              ),
            if (hasProcessedImage) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isProcessing ? null : onBackgroundOptions,
                      icon: const Icon(Icons.wallpaper),
                      label: const Text('Background'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isProcessing ? null : onExport,
                      icon: const Icon(Icons.download),
                      label: const Text('Export'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
