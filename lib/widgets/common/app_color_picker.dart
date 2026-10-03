import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/color_sampler.dart';

class AppColorPicker extends StatefulWidget {
  const AppColorPicker({
    super.key,
    required this.color,
    required this.onChanged,
    this.onPickFromImage,
  });

  final Color color;
  final ValueChanged<Color> onChanged;
  final VoidCallback? onPickFromImage;

  @override
  State<AppColorPicker> createState() => _AppColorPickerState();
}

class _AppColorPickerState extends State<AppColorPicker> {
  late HSVColor _hsv;
  late TextEditingController _hexController;

  static const _presets = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFF000000),
    Color(0xFFF3F4F6),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
  ];

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.color);
    _hexController = TextEditingController(text: colorToHex(_hsv.toColor()));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _setHsv(HSVColor hsv, {bool updateHex = true}) {
    setState(() => _hsv = hsv);
    final color = hsv.toColor();
    if (updateHex) {
      _hexController.value = TextEditingValue(
        text: colorToHex(color),
        selection: TextSelection.collapsed(offset: colorToHex(color).length),
      );
    }
    widget.onChanged(color);
  }

  void _applyHex(String raw) {
    var value = raw.trim();
    if (value.startsWith('#')) value = value.substring(1);
    if (value.length != 6) return;
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return;
    _setHsv(HSVColor.fromColor(Color(0xFF000000 | parsed)), updateHex: false);
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsv.toColor();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 180,
          child: _SaturationValuePad(
            hsv: _hsv,
            onChanged: _setHsv,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 24,
          child: _HueSlider(
            hsv: _hsv,
            onChanged: _setHsv,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _hexController,
                decoration: const InputDecoration(
                  prefixText: '',
                  labelText: 'Hex',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F#]')),
                  LengthLimitingTextInputFormatter(7),
                ],
                onChanged: _applyHex,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presets.map((preset) {
            final selected = colorToHex(preset) == colorToHex(color);
            return GestureDetector(
              onTap: () => _setHsv(HSVColor.fromColor(preset)),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: preset,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    width: selected ? 2 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (widget.onPickFromImage != null) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: widget.onPickFromImage,
            icon: const Icon(Icons.colorize),
            label: const Text('Pick from image'),
          ),
        ],
      ],
    );
  }
}

class _SaturationValuePad extends StatelessWidget {
  const _SaturationValuePad({
    required this.hsv,
    required this.onChanged,
  });

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  void _update(Offset local, Size size) {
    if (size.isEmpty) return;
    final saturation = (local.dx / size.width).clamp(0.0, 1.0);
    final value = (1 - local.dy / size.height).clamp(0.0, 1.0);
    onChanged(hsv.withSaturation(saturation).withValue(value));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) => _update(event.localPosition, size),
          onPointerMove: (event) => _update(event.localPosition, size),
          child: CustomPaint(
            size: size,
            painter: _SaturationValuePainter(hsv),
          ),
        );
      },
    );
  }
}

class _HueSlider extends StatelessWidget {
  const _HueSlider({
    required this.hsv,
    required this.onChanged,
  });

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  void _update(Offset local, Size size) {
    if (size.isEmpty) return;
    final hue = (local.dx / size.width * 360.0).clamp(0.0, 360.0);
    onChanged(hsv.withHue(hue));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) => _update(event.localPosition, size),
          onPointerMove: (event) => _update(event.localPosition, size),
          child: CustomPaint(
            size: size,
            painter: _HueSliderPainter(hsv),
          ),
        );
      },
    );
  }
}

class _SaturationValuePainter extends CustomPainter {
  const _SaturationValuePainter(this.hsv);

  final HSVColor hsv;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hueColor = HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor();

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, hueColor],
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );

    final thumb = Offset(size.width * hsv.saturation, size.height * (1 - hsv.value));
    canvas.drawCircle(
      thumb,
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(thumb, 4, Paint()..color = hsv.toColor());
  }

  @override
  bool shouldRepaint(covariant _SaturationValuePainter oldDelegate) {
    return oldDelegate.hsv != hsv;
  }
}

class _HueSliderPainter extends CustomPainter {
  const _HueSliderPainter(this.hsv);

  final HSVColor hsv;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const hues = <Color>[
      Color(0xFFFF0000),
      Color(0xFFFFFF00),
      Color(0xFF00FF00),
      Color(0xFF00FFFF),
      Color(0xFF0000FF),
      Color(0xFFFF00FF),
      Color(0xFFFF0000),
    ];

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()..shader = const LinearGradient(colors: hues).createShader(rect),
    );

    final x = (hsv.hue / 360.0) * size.width;
    canvas.drawCircle(
      Offset(x, size.height / 2),
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _HueSliderPainter oldDelegate) {
    return oldDelegate.hsv != hsv;
  }
}
