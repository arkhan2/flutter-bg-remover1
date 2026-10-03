import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/edited_image.dart';
import '../../../providers/editor_provider.dart';

class BackgroundOptionsSheet extends ConsumerStatefulWidget {
  const BackgroundOptionsSheet({super.key});

  @override
  ConsumerState<BackgroundOptionsSheet> createState() => _BackgroundOptionsSheetState();
}

class _BackgroundOptionsSheetState extends ConsumerState<BackgroundOptionsSheet> {
  BackgroundType _selectedType = BackgroundType.transparent;
  Color _solidColor = Colors.white;
  Color _gradientStartColor = const Color(0xFF6366F1);
  Color _gradientEndColor = const Color(0xFF8B5CF6);
  double _blurRadius = 20.0;

  @override
  void initState() {
    super.initState();
    final currentImage = ref.read(editorProvider).currentImage;
    _selectedType = currentImage.backgroundType;
    if (currentImage.solidColor != null) {
      _solidColor = currentImage.solidColor!;
    }
    if (currentImage.gradientColors != null && currentImage.gradientColors!.length >= 2) {
      _gradientStartColor = currentImage.gradientColors![0];
      _gradientEndColor = currentImage.gradientColors![1];
    }
    if (currentImage.blurRadius != null) {
      _blurRadius = currentImage.blurRadius!;
    }
  }

  void _applyBackground() {
    final notifier = ref.read(editorProvider.notifier);
    
    notifier.applyBackground(
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
                  _buildColorPicker(_solidColor, (color) {
                    setState(() => _solidColor = color);
                  }),
                ],
                if (_selectedType == BackgroundType.gradient) ...[
                  Text(
                    'Start Color',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  _buildColorPicker(_gradientStartColor, (color) {
                    setState(() => _gradientStartColor = color);
                  }),
                  const SizedBox(height: 16),
                  Text(
                    'End Color',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  _buildColorPicker(_gradientEndColor, (color) {
                    setState(() => _gradientEndColor = color);
                  }),
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

  Widget _buildColorPicker(Color currentColor, ValueChanged<Color> onColorChanged) {
    return InkWell(
      onTap: () => _showColorPickerDialog(currentColor, onColorChanged),
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
                    '#${currentColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Tap to change',
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

  void _showColorPickerDialog(Color currentColor, ValueChanged<Color> onColorChanged) {
    Color pickerColor = currentColor;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) => pickerColor = color,
            enableAlpha: false,
            displayThumbColor: true,
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              onColorChanged(pickerColor);
              Navigator.pop(context);
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }
}
