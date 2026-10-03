import 'dart:typed_data';
import 'package:background_remover/core/services/storage_service.dart';
import 'package:background_remover/models/edited_image.dart';
import 'package:background_remover/models/project.dart';
import 'package:background_remover/providers/gallery_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(StorageService.clearAll);

  test('save, load, and delete a project with images', () async {
    final original = Uint8List.fromList([1, 2, 3]);
    final processed = Uint8List.fromList([4, 5, 6]);

    final originalKey = await StorageService.saveImage(original);
    final processedKey = await StorageService.saveImage(processed);

    final project = Project(
      name: 'Test project',
      originalImagePath: originalKey,
      processedImagePath: processedKey,
      displayImagePath: processedKey,
      thumbnailPath: processedKey,
    );

    await StorageService.saveProject(project);

    final loaded = await StorageService.loadProject(project.id);
    expect(loaded, isNotNull);
    expect(loaded!.name, 'Test project');
    expect(await StorageService.loadImage(originalKey), original);

    await StorageService.deleteProject(project.id);
    expect(await StorageService.loadProject(project.id), isNull);
    expect(await StorageService.loadImage(originalKey), isNull);
  });

  test('gallery notifier saves an edited image for this session', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(galleryProvider.notifier);
    final image = EditedImage(
      originalBytes: Uint8List.fromList([9, 8, 7]),
      processedBytes: Uint8List.fromList([1, 1, 1]),
      displayBytes: Uint8List.fromList([2, 2, 2]),
    );

    final project = await notifier.saveFromEditedImage(image);
    expect(project, isNotNull);

    await notifier.loadProjects();
    final state = container.read(galleryProvider);
    expect(state.projects, isNotEmpty);
    expect(state.thumbnails.containsKey(project!.id), isTrue);
    expect(state.errorMessage, isNull);
  });
}
