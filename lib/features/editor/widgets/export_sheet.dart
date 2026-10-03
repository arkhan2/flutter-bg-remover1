import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/image_processing_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../providers/editor_provider.dart';

class ExportSheet extends ConsumerStatefulWidget {
  const ExportSheet({super.key});

  @override
  ConsumerState<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<ExportSheet> {
  ExportFormat _selectedFormat = ExportFormat.png;
  int _quality = 90;
  bool _isExporting = false;

  Future<void> _exportAndSave() async {
    setState(() => _isExporting = true);

    try {
      final editorState = ref.read(editorProvider);
      final displayBytes = editorState.currentImage.displayBytes;

      if (displayBytes == null) {
        _showError('No image to export');
        return;
      }

      final exportedBytes = await ImageProcessingService.exportImage(
        imageBytes: displayBytes,
        format: _selectedFormat,
        quality: _quality,
      );

      if (exportedBytes == null) {
        _showError('Failed to export image');
        return;
      }

      final extension = _selectedFormat.name;
      final filename = 'background_removed_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = await StorageService.exportToFile(exportedBytes, filename);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to: $path'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => _shareFile(path),
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Export failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _shareFile(String path) async {
    try {
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Background Removed Image',
      );
    } catch (e) {
      _showError('Failed to share: $e');
    }
  }

  Future<void> _shareDirectly() async {
    setState(() => _isExporting = true);

    try {
      final editorState = ref.read(editorProvider);
      final displayBytes = editorState.currentImage.displayBytes;

      if (displayBytes == null) {
        _showError('No image to share');
        return;
      }

      final exportedBytes = await ImageProcessingService.exportImage(
        imageBytes: displayBytes,
        format: _selectedFormat,
        quality: _quality,
      );

      if (exportedBytes == null) {
        _showError('Failed to process image');
        return;
      }

      final extension = _selectedFormat.name;
      final filename = 'background_removed_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = await StorageService.exportToFile(exportedBytes, filename);

      if (mounted) {
        Navigator.pop(context);
        await Share.shareXFiles(
          [XFile(path)],
          subject: 'Background Removed Image',
        );
      }
    } catch (e) {
      _showError('Share failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export Image',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Format',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ExportFormat.values.map((format) {
              final isSelected = _selectedFormat == format;
              return FilterChip(
                selected: isSelected,
                label: Text(format.name.toUpperCase()),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedFormat = format);
                  }
                },
              );
            }).toList(),
          ),
          if (_selectedFormat == ExportFormat.jpeg) ...[
            const SizedBox(height: 24),
            Text(
              'Quality: $_quality%',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Slider(
              value: _quality.toDouble(),
              min: 10,
              max: 100,
              divisions: 9,
              label: '$_quality%',
              onChanged: (value) {
                setState(() => _quality = value.toInt());
              },
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isExporting ? null : _shareDirectly,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isExporting ? null : _exportAndSave,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_alt),
                  label: const Text('Save'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedFormat == ExportFormat.png
                        ? 'PNG supports transparency'
                        : _selectedFormat == ExportFormat.jpeg
                            ? 'JPEG has smaller file size but no transparency'
                            : 'WebP offers good quality with small file size',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: const SizedBox(height: 8),
          ),
        ],
      ),
    );
  }
}
