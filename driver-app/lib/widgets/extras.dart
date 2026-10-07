import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Bottom navigation: Home, Jobs, Earnings, Account.
class DriverNav extends StatelessWidget {
  const DriverNav(this.current, {super.key});
  final int current;

  static const tabs = [
    (Icons.home_rounded, 'Home', '/home'),
    (Icons.event_note_rounded, 'Jobs', '/jobs'),
    (Icons.account_balance_wallet_rounded, 'Earnings', '/earnings'),
    (Icons.person_rounded, 'Account', '/account'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CaboColors.surface,
        border: Border(top: BorderSide(color: CaboColors.surfaceHigh)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: i == current
                        ? null
                        : () =>
                              Navigator.of(context)
                                  .pushReplacementNamed(tabs[i].$3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: i == current
                                ? CaboColors.yellow.withValues(alpha: 0.18)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            tabs[i].$1,
                            color: i == current
                                ? CaboColors.yellow
                                : CaboColors.muted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tabs[i].$2,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: i == current
                                ? CaboColors.yellow
                                : CaboColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple bar chart with day labels; [highlight] marks one bar.
class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.values,
    required this.labels,
    this.highlight,
    this.height = 160,
    this.color = CaboColors.brightGreen,
    this.secondary,
    this.valueLabel,
  });

  final List<double> values;
  final List<String> labels;
  final int? highlight;
  final double height;
  final Color color;
  final List<double>? secondary;
  final String Function(double)? valueLabel;

  @override
  Widget build(BuildContext context) {
    final maxV = values.reduce(max);
    final maxS = secondary == null ? 1.0 : secondary!.reduce(max);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (valueLabel != null && i == highlight)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        valueLabel!(values[i]),
                        style: CaboText.label.copyWith(
                          color: CaboColors.yellow,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _bar(
                          values[i] / maxV,
                          i == highlight ? CaboColors.yellow : color,
                        ),
                        if (secondary != null) ...[
                          const SizedBox(width: 3),
                          _bar(
                            secondary![i] / maxS,
                            CaboColors.blue.withValues(alpha: 0.8),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    style: CaboText.label.copyWith(
                      color: i == highlight
                          ? CaboColors.yellow
                          : CaboColors.muted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bar(double fraction, Color c) => FractionallySizedBox(
    heightFactor: max(fraction, 0.04),
    child: Container(
      width: secondary == null ? 22 : 12,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(6),
      ),
    ),
  );
}

/// Circular progress ring with content in the middle.
class Ring extends StatelessWidget {
  const Ring({
    super.key,
    required this.value,
    required this.child,
    this.size = 120,
    this.color = CaboColors.yellow,
    this.stroke = 10,
  });

  final double value;
  final Widget child;
  final double size;
  final Color color;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(value, color, stroke),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color, this.stroke);
  final double value;
  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final base = Paint()
      ..color = CaboColors.surfaceHigh
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, 2 * pi, false, base);
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * value,
      false,
      base
        ..color = color
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color;
}

/// "Slide to complete" control used to end a trip.
class SlideToComplete extends StatefulWidget {
  const SlideToComplete({
    super.key,
    required this.label,
    required this.onComplete,
  });
  final String label;
  final VoidCallback onComplete;

  @override
  State<SlideToComplete> createState() => _SlideToCompleteState();
}

class _SlideToCompleteState extends State<SlideToComplete> {
  double dx = 0;

  @override
  Widget build(BuildContext context) {
    const knob = 60.0;
    return LayoutBuilder(
      builder: (context, c) {
        final maxDx = c.maxWidth - knob - 8;
        return Container(
          height: knob + 8,
          decoration: BoxDecoration(
            color: CaboColors.brightGreen.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: CaboColors.brightGreen, width: 1.5),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: Text(
                  widget.label,
                  style: CaboText.h3.copyWith(color: CaboColors.brightGreen),
                ),
              ),
              Positioned(
                left: 4 + dx,
                child: GestureDetector(
                  onHorizontalDragUpdate: (d) =>
                      setState(() => dx = (dx + d.delta.dx).clamp(0, maxDx)),
                  onHorizontalDragEnd: (_) {
                    if (dx > maxDx * 0.85) {
                      widget.onComplete();
                    }
                    setState(() => dx = 0);
                  },
                  child: Container(
                    width: knob,
                    height: knob,
                    decoration: const BoxDecoration(
                      color: CaboColors.brightGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.double_arrow_rounded,
                      color: CaboColors.onYellow,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Pulsing "searching" dot shown while online.
class Pulse extends StatefulWidget {
  const Pulse({super.key, this.animate = true, this.size = 120});
  final bool animate;
  final double size;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
    value: 0.55,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) c.repeat();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size * c.value,
              height: widget.size * c.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CaboColors.brightGreen.withValues(
                  alpha: 0.45 * (1 - c.value),
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: CaboColors.brightGreen,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Six-box code entry (OTP / PIN) display.
class CodeBoxes extends StatelessWidget {
  const CodeBoxes(this.code, {super.key, this.length = 6});
  final String code;
  final int length;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < length; i++)
          Container(
            width: length > 4 ? 48 : 62,
            height: length > 4 ? 58 : 70,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CaboColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: i == code.length
                    ? CaboColors.yellow
                    : i < code.length
                    ? CaboColors.outline
                    : CaboColors.surfaceHigh,
                width: i == code.length ? 2 : 1,
              ),
            ),
            child: Text(
              i < code.length ? code[i] : '',
              style: CaboText.h1.copyWith(fontSize: length > 4 ? 24 : 30),
            ),
          ),
      ],
    );
  }
}
