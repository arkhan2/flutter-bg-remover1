import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../../../providers/editor_provider.dart';
import '../../editor/presentation/editor_screen.dart';
import '../../gallery/presentation/gallery_screen.dart';
import '../widgets/feature_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isLoading = true);

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
      );

      if (image != null && mounted) {
        _openEditor(await image.readAsBytes());
      }
    } catch (e) {
      if (mounted) {
        final isCamera = source == ImageSource.camera;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCamera
                  ? 'Camera is not available here. Choose an image from your files instead.'
                  : 'Could not open that image. Try a PNG or JPEG from your files.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openEditor(Uint8List bytes) {
    ref.read(editorProvider.notifier).loadImage(bytes);
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const EditorScreen(),
      ),
    )
        .then((_) {
      if (mounted) {
        ref.read(editorProvider.notifier).reset();
      }
    });
  }

  Future<void> _loadSampleImage() async {
    setState(() => _isLoading = true);
    try {
      final image = img.Image(width: 320, height: 320, numChannels: 4);
      img.fill(image, color: img.ColorRgba8(245, 245, 245, 255));
      for (int y = 60; y < 260; y++) {
        for (int x = 80; x < 240; x++) {
          image.setPixelRgba(x, y, 198, 40, 40, 255);
        }
      }
      _openEditor(Uint8List.fromList(img.encodePng(image)));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_fix_high,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text('Background Remover'),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.photo_library_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const GalleryScreen(),
                      ),
                    );
                  },
                  tooltip: 'Gallery',
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroCard(context, colorScheme),
                    const SizedBox(height: 32),
                    Text(
                      'Features',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeaturesGrid(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.secondaryContainer,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.image_outlined,
                  size: 32,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Remove Background',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select an image to remove a flat background on this device. Photos are not uploaded. The gallery only lasts for this session.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _showImageSourceDialog,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(_isLoading ? 'Loading...' : 'Select Image'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isLoading ? null : _loadSampleImage,
                child: const Text('Try a sample image'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: const [
        FeatureCard(
          icon: Icons.auto_fix_high,
          title: 'Auto Remove',
          description: 'On-device color background removal',
        ),
        FeatureCard(
          icon: Icons.palette_outlined,
          title: 'Solid Colors',
          description: 'Add any solid color background',
        ),
        FeatureCard(
          icon: Icons.gradient,
          title: 'Gradients',
          description: 'Beautiful gradient backgrounds',
        ),
        FeatureCard(
          icon: Icons.blur_on,
          title: 'Blur Effect',
          description: 'Blur the original background',
        ),
        FeatureCard(
          icon: Icons.history,
          title: 'Undo/Redo',
          description: 'Unlimited edit history',
        ),
        FeatureCard(
          icon: Icons.share_outlined,
          title: 'Export & Share',
          description: 'Download or share PNG and JPEG',
        ),
      ],
    );
  }
}
