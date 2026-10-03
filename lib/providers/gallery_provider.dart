import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/storage_service.dart';
import '../models/edited_image.dart';
import '../models/project.dart';

class GalleryState {
  final List<Project> projects;
  final Map<String, Uint8List> thumbnails;
  final bool isLoading;
  final String? errorMessage;

  const GalleryState({
    this.projects = const [],
    this.thumbnails = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  GalleryState copyWith({
    List<Project>? projects,
    Map<String, Uint8List>? thumbnails,
    bool? isLoading,
    String? errorMessage,
  }) {
    return GalleryState(
      projects: projects ?? this.projects,
      thumbnails: thumbnails ?? this.thumbnails,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  bool get isEmpty => projects.isEmpty;
  int get count => projects.length;
}

class GalleryNotifier extends StateNotifier<GalleryState> {
  GalleryNotifier() : super(const GalleryState());

  Future<void> loadProjects() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final projects = await StorageService.loadProjects();
      final thumbnails = await _loadThumbnails(projects);
      state = state.copyWith(
        projects: projects,
        thumbnails: thumbnails,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load projects: $e',
      );
    }
  }

  Future<Map<String, Uint8List>> _loadThumbnails(List<Project> projects) async {
    final thumbnails = <String, Uint8List>{};
    for (final project in projects) {
      final key = project.previewImagePath;
      if (key == null) continue;
      final bytes = await StorageService.loadImage(key);
      if (bytes != null) {
        thumbnails[project.id] = bytes;
      }
    }
    return thumbnails;
  }

  Future<void> saveProject(Project project) async {
    try {
      final savedProject = await StorageService.saveProject(project);
      final updatedProjects = [...state.projects];
      final existingIndex = updatedProjects.indexWhere((p) => p.id == savedProject.id);

      if (existingIndex >= 0) {
        updatedProjects[existingIndex] = savedProject;
      } else {
        updatedProjects.insert(0, savedProject);
      }

      final thumbnails = Map<String, Uint8List>.from(state.thumbnails);
      final previewKey = savedProject.previewImagePath;
      if (previewKey != null) {
        final bytes = await StorageService.loadImage(previewKey);
        if (bytes != null) {
          thumbnails[savedProject.id] = bytes;
        }
      }

      state = state.copyWith(
        projects: updatedProjects,
        thumbnails: thumbnails,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save project: $e');
    }
  }

  Future<Project?> saveFromEditedImage(EditedImage image) async {
    if (image.originalBytes == null) {
      state = state.copyWith(errorMessage: 'No image to save');
      return null;
    }

    try {
      final originalKey = await StorageService.saveImage(image.originalBytes!);
      String? processedKey;
      if (image.processedBytes != null) {
        processedKey = await StorageService.saveImage(image.processedBytes!);
      }
      final displayBytes = image.displayBytes ?? image.processedBytes ?? image.originalBytes!;
      final displayKey = await StorageService.saveImage(displayBytes);
      final thumbnailKey = await StorageService.saveImage(displayBytes);

      final now = DateTime.now();
      final minute = now.minute.toString().padLeft(2, '0');
      final project = Project(
        name: 'Edit ${now.month}/${now.day} ${now.hour}:$minute',
        originalImagePath: originalKey,
        processedImagePath: processedKey,
        displayImagePath: displayKey,
        thumbnailPath: thumbnailKey,
        backgroundType: image.backgroundType,
        solidColorValue: image.solidColor?.toARGB32(),
        gradientColorValues: image.gradientColors?.map((c) => c.toARGB32()).toList(),
        blurRadius: image.blurRadius,
      );

      await saveProject(project);
      return project;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save project: $e');
      return null;
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await StorageService.deleteProject(id);
      final updatedProjects = state.projects.where((p) => p.id != id).toList();
      final thumbnails = Map<String, Uint8List>.from(state.thumbnails)..remove(id);
      state = state.copyWith(
        projects: updatedProjects,
        thumbnails: thumbnails,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete project: $e');
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final galleryProvider = StateNotifierProvider<GalleryNotifier, GalleryState>((ref) {
  return GalleryNotifier();
});
