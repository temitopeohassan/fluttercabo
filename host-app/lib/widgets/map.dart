import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

enum MarkerKind { driver, pickup, dropoff, stop, airport }

class MapMarker {
  const MapMarker(this.position, this.kind, {this.label});
  final Offset position; // Fractions of the map size.
  final MarkerKind kind;
  final String? label;
}

class HeatZone {
  const HeatZone(this.center, this.radius, this.intensity, {this.label});
  final Offset center; // Fractions of the map size.
  final double radius; // Fraction of the map width.
  final double intensity; // 0..1
  final String? label;
}

/// A stylised dark map of Lagos drawn without any map SDK, used as a
/// stand-in until a real maps provider is wired in.
class CaboMap extends StatelessWidget {
  const CaboMap({
    super.key,
    this.route = const [],
    this.markers = const [],
    this.heat = const [],
    this.routeColor = CaboColors.yellow,
    this.dimmed = false,
    this.serviceArea = false,
    this.labels = true,
  });

  final List<Offset> route;
  final List<MapMarker> markers;
  final List<HeatZone> heat;
  final Color routeColor;
  final bool dimmed;
  final bool serviceArea;
  final bool labels;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        return ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _MapPainter(
                    route: route,
                    heat: heat,
                    routeColor: routeColor,
                    serviceArea: serviceArea,
                    labels: labels,
                  ),
                ),
              ),
              for (final z in heat)
                if (z.label != null)
                  Positioned(
                    left: z.center.dx * w - 50,
                    top: z.center.dy * h - 12,
                    width: 100,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          z.label!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              for (final m in markers) _positioned(m, w, h),
              if (dimmed)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _positioned(MapMarker m, double w, double h) {
    const size = 44.0;
    final Widget icon = switch (m.kind) {
      MarkerKind.driver => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: CaboColors.yellow,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: CaboColors.yellow.withValues(alpha: 0.4),
              blurRadius: 16,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(
          Icons.navigation_rounded,
          color: CaboColors.onYellow,
          size: 22,
        ),
      ),
      MarkerKind.pickup => const Icon(
        Icons.location_on,
        color: CaboColors.brightGreen,
        size: size,
      ),
      MarkerKind.dropoff => const Icon(
        Icons.location_on,
        color: CaboColors.red,
        size: size,
      ),
      MarkerKind.stop => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: CaboColors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
      ),
      MarkerKind.airport => Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: CaboColors.blue,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.flight, color: Colors.white, size: 20),
      ),
    };
    final pinLike = m.kind == MarkerKind.pickup || m.kind == MarkerKind.dropoff;
    return Positioned(
      left: m.position.dx * w - 60,
      top: m.position.dy * h - (pinLike ? size : size / 2),
      width: 120,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          if (m.label != null)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                m.label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: CaboColors.onYellow,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.route,
    required this.heat,
    required this.routeColor,
    required this.serviceArea,
    required this.labels,
  });

  final List<Offset> route;
  final List<HeatZone> heat;
  final Color routeColor;
  final bool serviceArea;
  final bool labels;

  static const _land = Color(0xFF0C2E20);
  static const _block = Color(0xFF103827);
  static const _water = Color(0xFF0A2733);
  static const _minor = Color(0xFF1A4A35);
  static const _major = Color(0xFF2A6149);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = _land);

    // City blocks on a slightly rotated grid.
    final rnd = Random(7);
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-0.12);
    canvas.translate(-w / 2, -h / 2);
    final block = Paint()..color = _block;
    for (var x = -w * 0.2; x < w * 1.2; x += 46) {
      for (var y = -h * 0.2; y < h * 1.2; y += 38) {
        if (rnd.nextDouble() < 0.8) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x + 4, y + 4, 38 + rnd.nextDouble() * 4, 30),
              const Radius.circular(3),
            ),
            block,
          );
        }
      }
    }
    canvas.restore();

    // Lagos lagoon and the Atlantic.
    final lagoon = Path()
      ..moveTo(0, h * 0.42)
      ..cubicTo(w * 0.3, h * 0.36, w * 0.45, h * 0.55, w, h * 0.47)
      ..lineTo(w, h * 0.56)
      ..cubicTo(w * 0.55, h * 0.64, w * 0.3, h * 0.47, 0, h * 0.53)
      ..close();
    final ocean = Path()
      ..moveTo(0, h * 0.93)
      ..cubicTo(w * 0.4, h * 0.88, w * 0.7, h * 0.95, w, h * 0.9)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final water = Paint()..color = _water;
    canvas.drawPath(lagoon, water);
    canvas.drawPath(ocean, water);

    // Roads.
    final minor = Paint()
      ..color = _minor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 9; i++) {
      final y = h * (0.06 + i * 0.11);
      canvas.drawLine(Offset(0, y + 10), Offset(w, y - 20), minor);
    }
    final major = Paint()
      ..color = _major
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.15, 0)
        ..cubicTo(w * 0.25, h * 0.3, w * 0.2, h * 0.6, w * 0.32, h),
      major,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.72)
        ..cubicTo(w * 0.4, h * 0.68, w * 0.6, h * 0.78, w, h * 0.7),
      major,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.7, 0)
        ..cubicTo(w * 0.65, h * 0.25, w * 0.85, h * 0.5, w * 0.78, h),
      major,
    );
    // Third Mainland Bridge across the lagoon.
    canvas.drawLine(
      Offset(w * 0.05, h * 0.2),
      Offset(w * 0.42, h * 0.62),
      major,
    );

    if (labels) {
      for (final (text, x, y) in const [
        ('YABA', 0.1, 0.12),
        ('IKOYI', 0.52, 0.32),
        ('VICTORIA ISLAND', 0.36, 0.66),
        ('LEKKI', 0.8, 0.8),
        ('LAGOS LAGOON', 0.58, 0.5),
      ]) {
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: Colors.white.withValues(alpha: 0.32),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(w * x - tp.width / 2, h * y));
      }
    }

    for (final z in heat) {
      final c = Offset(z.center.dx * w, z.center.dy * h);
      final r = z.radius * w;
      final color = Color.lerp(CaboColors.yellow, CaboColors.red, z.intensity)!;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: 0.55),
              color.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    if (serviceArea) {
      final area = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.08, h * 0.05, w * 0.7, h * 0.62),
            const Radius.circular(40),
          ),
        );
      canvas.drawPath(
        area,
        Paint()..color = CaboColors.brightGreen.withValues(alpha: 0.10),
      );
      canvas.drawPath(
        area,
        Paint()
          ..color = CaboColors.brightGreen
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    if (route.length > 1) {
      final path = Path()..moveTo(route.first.dx * w, route.first.dy * h);
      for (final p in route.skip(1)) {
        path.lineTo(p.dx * w, p.dy * h);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.5)
          ..strokeWidth = 10
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = routeColor
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.route != route || old.heat != heat || old.serviceArea != serviceArea;
}

/// Common routes used by the trip screens.
class Routes {
  static const toPickup = [
    Offset(0.3, 0.78),
    Offset(0.3, 0.6),
    Offset(0.52, 0.56),
    Offset(0.56, 0.36),
  ];
  static const trip = [
    Offset(0.56, 0.36),
    Offset(0.62, 0.52),
    Offset(0.78, 0.6),
    Offset(0.8, 0.82),
  ];
  static const airport = [
    Offset(0.2, 0.1),
    Offset(0.25, 0.3),
    Offset(0.42, 0.6),
    Offset(0.6, 0.62),
    Offset(0.62, 0.75),
  ];
}

/// Full-screen map with an optional overlay on top and a panel at the bottom.
class MapLayout extends StatelessWidget {
  const MapLayout({
    super.key,
    required this.map,
    required this.panel,
    this.top,
    this.bottomNav,
    this.panelColor = CaboColors.deepGreen,
  });

  final Widget map;
  final Widget panel;
  final Widget? top;
  final Widget? bottomNav;
  final Color panelColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: map),
                if (top != null)
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: top,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: panelColor,
              border: const Border(
                top: BorderSide(color: CaboColors.surfaceHigh, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              bottom: bottomNav == null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: panel,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: bottomNav,
    );
  }
}

/// Turn-by-turn instruction banner shown over the map.
class NavInstruction extends StatelessWidget {
  const NavInstruction({
    super.key,
    required this.distance,
    required this.street,
    this.then,
    this.icon = Icons.turn_right_rounded,
  });

  final String distance;
  final String street;
  final String? then;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CaboColors.green,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 16)],
      ),
      child: Row(
        children: [
          Icon(icon, size: 48, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(distance, style: CaboText.h1.copyWith(fontSize: 28)),
                Text(street, style: CaboText.h3),
                if (then != null)
                  Text(
                    'Then: $then',
                    style: CaboText.muted.copyWith(color: Colors.white70),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
