import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/background_removal_service.dart';
import '../core/services/image_processing_service.dart';
import '../models/edited_image.dart';

class EditorState {
  final EditedImage currentImage;
  final List<EditedImage> history;
  final int historyIndex;
  final bool canUndo;
  final bool canRedo;

  const EditorState({
    this.currentImage = const EditedImage(),
    this.history = const [],
    this.historyIndex = -1,
    this.canUndo = false,
    this.canRedo = false,
  });

  EditorState copyWith({
    EditedImage? currentImage,
    List<EditedImage>? history,
    int? historyIndex,
    bool? canUndo,
    bool? canRedo,
  }) {
    return EditorState(
      currentImage: currentImage ?? this.currentImage,
      history: history ?? this.history,
      historyIndex: historyIndex ?? this.historyIndex,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
    );
  }
}

class EditorNotifier extends StateNotifier<EditorState> {
  EditorNotifier() : super(const EditorState());

  void loadImage(Uint8List imageBytes) {
    final newImage = EditedImage(
      originalBytes: imageBytes,
      displayBytes: imageBytes,
    );
    _addToHistory(newImage);
  }

  Future<void> removeBackground() async {
    if (state.currentImage.originalBytes == null) return;

    state = state.copyWith(
      currentImage: state.currentImage.copyWith(isProcessing: true),
    );

    try {
      final processedBytes = await BackgroundRemovalService.removeBackground(
        state.currentImage.originalBytes!,
      );

      if (processedBytes != null) {
        final newImage = state.currentImage.copyWith(
          processedBytes: processedBytes,
          displayBytes: processedBytes,
          backgroundType: BackgroundType.transparent,
          isProcessing: false,
        );
        _addToHistory(newImage);
      } else {
        state = state.copyWith(
          currentImage: state.currentImage.copyWith(
            isProcessing: false,
            errorMessage: 'Failed to remove background',
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(
        currentImage: state.currentImage.copyWith(
          isProcessing: false,
          errorMessage: 'Error: $e',
        ),
      );
    }
  }

  Future<void> applyBackground({
    required BackgroundType type,
    Color? solidColor,
    List<Color>? gradientColors,
    double? blurRadius,
  }) async {
    if (state.currentImage.processedBytes == null) return;

    state = state.copyWith(
      currentImage: state.currentImage.copyWith(isProcessing: true),
    );

    try {
      final displayBytes = await ImageProcessingService.applyBackground(
        foregroundBytes: state.currentImage.processedBytes!,
        backgroundType: type,
        solidColor: solidColor,
        gradientColors: gradientColors,
        blurRadius: blurRadius,
        originalImageBytes: state.currentImage.originalBytes,
      );

      if (displayBytes != null) {
        final newImage = state.currentImage.copyWith(
          displayBytes: displayBytes,
          backgroundType: type,
          solidColor: solidColor,
          gradientColors: gradientColors,
          blurRadius: blurRadius,
          isProcessing: false,
        );
        _addToHistory(newImage);
      } else {
        state = state.copyWith(
          currentImage: state.currentImage.copyWith(
            isProcessing: false,
            errorMessage: 'Failed to apply background',
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(
        currentImage: state.currentImage.copyWith(
          isProcessing: false,
          errorMessage: 'Error: $e',
        ),
      );
    }
  }

  void _addToHistory(EditedImage image) {
    final newHistory = [
      ...state.history.take(state.historyIndex + 1),
      image,
    ];
    
    state = state.copyWith(
      currentImage: image,
      history: newHistory,
      historyIndex: newHistory.length - 1,
      canUndo: newHistory.length > 1,
      canRedo: false,
    );
  }

  void undo() {
    if (!state.canUndo || state.historyIndex <= 0) return;

    final newIndex = state.historyIndex - 1;
    state = state.copyWith(
      currentImage: state.history[newIndex],
      historyIndex: newIndex,
      canUndo: newIndex > 0,
      canRedo: true,
    );
  }

  void redo() {
    if (!state.canRedo || state.historyIndex >= state.history.length - 1) return;

    final newIndex = state.historyIndex + 1;
    state = state.copyWith(
      currentImage: state.history[newIndex],
      historyIndex: newIndex,
      canUndo: true,
      canRedo: newIndex < state.history.length - 1,
    );
  }

  void reset() {
    state = const EditorState();
  }

  void clearError() {
    state = state.copyWith(
      currentImage: state.currentImage.copyWith(errorMessage: null),
    );
  }
}

final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier();
});
