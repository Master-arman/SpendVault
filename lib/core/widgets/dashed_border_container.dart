import 'dart:ui';
import 'package:flutter/material.dart';

/// Container widget that draws a customizable dashed border around its child.
class DashedBorderContainer extends StatelessWidget {
  const DashedBorderContainer({
    required this.child,
    this.color = const Color(0xFF64748B),
    this.strokeWidth = 1.5,
    this.dashLength = 6.0,
    this.dashSpace = 4.0,
    this.borderRadius = 16.0,
    this.backgroundColor,
    this.padding,
    super.key,
  });

  final Widget child;
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashSpace;
  final double borderRadius;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        dashLength: dashLength,
        dashSpace: dashSpace,
        borderRadius: borderRadius,
        backgroundColor: backgroundColor,
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashSpace,
    required this.borderRadius,
    this.backgroundColor,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashSpace;
  final double borderRadius;
  final Color? backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    if (backgroundColor != null) {
      final Paint bgPaint = Paint()
        ..color = backgroundColor!
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, bgPaint);
    }

    final Paint borderPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()..addRRect(rrect);
    final Path dashedPath = Path();

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double length = (distance + dashLength < metric.length)
            ? dashLength
            : metric.length - distance;
        dashedPath.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += dashLength + dashSpace;
      }
    }

    canvas.drawPath(dashedPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
