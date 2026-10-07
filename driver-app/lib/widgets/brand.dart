import 'package:flutter/material.dart';

import '../theme.dart';

/// The Cabo wordmark: "Cab" followed by an "o" drawn as a ring with the
/// yellow location pin inside, and a yellow smile under the letters.
class CaboLogo extends StatelessWidget {
  const CaboLogo({
    super.key,
    this.size = 64,
    this.driverLabel = true,
    this.color = Colors.white,
  });
  final double size;
  final bool driverLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final painter = _WordmarkPainter(size, color);
    return Semantics(
      label: driverLabel ? 'Cabo Driver' : 'Cabo',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(size: painter.layoutSize, painter: painter),
          if (driverLabel) ...[
            SizedBox(height: size * 0.14),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: size * 0.18,
                vertical: size * 0.05,
              ),
              decoration: BoxDecoration(
                color: CaboColors.yellow,
                borderRadius: BorderRadius.circular(size),
              ),
              child: Text(
                'DRIVER',
                style: TextStyle(
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.w800,
                  color: CaboColors.onYellow,
                  letterSpacing: size * 0.06,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WordmarkPainter extends CustomPainter {
  _WordmarkPainter(this.fontSize, this.color)
    : _text = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -fontSize * 0.02,
            color: color,
          ),
          children: const [
            TextSpan(text: 'Cab'),
            // Reserves the space of a real "o"; the ring is painted over it.
            TextSpan(
              text: 'o',
              style: TextStyle(color: Color(0x00000000)),
            ),
          ],
        ),
      )..layout();

  final double fontSize;
  final Color color;
  final TextPainter _text;

  double get _baseline => _text.computeLineMetrics().first.baseline;

  Size get layoutSize =>
      Size(_text.width + fontSize * 0.04, _baseline + fontSize * 0.3);

  @override
  void paint(Canvas canvas, Size size) {
    _text.paint(canvas, Offset.zero);
    final s = fontSize;
    final baseline = _baseline;

    Rect box(int start) => _text
        .getBoxesForSelection(
          TextSelection(baseOffset: start, extentOffset: start + 1),
        )
        .first
        .toRect();
    final b = box(2);
    final o = box(3);

    // The "o": a thick ring as tall as the x-height.
    const xHeight = 0.58;
    final stroke = s * 0.12;
    final radius = s * xHeight / 2 - stroke / 2;
    final center = Offset(o.center.dx, baseline - s * xHeight / 2);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    // Yellow pin inside the ring.
    final inner = radius - stroke / 2;
    final headR = inner * 0.7;
    final headC = Offset(center.dx, center.dy - inner * 0.2);
    final tip = Offset(center.dx, center.dy + inner * 0.92);
    final yellow = Paint()..color = CaboColors.yellow;
    canvas.drawCircle(headC, headR, yellow);
    final tail = Path()
      ..moveTo(headC.dx - headR * 0.9, headC.dy + headR * 0.45)
      ..quadraticBezierTo(
        headC.dx - headR * 0.5,
        tip.dy - headR * 0.6,
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(
        headC.dx + headR * 0.5,
        tip.dy - headR * 0.6,
        headC.dx + headR * 0.9,
        headC.dy + headR * 0.45,
      )
      ..close();
    canvas.drawPath(tail, yellow);
    canvas.drawCircle(headC, headR * 0.4, Paint()..color = CaboColors.onYellow);

    // Smile from under the "b" to under the "o".
    final smile = Path()
      ..moveTo(b.left + b.width * 0.15, baseline + s * 0.08)
      ..quadraticBezierTo(
        (b.left + o.center.dx) / 2,
        baseline + s * 0.3,
        o.left + o.width * 0.35,
        baseline + s * 0.08,
      );
    canvas.drawPath(
      smile,
      Paint()
        ..color = CaboColors.yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.075
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _WordmarkPainter old) =>
      old.fontSize != fontSize || old.color != color;
}

/// Lagos skyline silhouette with a line drawing of the Lekki-Ikoyi Link Bridge.
class SkylinePainter extends CustomPainter {
  SkylinePainter({
    this.buildingColor = const Color(0xFF0D4A2E),
    this.lineColor = Colors.white,
    this.water = false,
  });

  final Color buildingColor;
  final Color lineColor;
  final bool water;

  // (left, width, height) as fractions of the canvas.
  static const _towers = [
    (0.00, 0.07, 0.30),
    (0.06, 0.06, 0.46),
    (0.12, 0.05, 0.38),
    (0.17, 0.08, 0.62),
    (0.25, 0.05, 0.44),
    (0.30, 0.07, 0.72),
    (0.37, 0.06, 0.52),
    (0.55, 0.06, 0.48),
    (0.61, 0.08, 0.82),
    (0.69, 0.05, 0.58),
    (0.74, 0.07, 0.68),
    (0.81, 0.06, 0.40),
    (0.87, 0.07, 0.55),
    (0.94, 0.06, 0.34),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final base = h * 0.78;
    final fill = Paint()..color = buildingColor;
    for (final (l, bw, bh) in _towers) {
      final rect = Rect.fromLTRB(l * w, base - bh * base, (l + bw) * w, base);
      canvas.drawRect(rect, fill);
      // Windows.
      final win = Paint()..color = lineColor.withValues(alpha: 0.07);
      for (var y = rect.top + 8; y < rect.bottom - 6; y += 10) {
        canvas.drawRect(
          Rect.fromLTWH(rect.left + 4, y, rect.width - 8, 3),
          win,
        );
      }
    }
    // Antenna on the tallest tower.
    canvas.drawRect(
      Rect.fromLTWH(0.645 * w, base - 0.82 * base - 18, 2, 18),
      fill,
    );

    final line = Paint()
      ..color = lineColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    // Bridge deck.
    final deckY = base - h * 0.06;
    canvas.drawLine(Offset(0, deckY + 10), Offset(w, deckY - 4), line);
    // Pylon: an inverted "Y" like the Lekki-Ikoyi Link Bridge.
    final px = w * 0.47;
    final top = Offset(px, base - h * 0.62);
    final mid = Offset(px, deckY - h * 0.14);
    canvas.drawLine(top, mid, line..strokeWidth = 2.6);
    canvas.drawLine(mid, Offset(px - w * 0.03, deckY + 3), line);
    canvas.drawLine(mid, Offset(px + w * 0.03, deckY + 3), line);
    line.strokeWidth = 1;
    // Cables.
    for (var i = 1; i <= 7; i++) {
      final t = i / 7;
      final anchor = Offset(top.dx, top.dy + (mid.dy - top.dy) * t * 0.6);
      canvas.drawLine(anchor, Offset(px - w * 0.36 * t, deckY + 10 * t), line);
      canvas.drawLine(anchor, Offset(px + w * 0.36 * t, deckY - 4 * t), line);
    }

    if (water) {
      final wp = Paint()..color = lineColor.withValues(alpha: 0.12);
      for (var i = 0; i < 4; i++) {
        final y = base + 8 + i * 9.0;
        canvas.drawLine(
          Offset(w * (0.1 + i * 0.07), y),
          Offset(w * (0.9 - i * 0.05), y),
          wp..strokeWidth = 1.2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Decorative illustration: an icon in layered circles.
class HeroIllustration extends StatelessWidget {
  const HeroIllustration(
    this.icon, {
    super.key,
    this.size = 200,
    this.color = CaboColors.yellow,
    this.badges = const [],
  });
  final IconData icon;
  final double size;
  final Color color;
  final List<IconData> badges;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.08),
            ),
          ),
          Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.14),
            ),
          ),
          Container(
            width: size * 0.48,
            height: size * 0.48,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(icon, size: size * 0.24, color: CaboColors.onYellow),
          ),
          for (var i = 0; i < badges.length; i++)
            Align(
              alignment: [
                const Alignment(0.85, -0.75),
                const Alignment(-0.9, 0.55),
                const Alignment(0.8, 0.8),
              ][i % 3],
              child: Container(
                width: size * 0.2,
                height: size * 0.2,
                decoration: BoxDecoration(
                  color: CaboColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(size * 0.07),
                  border: Border.all(color: CaboColors.outline),
                ),
                child: Icon(
                  badges[i],
                  color: CaboColors.yellow,
                  size: size * 0.1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
