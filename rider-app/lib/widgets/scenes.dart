import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'brand.dart';

/// Painted stand-ins for destination photography until real photos exist.
enum SceneKind { skyline, beach, nature, art, heritage, food, nightlife, van }

class Scene extends StatelessWidget {
  const Scene(this.kind, {super.key, this.radius = 18, this.height});
  final SceneKind kind;
  final double radius;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _ScenePainter(kind)),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.kind);
  final SceneKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    switch (kind) {
      case SceneKind.skyline:
        _sky(canvas, rect, const [
          Color(0xFF6FA8C9),
          Color(0xFFF6B26B),
          Color(0xFFF7D79B),
        ]);
        canvas.drawCircle(
          Offset(w * 0.72, h * 0.42),
          h * 0.09,
          Paint()..color = const Color(0xFFFFE7A8),
        );
        // Keep the skyline in a band at the bottom so tall frames don't
        // stretch the towers.
        final band = min(h, w * 1.05);
        canvas.save();
        canvas.translate(0, h * 0.92 - band);
        SkylinePainter(
          buildingColor: const Color(0xFF2E4B5C),
          lineColor: Colors.white,
          water: true,
        ).paint(canvas, Size(w, band));
        canvas.restore();
        _water(
          canvas,
          Rect.fromLTWH(0, h * 0.72, w, h * 0.28),
          const Color(0xFF3F6E8A),
        );
      case SceneKind.beach:
        _sky(canvas, rect, const [Color(0xFF7CC6F2), Color(0xFFCDEBFA)]);
        _water(
          canvas,
          Rect.fromLTWH(0, h * 0.5, w, h * 0.2),
          const Color(0xFF2B9BD1),
        );
        final sand = Path()
          ..moveTo(0, h * 0.68)
          ..quadraticBezierTo(w * 0.5, h * 0.6, w, h * 0.7)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close();
        canvas.drawPath(sand, Paint()..color = const Color(0xFFF2DDA4));
        _palm(canvas, Offset(w * 0.18, h * 0.85), h * 0.6, 0.25);
        _palm(canvas, Offset(w * 0.82, h * 0.88), h * 0.5, -0.2);
        // Umbrella.
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(w * 0.55, h * 0.72),
            width: w * 0.2,
            height: h * 0.16,
          ),
          pi,
          pi,
          true,
          Paint()..color = CaboColors.red,
        );
        canvas.drawLine(
          Offset(w * 0.55, h * 0.72),
          Offset(w * 0.55, h * 0.86),
          Paint()
            ..color = Colors.brown
            ..strokeWidth = 2,
        );
      case SceneKind.nature:
        _sky(canvas, rect, const [Color(0xFF9ED0E8), Color(0xFFDDF0E0)]);
        final rnd = Random(3);
        for (var i = 0; i < 14; i++) {
          final x = rnd.nextDouble() * w;
          final r = h * (0.12 + rnd.nextDouble() * 0.14);
          canvas.drawCircle(
            Offset(x, h * 0.45),
            r,
            Paint()
              ..color = Color.lerp(
                const Color(0xFF2F7D3A),
                const Color(0xFF5FAF4E),
                rnd.nextDouble(),
              )!,
          );
        }
        _water(
          canvas,
          Rect.fromLTWH(0, h * 0.62, w, h * 0.38),
          const Color(0xFF4F9AB4),
        );
        // Canopy walkway.
        final wood = Paint()
          ..color = const Color(0xFF8A5A2B)
          ..strokeWidth = 5
          ..style = PaintingStyle.stroke;
        final deck = Path()
          ..moveTo(-10, h * 0.7)
          ..quadraticBezierTo(w * 0.5, h * 0.5, w + 10, h * 0.66);
        canvas.drawPath(deck, wood);
        canvas.drawPath(
          deck.shift(Offset(0, -h * 0.08)),
          wood..strokeWidth = 2,
        );
        for (var i = 1; i < 10; i++) {
          final x = w * i / 10;
          final y = h * 0.7 - sin(pi * i / 10) * h * 0.14;
          canvas.drawLine(Offset(x, y), Offset(x, y - h * 0.08), wood);
        }
      case SceneKind.art:
        canvas.drawRect(rect, Paint()..color = const Color(0xFFF3E7D3));
        const colors = [
          Color(0xFFE85D3A),
          Color(0xFF1F7A8C),
          Color(0xFFF2B33D),
          Color(0xFF6B3FA0),
          Color(0xFF2E8B57),
          Color(0xFFD94E8F),
        ];
        final frames = [
          Rect.fromLTWH(w * 0.06, h * 0.14, w * 0.26, h * 0.38),
          Rect.fromLTWH(w * 0.38, h * 0.08, w * 0.24, h * 0.3),
          Rect.fromLTWH(w * 0.68, h * 0.16, w * 0.26, h * 0.34),
          Rect.fromLTWH(w * 0.4, h * 0.44, w * 0.22, h * 0.24),
        ];
        for (var i = 0; i < frames.length; i++) {
          final f = frames[i];
          canvas.drawRect(
            f.inflate(4),
            Paint()..color = const Color(0xFF5B3A1E),
          );
          canvas.drawRect(f, Paint()..color = colors[i]);
          canvas.drawCircle(
            f.center,
            f.shortestSide * 0.25,
            Paint()..color = colors[(i + 2) % colors.length],
          );
          canvas.drawLine(
            f.topLeft,
            f.bottomRight,
            Paint()
              ..color = Colors.white54
              ..strokeWidth = 2,
          );
        }
        canvas.drawRect(
          Rect.fromLTWH(0, h * 0.78, w, h * 0.22),
          Paint()..color = const Color(0xFFB98B5E),
        );
        _person(canvas, Offset(w * 0.2, h * 0.78), h * 0.32, CaboColors.blue);
        _person(canvas, Offset(w * 0.82, h * 0.78), h * 0.3, CaboColors.orange);
      case SceneKind.heritage:
        _sky(canvas, rect, const [Color(0xFF8CC3E3), Color(0xFFF1E3C6)]);
        final wall = Paint()..color = const Color(0xFFE9C48F);
        canvas.drawRect(
          Rect.fromLTWH(w * 0.12, h * 0.36, w * 0.76, h * 0.5),
          wall,
        );
        final dark = Paint()..color = const Color(0xFF7A4E2D);
        for (var i = 0; i < 5; i++) {
          final x = w * (0.18 + i * 0.14);
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              Rect.fromLTWH(x, h * 0.5, w * 0.08, h * 0.2),
              topLeft: Radius.circular(w * 0.04),
              topRight: Radius.circular(w * 0.04),
            ),
            dark,
          );
        }
        final roof = Path()
          ..moveTo(w * 0.08, h * 0.38)
          ..lineTo(w * 0.5, h * 0.16)
          ..lineTo(w * 0.92, h * 0.38)
          ..close();
        canvas.drawPath(roof, Paint()..color = const Color(0xFFB4532A));
        canvas.drawRect(
          Rect.fromLTWH(0, h * 0.86, w, h * 0.14),
          Paint()..color = const Color(0xFFCFB58B),
        );
      case SceneKind.food:
        canvas.drawRect(rect, Paint()..color = const Color(0xFF6B3E26));
        final plate = Offset(w * 0.5, h * 0.55);
        canvas.drawCircle(plate, h * 0.36, Paint()..color = Colors.white);
        canvas.drawCircle(
          plate,
          h * 0.28,
          Paint()..color = const Color(0xFFE8572A),
        );
        final rnd = Random(9);
        for (var i = 0; i < 14; i++) {
          final a = rnd.nextDouble() * 2 * pi;
          final d = rnd.nextDouble() * h * 0.22;
          canvas.drawCircle(
            plate + Offset(cos(a) * d, sin(a) * d),
            h * 0.03,
            Paint()
              ..color = i.isEven
                  ? const Color(0xFF8B2E12)
                  : const Color(0xFF3E8E41),
          );
        }
        canvas.drawCircle(
          Offset(w * 0.15, h * 0.3),
          h * 0.12,
          Paint()..color = const Color(0xFFF2C14E),
        );
      case SceneKind.nightlife:
        _sky(canvas, rect, const [Color(0xFF1B1035), Color(0xFF4A1D6B)]);
        final rnd = Random(5);
        for (var i = 0; i < 6; i++) {
          final c = Offset(rnd.nextDouble() * w, rnd.nextDouble() * h * 0.6);
          canvas.drawCircle(
            c,
            h * 0.2,
            Paint()
              ..shader = RadialGradient(
                colors: [
                  [
                    CaboColors.yellow,
                    const Color(0xFFE040FB),
                    CaboColors.blue,
                  ][i % 3].withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ).createShader(Rect.fromCircle(center: c, radius: h * 0.2)),
          );
        }
        SkylinePainter(
          buildingColor: const Color(0xFF0E0820),
          lineColor: const Color(0xFFFFE082),
        ).paint(canvas, Size(w, h));
      case SceneKind.van:
        _sky(canvas, rect, const [Color(0xFFDDEFE3), Color(0xFFF6FBF7)]);
        final body = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.12, h * 0.3, w * 0.76, h * 0.42),
          Radius.circular(h * 0.1),
        );
        canvas.drawRRect(body, Paint()..color = const Color(0xFF1E2A2F));
        final glass = Paint()..color = const Color(0xFF8FB4C4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.17, h * 0.35, w * 0.2, h * 0.14),
            const Radius.circular(6),
          ),
          glass,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.4, h * 0.35, w * 0.2, h * 0.14),
            const Radius.circular(6),
          ),
          glass,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.63, h * 0.35, w * 0.2, h * 0.14),
            const Radius.circular(6),
          ),
          glass,
        );
        for (final x in [0.28, 0.72]) {
          canvas.drawCircle(
            Offset(w * x, h * 0.72),
            h * 0.09,
            Paint()..color = const Color(0xFF111111),
          );
          canvas.drawCircle(
            Offset(w * x, h * 0.72),
            h * 0.04,
            Paint()..color = const Color(0xFF9E9E9E),
          );
        }
        // Wheelchair ramp.
        final ramp = Path()
          ..moveTo(w * 0.42, h * 0.68)
          ..lineTo(w * 0.62, h * 0.68)
          ..lineTo(w * 0.7, h * 0.84)
          ..lineTo(w * 0.34, h * 0.84)
          ..close();
        canvas.drawPath(ramp, Paint()..color = CaboColors.yellow);
        canvas.drawRect(
          Rect.fromLTWH(0, h * 0.84, w, h * 0.16),
          Paint()..color = const Color(0xFFC9D6CC),
        );
    }
  }

  void _sky(Canvas canvas, Rect rect, List<Color> colors) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(rect),
    );
  }

  void _water(Canvas canvas, Rect r, Color c) {
    canvas.drawRect(r, Paint()..color = c);
    final wave = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;
    for (var i = 1; i < 5; i++) {
      final y = r.top + r.height * i / 5;
      canvas.drawLine(
        Offset(r.left + r.width * 0.1 * i, y),
        Offset(r.left + r.width * (0.5 + 0.08 * i), y),
        wave,
      );
    }
  }

  void _palm(Canvas canvas, Offset base, double height, double lean) {
    final top = base + Offset(height * lean, -height);
    final trunk = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(
        base.dx + height * lean * 0.2,
        base.dy - height * 0.5,
        top.dx,
        top.dy,
      );
    canvas.drawPath(
      trunk,
      Paint()
        ..color = const Color(0xFF7B5530)
        ..strokeWidth = height * 0.06
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    final leaf = Paint()
      ..color = const Color(0xFF2E8B3D)
      ..strokeWidth = height * 0.05
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final a = -pi / 2 + (i - 2.5) * 0.55;
      final end =
          top +
          Offset(
            cos(a) * height * 0.38,
            sin(a) * height * 0.22 + height * 0.12,
          );
      final ctrl =
          top +
          Offset(cos(a) * height * 0.2, sin(a) * height * 0.3 - height * 0.05);
      canvas.drawPath(
        Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy),
        leaf,
      );
    }
  }

  void _person(Canvas canvas, Offset feet, double height, Color shirt) {
    canvas.drawCircle(
      feet + Offset(0, -height * 0.88),
      height * 0.1,
      Paint()..color = const Color(0xFF6B4226),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: feet + Offset(0, -height * 0.52),
          width: height * 0.3,
          height: height * 0.5,
        ),
        Radius.circular(height * 0.1),
      ),
      Paint()..color = shirt,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: feet + Offset(0, -height * 0.14),
        width: height * 0.22,
        height: height * 0.28,
      ),
      Paint()..color = const Color(0xFF263238),
    );
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) => old.kind != kind;
}
