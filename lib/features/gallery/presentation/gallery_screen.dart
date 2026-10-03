import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/storage_service.dart';
import '../../../models/project.dart';
import '../../../providers/editor_provider.dart';
import '../../../providers/gallery_provider.dart';
import '../../editor/presentation/editor_screen.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(galleryProvider.notifier).loadProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final galleryState = ref.watch(galleryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        actions: [
          if (!galleryState.isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _showClearAllDialog(context),
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This session only. Images stay on this device and are cleared when you close the app.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (galleryState.errorMessage != null)
            Material(
              color: colorScheme.errorContainer,
              child: ListTile(
                leading: Icon(Icons.error_outline, color: colorScheme.error),
                title: Text(
                  galleryState.errorMessage!,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => ref.read(galleryProvider.notifier).clearError(),
                ),
              ),
            ),
          Expanded(
            child: galleryState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : galleryState.isEmpty
                    ? _buildEmptyState(context, colorScheme)
                    : _buildGalleryGrid(context, galleryState),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Saved Projects',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Edits you save from the editor appear here for this session.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Create New Project'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryGrid(BuildContext context, GalleryState galleryState) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: galleryState.projects.length,
      itemBuilder: (context, index) {
        final project = galleryState.projects[index];
        return _buildProjectCard(
          context,
          project,
          galleryState.thumbnails[project.id],
        );
      },
    );
  }

  Widget _buildProjectCard(BuildContext context, Project project, Uint8List? thumbnail) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openProject(project),
        onLongPress: () => _showProjectOptions(context, project),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbnail != null)
              Image.memory(
                thumbnail,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              )
            else
              Container(
                color: colorScheme.surfaceContainerHighest,
                child: const Icon(
                  Icons.image_outlined,
                  size: 48,
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      project.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _formatDate(project.updatedAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _openProject(Project project) async {
    final original = project.originalImagePath == null
        ? null
        : await StorageService.loadImage(project.originalImagePath!);
    if (original == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this project')),
      );
      return;
    }

    final processed = project.processedImagePath == null
        ? null
        : await StorageService.loadImage(project.processedImagePath!);
    final display = project.displayImagePath == null
        ? null
        : await StorageService.loadImage(project.displayImagePath!);

    ref.read(editorProvider.notifier).loadProject(
      originalBytes: original,
      processedBytes: processed,
      displayBytes: display,
      backgroundType: project.backgroundType,
      solidColor: project.solidColorValue == null ? null : Color(project.solidColorValue!),
      gradientColors: project.gradientColorValues?.map(Color.new).toList(),
      blurRadius: project.blurRadius,
    );

    if (!mounted) return;
    Navigator.of(context)
        .push(
      MaterialPageRoute(builder: (context) => const EditorScreen()),
    )
        .then((_) {
      if (mounted) {
        ref.read(editorProvider.notifier).reset();
      }
    });
  }

  Future<void> _shareProject(Project project) async {
    final key = project.displayImagePath ??
        project.processedImagePath ??
        project.originalImagePath;
    if (key == null) return;
    final bytes = await StorageService.loadImage(key);
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to share')),
      );
      return;
    }

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: '${project.name.replaceAll(' ', '_').toLowerCase()}.png',
          mimeType: 'image/png',
        ),
      ],
      subject: project.name,
    );
  }

  void _showProjectOptions(BuildContext context, Project project) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Open'),
              onTap: () {
                Navigator.pop(context);
                _openProject(project);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                _shareProject(project);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, project);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text('Are you sure you want to delete "${project.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(galleryProvider.notifier).deleteProject(project.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Projects?'),
        content: const Text(
          'This will delete all projects saved in this session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              final projects = ref.read(galleryProvider).projects;
              for (final project in projects) {
                ref.read(galleryProvider.notifier).deleteProject(project.id);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
