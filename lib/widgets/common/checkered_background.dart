import 'package:flutter/material.dart';

class CheckeredBackground extends StatelessWidget {
  final double squareSize;
  final Color color1;
  final Color color2;

  const CheckeredBackground({
    super.key,
    this.squareSize = 10.0,
    this.color1 = const Color(0xFFE0E0E0),
    this.color2 = const Color(0xFFFFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CheckeredPainter(
        squareSize: squareSize,
        color1: color1,
        color2: color2,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _CheckeredPainter extends CustomPainter {
  final double squareSize;
  final Color color1;
  final Color color2;

  _CheckeredPainter({
    required this.squareSize,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = color1;
    final paint2 = Paint()..color = color2;

    final horizontalSquares = (size.width / squareSize).ceil();
    final verticalSquares = (size.height / squareSize).ceil();

    for (int row = 0; row < verticalSquares; row++) {
      for (int col = 0; col < horizontalSquares; col++) {
        final isEven = (row + col) % 2 == 0;
        final paint = isEven ? paint1 : paint2;

        final rect = Rect.fromLTWH(
          col * squareSize,
          row * squareSize,
          squareSize,
          squareSize,
        );

        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckeredPainter oldDelegate) {
    return oldDelegate.squareSize != squareSize ||
        oldDelegate.color1 != color1 ||
        oldDelegate.color2 != color2;
  }
}
