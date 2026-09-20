import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate high resolution SpendVault brand assets', () async {
    final iconsDir = Directory('assets/icons');
    final splashDir = Directory('assets/splash');
    if (!iconsDir.existsSync()) iconsDir.createSync(recursive: true);
    if (!splashDir.existsSync()) splashDir.createSync(recursive: true);

    // 1. Full App Icon (1024x1024) - Dark Slate Background with Emerald/Indigo Shield & Vault Emblem
    await _renderAndSave(
      width: 1024,
      height: 1024,
      file: File('assets/icons/app_icon.png'),
      painter: (canvas, size) {
        // Dark Slate Background #0A0F1D
        final bgPaint = Paint()..color = const Color(0xFF0A0F1D);
        canvas.drawRect(Offset.zero & size, bgPaint);

        // Subtle Radial Background Glow
        final glowPaint = Paint()
          ..shader = ui.Gradient.radial(
            Offset(size.width / 2, size.height / 2),
            size.width * 0.45,
            [
              const Color(0xFF10B981).withOpacity(0.18),
              const Color(0xFF6366F1).withOpacity(0.12),
              Colors.transparent,
            ],
            [0.0, 0.6, 1.0],
          );
        canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width * 0.45, glowPaint);

        _drawEmblem(canvas, size, scale: 1.0);
      },
    );

    // 2. Adaptive Foreground (1024x1024 Transparent Background)
    await _renderAndSave(
      width: 1024,
      height: 1024,
      file: File('assets/icons/app_icon_foreground.png'),
      painter: (canvas, size) {
        _drawEmblem(canvas, size, scale: 0.72);
      },
    );

    // 3. Splash Logo (512x512)
    await _renderAndSave(
      width: 512,
      height: 512,
      file: File('assets/splash/splash_logo.png'),
      painter: (canvas, size) {
        _drawEmblem(canvas, size, scale: 0.85);
      },
    );

    // 4. Splash Branding (512x128)
    await _renderAndSave(
      width: 512,
      height: 128,
      file: File('assets/splash/splash_branding.png'),
      painter: (canvas, size) {
        final textPainter = TextPainter(
          text: const TextSpan(
            text: 'SPENDVAULT',
            style: TextStyle(
              color: Color(0xFFF8FAFC),
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: 6.0,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
        );
      },
    );

    expect(File('assets/icons/app_icon.png').existsSync(), isTrue);
    expect(File('assets/icons/app_icon_foreground.png').existsSync(), isTrue);
    expect(File('assets/splash/splash_logo.png').existsSync(), isTrue);
    expect(File('assets/splash/splash_branding.png').existsSync(), isTrue);
  });
}

void _drawEmblem(Canvas canvas, Size size, {double scale = 1.0}) {
  final center = Offset(size.width / 2, size.height / 2);
  final emblemSize = size.width * 0.55 * scale;
  final half = emblemSize / 2;

  // Outer Shield Path
  final shieldPath = Path();
  final top = center.dy - half;
  final bottom = center.dy + half * 1.1;
  final left = center.dx - half;
  final right = center.dx + half;

  shieldPath.moveTo(center.dx, top);
  shieldPath.cubicTo(right, top, right, center.dy + half * 0.2, center.dx, bottom);
  shieldPath.cubicTo(left, center.dy + half * 0.2, left, top, center.dx, top);
  shieldPath.close();

  // Emerald to Indigo Gradient
  final shieldGradient = ui.Gradient.linear(
    Offset(left, top),
    Offset(right, bottom),
    [
      const Color(0xFF10B981), // Emerald
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Purple
    ],
    [0.0, 0.35, 0.75, 1.0],
  );

  final shieldPaint = Paint()
    ..shader = shieldGradient
    ..style = PaintingStyle.fill;

  // Draw Shield
  canvas.drawPath(shieldPath, shieldPaint);

  // Inner Vault Card / Geometric Diamond
  final innerPath = Path();
  final innerOffset = emblemSize * 0.22;
  innerPath.moveTo(center.dx, center.dy - innerOffset * 1.2);
  innerPath.lineTo(center.dx + innerOffset * 1.1, center.dy);
  innerPath.lineTo(center.dx, center.dy + innerOffset * 1.3);
  innerPath.lineTo(center.dx - innerOffset * 1.1, center.dy);
  innerPath.close();

  final innerPaint = Paint()
    ..color = const Color(0xFF0A0F1D)
    ..style = PaintingStyle.fill;
  canvas.drawPath(innerPath, innerPaint);

  // Central Accent Dot / Security Core
  final corePaint = Paint()
    ..shader = ui.Gradient.linear(
      Offset(center.dx - 15, center.dy - 15),
      Offset(center.dx + 15, center.dy + 15),
      [const Color(0xFF10B981), const Color(0xFF6366F1)],
    );
  canvas.drawCircle(center, emblemSize * 0.1, corePaint);
}

Future<void> _renderAndSave({
  required int width,
  required int height,
  required File file,
  required void Function(Canvas canvas, Size size) painter,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
  painter(canvas, Size(width.toDouble(), height.toDouble()));

  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();
  await file.writeAsBytes(bytes);
}
