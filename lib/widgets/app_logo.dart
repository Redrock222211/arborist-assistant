import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;

  const AppLogo({
    super.key,
    this.size = 120,
    this.showText = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size + (showText ? 40 : 0)),
      painter: AppLogoPainter(
        showText: showText,
        color: color ?? Colors.black,
      ),
    );
  }
}

class AppLogoPainter extends CustomPainter {
  final bool showText;
  final Color color;

  AppLogoPainter({
    required this.showText,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Calculate dimensions
    final logoSize = showText ? size.width * 0.7 : size.width;
    final centerX = size.width / 2;
    final centerY = showText ? size.height * 0.35 : size.height / 2;

    // Draw the circular background
    final circleRadius = logoSize * 0.4;
    canvas.drawCircle(
      Offset(centerX, centerY),
      circleRadius,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(centerX, centerY),
      circleRadius,
      strokePaint,
    );

    // Draw the stylized tree/antler design
    _drawTreeDesign(canvas, Offset(centerX, centerY), logoSize * 0.3, paint);

    // Draw the text if needed
    if (showText) {
      _drawText(canvas, size, color);
    }
  }

  void _drawTreeDesign(Canvas canvas, Offset center, double size, Paint paint) {
    // Draw the trunk
    final trunkRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: size * 0.15,
        height: size * 0.4,
      ),
      Radius.circular(size * 0.075),
    );
    canvas.drawRRect(trunkRect, paint);

    // Draw the main branches/antlers
    final branchPoints = [
      // Left branches
      Offset(center.dx - size * 0.25, center.dy - size * 0.2),
      Offset(center.dx - size * 0.35, center.dy - size * 0.35),
      Offset(center.dx - size * 0.2, center.dy - size * 0.4),
      // Right branches
      Offset(center.dx + size * 0.25, center.dy - size * 0.2),
      Offset(center.dx + size * 0.35, center.dy - size * 0.35),
      Offset(center.dx + size * 0.2, center.dy - size * 0.4),
      // Top branches
      Offset(center.dx, center.dy - size * 0.45),
      Offset(center.dx - size * 0.1, center.dy - size * 0.5),
      Offset(center.dx + size * 0.1, center.dy - size * 0.5),
    ];

    for (final point in branchPoints) {
      canvas.drawCircle(point, size * 0.08, paint);
    }

    // Draw connecting lines for branches
    final branchPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.06
      ..strokeCap = StrokeCap.round;

    // Main branch connections
    canvas.drawLine(
      center + Offset(0, -size * 0.2),
      branchPoints[0],
      branchPaint,
    );
    canvas.drawLine(
      center + Offset(0, -size * 0.2),
      branchPoints[3],
      branchPaint,
    );
    canvas.drawLine(
      center + Offset(0, -size * 0.2),
      branchPoints[6],
      branchPaint,
    );

    // Secondary branch connections
    canvas.drawLine(
      branchPoints[0],
      branchPoints[1],
      branchPaint,
    );
    canvas.drawLine(
      branchPoints[0],
      branchPoints[2],
      branchPaint,
    );
    canvas.drawLine(
      branchPoints[3],
      branchPoints[4],
      branchPaint,
    );
    canvas.drawLine(
      branchPoints[3],
      branchPoints[5],
      branchPaint,
    );
    canvas.drawLine(
      branchPoints[6],
      branchPoints[7],
      branchPaint,
    );
    canvas.drawLine(
      branchPoints[6],
      branchPoints[8],
      branchPaint,
    );
  }

  void _drawText(Canvas canvas, Size size, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'ARBORESTS BY NATURE',
        style: TextStyle(
          color: color,
          fontSize: size.width * 0.08,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        size.height * 0.75,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
