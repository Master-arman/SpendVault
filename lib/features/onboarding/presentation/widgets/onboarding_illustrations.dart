import 'dart:math' as math;

import 'package:flutter/material.dart';

// ── Public API ───────────────────────────────────────────────────────────────

/// Returns the [CustomPaint] illustration widget for the given slide index.
Widget onboardingIllustration(int index, {double size = 260}) {
  return switch (index) {
    0 => _IllustrationFrame(
        size: size,
        painter: _StoragePainter(),
      ),
    1 => _IllustrationFrame(
        size: size,
        painter: _LedgerPainter(),
      ),
    _ => _IllustrationFrame(
        size: size,
        painter: _AutoDetectPainter(),
      ),
  };
}

// ── Frame wrapper ─────────────────────────────────────────────────────────────

class _IllustrationFrame extends StatelessWidget {
  const _IllustrationFrame({required this.size, required this.painter});

  final double size;
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: painter),
    );
  }
}

// ── Slide 1: Complete On-Device Storage ──────────────────────────────────────
//
//  Visual: A phone silhouette with a teal shield in the centre.
//          A crossed-out cloud/server to the right signals "zero servers".

class _StoragePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // -- Background halo -------------------------------------------------------
    final Paint halo = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFF0D9488).withOpacity(0.18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 110));
    canvas.drawCircle(Offset(cx, cy), 110, halo);

    // -- Phone body ------------------------------------------------------------
    final RRect phone = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 10), width: 80, height: 130),
      const Radius.circular(16),
    );
    canvas.drawRRect(
      phone,
      Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      phone,
      Paint()
        ..color = const Color(0xFF14B8A6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Phone notch
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - 50), width: 24, height: 6),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF334155),
    );

    // -- Shield ----------------------------------------------------------------
    _drawShield(canvas, Offset(cx, cy + 10), 32);

    // -- Crossed-out server (top-right) ----------------------------------------
    _drawCrossedServer(canvas, Offset(cx + 70, cy - 40), 24);
  }

  void _drawShield(Canvas canvas, Offset centre, double r) {
    final Path shield = Path();
    shield.moveTo(centre.dx, centre.dy - r);
    shield.cubicTo(
      centre.dx + r, centre.dy - r * 0.6,
      centre.dx + r, centre.dy + r * 0.2,
      centre.dx, centre.dy + r,
    );
    shield.cubicTo(
      centre.dx - r, centre.dy + r * 0.2,
      centre.dx - r, centre.dy - r * 0.6,
      centre.dx, centre.dy - r,
    );
    shield.close();

    canvas.drawPath(
      shield,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFF0D9488), Color(0xFF2DD4BF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(
          Rect.fromCenter(center: centre, width: r * 2, height: r * 2),
        ),
    );

    // Check mark inside shield
    final Paint check = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final Path tick = Path()
      ..moveTo(centre.dx - r * 0.35, centre.dy)
      ..lineTo(centre.dx - r * 0.05, centre.dy + r * 0.3)
      ..lineTo(centre.dx + r * 0.4, centre.dy - r * 0.3);
    canvas.drawPath(tick, check);
  }

  void _drawCrossedServer(Canvas canvas, Offset centre, double r) {
    // Server box
    final RRect serverBox = RRect.fromRectAndRadius(
      Rect.fromCenter(center: centre, width: r * 1.6, height: r * 1.2),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      serverBox,
      Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      serverBox,
      Paint()
        ..color = const Color(0xFF475569)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Server lines
    final Paint line = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(centre.dx - r * 0.6, centre.dy - r * 0.15),
      Offset(centre.dx + r * 0.6, centre.dy - r * 0.15),
      line,
    );

    // Red cross
    final Paint cross = Paint()
      ..color = const Color(0xFFF43F5E)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(centre.dx - r * 0.5, centre.dy - r * 0.5),
      Offset(centre.dx + r * 0.5, centre.dy + r * 0.5),
      cross,
    );
    canvas.drawLine(
      Offset(centre.dx + r * 0.5, centre.dy - r * 0.5),
      Offset(centre.dx - r * 0.5, centre.dy + r * 0.5),
      cross,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Slide 2: Multi-Account Ledger ────────────────────────────────────────────
//
//  Visual: Three stacked, offset rounded-rect cards labelled Bank, UPI, Cash.

class _LedgerPainter extends CustomPainter {
  static const List<Map<String, dynamic>> _cards = <Map<String, dynamic>>[
    <String, dynamic>{
      'label': 'BANK',
      'color': Color(0xFF0D9488),
      'offsetY': 20.0,
    },
    <String, dynamic>{
      'label': 'UPI',
      'color': Color(0xFF0891B2),
      'offsetY': 0.0,
    },
    <String, dynamic>{
      'label': 'CASH',
      'color': Color(0xFF7C3AED),
      'offsetY': -20.0,
    },
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // Background halo
    final Paint halo = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFF0891B2).withOpacity(0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 110));
    canvas.drawCircle(Offset(cx, cy), 110, halo);

    // Draw cards back-to-front
    for (int i = _cards.length - 1; i >= 0; i--) {
      final Map<String, dynamic> card = _cards[i];
      final double dy = card['offsetY'] as double;
      final Color color = card['color'] as Color;
      final String label = card['label'] as String;
      _drawCard(canvas, cx, cy + dy, color, label, i);
    }

    // Sync icon at bottom
    _drawSyncArrows(canvas, Offset(cx, cy + 80));
  }

  void _drawCard(
    Canvas canvas,
    double cx,
    double cy,
    Color color,
    String label,
    int index,
  ) {
    final RRect card = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: 160,
        height: 70,
      ),
      const Radius.circular(14),
    );

    // Card fill
    canvas.drawRRect(
      card,
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(card.outerRect),
    );

    // Card stripe (chip simulation)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 70, cy - 12, 28, 20),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white.withOpacity(0.3),
    );

    // Label text via TextPainter
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - 70, cy + 18));

    // Amount placeholder dots
    final Paint dot = Paint()..color = Colors.white.withOpacity(0.5);
    for (int d = 0; d < 4; d++) {
      canvas.drawCircle(Offset(cx + 10 + d * 12.0, cy + 8), 3, dot);
    }
  }

  void _drawSyncArrows(Canvas canvas, Offset centre) {
    final Paint p = Paint()
      ..color = const Color(0xFF14B8A6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Two semi-circle arrows suggesting sync
    canvas.drawArc(
      Rect.fromCenter(center: centre, width: 24, height: 24),
      -math.pi * 0.8,
      math.pi * 1.4,
      false,
      p,
    );
    // Arrow head
    canvas.drawLine(
      Offset(centre.dx + 11, centre.dy - 5),
      Offset(centre.dx + 11, centre.dy + 1),
      p,
    );
    canvas.drawLine(
      Offset(centre.dx + 11, centre.dy - 5),
      Offset(centre.dx + 6, centre.dy - 5),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Slide 3: Automatic Detection ─────────────────────────────────────────────
//
//  Visual: A notification bell with radiating arc waves and data-flow arrows.

class _AutoDetectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2 - 10;

    // Background halo
    final Paint halo = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFF7C3AED).withOpacity(0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 110));
    canvas.drawCircle(Offset(cx, cy), 110, halo);

    // Radiating arcs (3 waves)
    for (int i = 1; i <= 3; i++) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, cy), width: i * 60.0, height: i * 60.0),
        -math.pi * 0.7,
        math.pi * 1.4,
        false,
        Paint()
          ..color = const Color(0xFF14B8A6).withOpacity(0.5 - i * 0.12)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }

    // Bell body
    _drawBell(canvas, Offset(cx, cy));

    // Data-flow arrow rows (simulating parsed notification data)
    _drawDataRows(canvas, Offset(cx, cy + 70));
  }

  void _drawBell(Canvas canvas, Offset centre) {
    final Path bell = Path();
    // Bell dome
    bell.moveTo(centre.dx, centre.dy - 40);
    bell.cubicTo(
      centre.dx + 30, centre.dy - 40,
      centre.dx + 35, centre.dy - 10,
      centre.dx + 35, centre.dy + 15,
    );
    bell.lineTo(centre.dx - 35, centre.dy + 15);
    bell.cubicTo(
      centre.dx - 35, centre.dy - 10,
      centre.dx - 30, centre.dy - 40,
      centre.dx, centre.dy - 40,
    );
    bell.close();

    // Bell platform
    bell.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(centre.dx, centre.dy + 20), width: 80, height: 10),
      const Radius.circular(5),
    ));

    canvas.drawPath(
      bell,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFF0D9488), Color(0xFF7C3AED)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromCenter(center: centre, width: 80, height: 80)),
    );

    // Clapper (small circle at bottom)
    canvas.drawCircle(
      Offset(centre.dx, centre.dy + 29),
      6,
      Paint()..color = const Color(0xFF2DD4BF),
    );

    // Notification dot (top-right of bell)
    canvas.drawCircle(
      Offset(centre.dx + 28, centre.dy - 36),
      7,
      Paint()..color = const Color(0xFFF43F5E),
    );
    canvas.drawCircle(
      Offset(centre.dx + 28, centre.dy - 36),
      7,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawDataRows(Canvas canvas, Offset origin) {
    // Three horizontal "parsed data" indicator bars
    final List<double> widths = <double>[80, 55, 65];
    for (int i = 0; i < widths.length; i++) {
      final double y = origin.dy + i * 12.0;
      final RRect bar = RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx - 40, y, widths[i], 6),
        const Radius.circular(3),
      );
      canvas.drawRRect(
        bar,
        Paint()
          ..color = const Color(0xFF14B8A6).withOpacity(0.6 - i * 0.15),
      );
    }

    // Arrow pointing from bell to bars
    final Paint arrow = Paint()
      ..color = const Color(0xFF14B8A6)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(origin.dx, origin.dy - 8),
      Offset(origin.dx, origin.dy + 3),
      arrow,
    );
    // Arrowhead
    canvas.drawLine(
      Offset(origin.dx - 4, origin.dy - 2),
      Offset(origin.dx, origin.dy + 3),
      arrow,
    );
    canvas.drawLine(
      Offset(origin.dx + 4, origin.dy - 2),
      Offset(origin.dx, origin.dy + 3),
      arrow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
