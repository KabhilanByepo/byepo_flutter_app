import 'package:flutter/material.dart';

/// Placeholder Byepo brand mark, drawn with [CustomPaint] so the POC needs no
/// image asset. Swap in a real logo (asset + `Image.asset`) when available.
class ByepoLogo extends StatelessWidget {
  final double size;

  const ByepoLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size.square(size),
          painter: _ByepoMarkPainter(
            background: scheme.primary,
            foreground: scheme.onPrimary,
          ),
        ),
        SizedBox(height: size * 0.22),
        Text(
          'Byepo',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: scheme.primary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Stock Market',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 2,
              ),
        ),
      ],
    );
  }
}

class _ByepoMarkPainter extends CustomPainter {
  final Color background;
  final Color foreground;

  _ByepoMarkPainter({required this.background, required this.foreground});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width * 0.24;
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = background,
    );

    // A simple upward "trend" polyline as the mark.
    final line = Paint()
      ..color = foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.20, size.height * 0.68)
      ..lineTo(size.width * 0.42, size.height * 0.46)
      ..lineTo(size.width * 0.56, size.height * 0.58)
      ..lineTo(size.width * 0.80, size.height * 0.30);
    canvas.drawPath(path, line);

    // Arrow head.
    final head = Paint()..color = foreground;
    final tip = Offset(size.width * 0.80, size.height * 0.30);
    final arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - size.width * 0.14, tip.dy + size.width * 0.02)
      ..lineTo(tip.dx - size.width * 0.02, tip.dy + size.width * 0.14)
      ..close();
    canvas.drawPath(arrow, head);
  }

  @override
  bool shouldRepaint(_ByepoMarkPainter oldDelegate) =>
      background != oldDelegate.background ||
      foreground != oldDelegate.foreground;
}
