import 'dart:typed_data';
import 'package:background_remover/models/edited_image.dart';
import 'package:background_remover/providers/editor_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _bytes(int fill) => Uint8List.fromList(List<int>.filled(8, fill));

EditedImage _image(int fill) => EditedImage(
      originalBytes: _bytes(fill),
      displayBytes: _bytes(fill),
    );

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('second loadImage replaces history instead of appending', () {
    final notifier = container.read(editorProvider.notifier);
    notifier.loadImage(_bytes(1));
    notifier.loadImage(_bytes(2));

    final state = container.read(editorProvider);
    expect(state.history.length, 1);
    expect(state.canUndo, isFalse);
    expect(state.currentImage.originalBytes, _bytes(2));
  });

  test('undo and redo move through history', () {
    final notifier = container.read(editorProvider.notifier);
    notifier.loadImage(_bytes(1));
    notifier.addHistoryEntry(_image(2));
    notifier.addHistoryEntry(_image(3));

    expect(container.read(editorProvider).canUndo, isTrue);
    notifier.undo();
    expect(container.read(editorProvider).currentImage.originalBytes, _bytes(2));
    expect(container.read(editorProvider).canRedo, isTrue);

    notifier.redo();
    expect(container.read(editorProvider).currentImage.originalBytes, _bytes(3));
    expect(container.read(editorProvider).canRedo, isFalse);
  });

  test('loadProject starts a fresh stack', () {
    final notifier = container.read(editorProvider.notifier);
    notifier.loadImage(_bytes(9));
    notifier.loadProject(
      originalBytes: _bytes(1),
      processedBytes: _bytes(2),
      displayBytes: _bytes(2),
    );

    final state = container.read(editorProvider);
    expect(state.history.length, 1);
    expect(state.currentImage.hasProcessed, isTrue);
    expect(state.canUndo, isFalse);
  });

  test('history is capped at 20 entries', () {
    final notifier = container.read(editorProvider.notifier);
    notifier.loadImage(_bytes(0));
    for (var i = 1; i <= 25; i++) {
      notifier.addHistoryEntry(_image(i));
    }

    final state = container.read(editorProvider);
    expect(state.history.length, EditorNotifier.maxHistory);
    expect(state.historyIndex, EditorNotifier.maxHistory - 1);
  });

  test('reset clears the editor', () {
    final notifier = container.read(editorProvider.notifier);
    notifier.loadImage(_bytes(1));
    notifier.reset();

    final state = container.read(editorProvider);
    expect(state.history, isEmpty);
    expect(state.currentImage.hasOriginal, isFalse);
  });
}
