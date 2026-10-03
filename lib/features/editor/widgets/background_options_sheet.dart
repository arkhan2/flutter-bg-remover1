import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/color_sampler.dart';
import '../../../models/edited_image.dart';
import '../../../providers/editor_provider.dart';
import '../../../widgets/common/app_color_picker.dart';

enum ColorPickField { solid, gradientStart, gradientEnd }

class BackgroundOptionsDraft {
  const BackgroundOptionsDraft({
    required this.type,
    required this.solidColor,
    required this.gradientStart,
    required this.gradientEnd,
    required this.blurRadius,
  });

  final BackgroundType type;
  final Color solidColor;
  final Color gradientStart;
  final Color gradientEnd;
  final double blurRadius;

  BackgroundOptionsDraft copyWith({
    BackgroundType? type,
    Color? solidColor,
    Color? gradientStart,
    Color? gradientEnd,
    double? blurRadius,
  }) {
    return BackgroundOptionsDraft(
      type: type ?? this.type,
      solidColor: solidColor ?? this.solidColor,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      blurRadius: blurRadius ?? this.blurRadius,
    );
  }

  BackgroundOptionsDraft withPickedColor(ColorPickField field, Color color) {
    switch (field) {
      case ColorPickField.solid:
        return copyWith(solidColor: color);
      case ColorPickField.gradientStart:
        return copyWith(gradientStart: color);
      case ColorPickField.gradientEnd:
        return copyWith(gradientEnd: color);
    }
  }
}

class BackgroundOptionsSheet extends ConsumerStatefulWidget {
  const BackgroundOptionsSheet({
    super.key,
    this.draft,
    this.onPickFromImage,
  });

  final BackgroundOptionsDraft? draft;
  final void Function(ColorPickField field, BackgroundOptionsDraft draft)? onPickFromImage;

  @override
  ConsumerState<BackgroundOptionsSheet> createState() => _BackgroundOptionsSheetState();
}

class _BackgroundOptionsSheetState extends ConsumerState<BackgroundOptionsSheet> {
  late BackgroundType _selectedType;
  late Color _solidColor;
  late Color _gradientStartColor;
  late Color _gradientEndColor;
  late double _blurRadius;

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    if (draft != null) {
      _selectedType = draft.type;
      _solidColor = draft.solidColor;
      _gradientStartColor = draft.gradientStart;
      _gradientEndColor = draft.gradientEnd;
      _blurRadius = draft.blurRadius;
      return;
    }

    final currentImage = ref.read(editorProvider).currentImage;
    _selectedType = currentImage.backgroundType;
    _solidColor = currentImage.solidColor ?? Colors.white;
    if (currentImage.gradientColors != null && currentImage.gradientColors!.length >= 2) {
      _gradientStartColor = currentImage.gradientColors![0];
      _gradientEndColor = currentImage.gradientColors![1];
    } else {
      _gradientStartColor = const Color(0xFF6366F1);
      _gradientEndColor = const Color(0xFF8B5CF6);
    }
    _blurRadius = currentImage.blurRadius ?? 20.0;
  }

  BackgroundOptionsDraft _currentDraft() {
    return BackgroundOptionsDraft(
      type: _selectedType,
      solidColor: _solidColor,
      gradientStart: _gradientStartColor,
      gradientEnd: _gradientEndColor,
      blurRadius: _blurRadius,
    );
  }

  void _applyBackground() {
    ref.read(editorProvider.notifier).applyBackground(
      type: _selectedType,
      solidColor: _solidColor,
      gradientColors: [_gradientStartColor, _gradientEndColor],
      blurRadius: _blurRadius,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Background Options',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Background Type',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                _buildTypeSelector(colorScheme),
                const SizedBox(height: 24),
                if (_selectedType == BackgroundType.solid) ...[
                  Text(
                    'Color',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  _buildColorPicker(
                    _solidColor,
                    ColorPickField.solid,
                    (color) => setState(() => _solidColor = color),
                  ),
                ],
                if (_selectedType == BackgroundType.gradient) ...[
                  Text(
                    'Start Color',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  _buildColorPicker(
                    _gradientStartColor,
                    ColorPickField.gradientStart,
                    (color) => setState(() => _gradientStartColor = color),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'End Color',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  _buildColorPicker(
                    _gradientEndColor,
                    ColorPickField.gradientEnd,
                    (color) => setState(() => _gradientEndColor = color),
                  ),
                  const SizedBox(height: 16),
                  _buildGradientPreview(),
                ],
                if (_selectedType == BackgroundType.blur) ...[
                  Text(
                    'Blur Radius: ${_blurRadius.toInt()}',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: _blurRadius,
                    min: 5,
                    max: 50,
                    divisions: 45,
                    label: _blurRadius.toInt().toString(),
                    onChanged: (value) {
                      setState(() => _blurRadius = value);
                    },
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _applyBackground,
                    child: const Text('Apply Background'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeSelector(ColorScheme colorScheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildTypeChip(
          BackgroundType.transparent,
          'Transparent',
          Icons.grid_on,
          colorScheme,
        ),
        _buildTypeChip(
          BackgroundType.solid,
          'Solid',
          Icons.square,
          colorScheme,
        ),
        _buildTypeChip(
          BackgroundType.gradient,
          'Gradient',
          Icons.gradient,
          colorScheme,
        ),
        _buildTypeChip(
          BackgroundType.blur,
          'Blur',
          Icons.blur_on,
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildTypeChip(
    BackgroundType type,
    String label,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    final isSelected = _selectedType == type;

    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
      ),
      label: Text(label),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedType = type);
        }
      },
    );
  }

  Widget _buildColorPicker(
    Color currentColor,
    ColorPickField field,
    ValueChanged<Color> onColorChanged,
  ) {
    return InkWell(
      onTap: () => _showColorPickerDialog(currentColor, field, onColorChanged),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    colorToHex(currentColor),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Tap to change or pick from image',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.colorize),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientPreview() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_gradientStartColor, _gradientEndColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _showColorPickerDialog(
    Color currentColor,
    ColorPickField field,
    ValueChanged<Color> onColorChanged,
  ) {
    var pickerColor = currentColor;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pick a color'),
        content: SizedBox(
          width: 320,
          child: AppColorPicker(
            color: currentColor,
            onChanged: (color) => pickerColor = color,
            onPickFromImage: widget.onPickFromImage == null
                ? null
                : () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(context);
                    widget.onPickFromImage!(field, _currentDraft());
                  },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              onColorChanged(pickerColor);
              Navigator.pop(dialogContext);
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }
}
