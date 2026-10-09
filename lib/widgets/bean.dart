import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/ladders.dart';
import '../theme.dart';

enum Mood { happy, focused, cheer, sleepy, oops }

/// Draws Bean, the mascot, in a 136 x 146 box (matches the approved design).
class BeanPainter extends CustomPainter {
  final Mood mood;
  final double blink; // 1 = eyes open, 0.1 = shut

  BeanPainter(this.mood, {this.blink = 1});

  static const _ink = C.ink;

  Paint _fill(Color c) => Paint()..color = c;
  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _ellipse(
    Canvas c,
    double cx,
    double cy,
    double rx,
    double ry, {
    double rot = 0,
    Color fill = C.lime,
    bool outline = true,
    double sw = 4,
  }) {
    c.save();
    c.translate(cx, cy);
    c.rotate(rot * math.pi / 180);
    final r = Rect.fromCenter(
      center: Offset.zero,
      width: rx * 2,
      height: ry * 2,
    );
    c.drawOval(r, _fill(fill));
    if (outline) c.drawOval(r, _stroke(_ink, sw));
    c.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 136);
    canvas.translate(8, 0);

    // shadow
    _ellipse(
      canvas,
      60,
      142,
      40,
      5,
      fill: const Color(0x59000000),
      outline: false,
    );

    // arms
    final cheer = mood == Mood.cheer;
    final rest = mood == Mood.sleepy || mood == Mood.oops;
    if (cheer) {
      _ellipse(canvas, 6, 76, 8, 13, rot: -35);
      _ellipse(canvas, 114, 76, 8, 13, rot: 35);
    } else {
      final y = rest ? 98.0 : 94.0;
      final r = rest ? 5.0 : 12.0;
      _ellipse(canvas, 8, y, 8, 13, rot: r);
      _ellipse(canvas, 112, y, 8, 13, rot: -r);
    }

    // feet
    _ellipse(canvas, 42, 134, 13, 8, fill: C.limeDark);
    _ellipse(canvas, 78, 134, 13, 8, fill: C.limeDark);

    // body
    final body = Path()
      ..moveTo(60, 8)
      ..cubicTo(92, 8, 108, 36, 108, 72)
      ..cubicTo(108, 112, 88, 132, 60, 132)
      ..cubicTo(32, 132, 12, 112, 12, 72)
      ..cubicTo(12, 36, 28, 8, 60, 8)
      ..close();
    canvas.drawPath(body, _fill(C.lime));
    canvas.drawPath(body, _stroke(_ink, 4));

    // highlight
    final hi = Path()
      ..moveTo(30, 28)
      ..cubicTo(36, 20, 44, 15, 52, 13);
    canvas.drawPath(hi, _stroke(Colors.white.withAlpha(140), 5));

    // headband
    final band = Path()
      ..moveTo(14, 52)
      ..cubicTo(42, 40, 78, 40, 106, 52)
      ..lineTo(105, 64)
      ..cubicTo(78, 52, 42, 52, 15, 64)
      ..close();
    canvas.drawPath(band, _fill(C.coral));
    canvas.drawPath(band, _stroke(_ink, 3.5));

    _face(canvas);
    canvas.restore();
  }

  void _cheeks(Canvas c) {
    final col = C.coral.withAlpha(153);
    _ellipse(c, 31, 96, 6, 4, fill: col, outline: false);
    _ellipse(c, 89, 96, 6, 4, fill: col, outline: false);
  }

  void _eyes(
    Canvas c,
    double ry,
    double cy, {
    double rx = 6.5,
    bool shine = true,
  }) {
    for (final x in [44.0, 76.0]) {
      c.save();
      c.translate(x, cy);
      c.scale(1, blink);
      c.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
        _fill(_ink),
      );
      c.restore();
      if (shine && blink > 0.5) {
        c.drawCircle(Offset(x + 2.5, cy - 4), 2.4, _fill(Colors.white));
      }
    }
  }

  void _face(Canvas c) {
    switch (mood) {
      case Mood.happy:
        _eyes(c, 9, 80);
        _cheeks(c);
        final m = Path()
          ..moveTo(50, 98)
          ..quadraticBezierTo(60, 109, 70, 98);
        c.drawPath(m, _stroke(_ink, 4));
      case Mood.focused:
        _eyes(c, 7, 82, rx: 6);
        final b = Path()
          ..moveTo(34, 70)
          ..lineTo(54, 74)
          ..moveTo(86, 70)
          ..lineTo(66, 74)
          ..moveTo(52, 100)
          ..lineTo(68, 100);
        c.drawPath(b, _stroke(_ink, 4));
      case Mood.cheer:
        final e = Path()
          ..moveTo(37, 84)
          ..quadraticBezierTo(44, 72, 51, 84)
          ..moveTo(69, 84)
          ..quadraticBezierTo(76, 72, 83, 84);
        c.drawPath(e, _stroke(_ink, 4));
        _cheeks(c);
        final mouth = Path()
          ..moveTo(47, 94)
          ..quadraticBezierTo(60, 120, 73, 94)
          ..close();
        c.drawPath(mouth, _fill(_ink));
        c.drawPath(mouth, _stroke(_ink, 3));
        final tongue = Path()
          ..moveTo(53, 105)
          ..quadraticBezierTo(60, 100, 67, 105)
          ..quadraticBezierTo(60, 112, 53, 105)
          ..close();
        c.drawPath(tongue, _fill(C.coral));
      case Mood.sleepy:
        final e = Path()
          ..moveTo(37, 82)
          ..lineTo(51, 82)
          ..moveTo(69, 82)
          ..lineTo(83, 82);
        c.drawPath(e, _stroke(_ink, 4));
        _ellipse(c, 60, 100, 5, 4, fill: _ink, outline: false);
        final z = Path()
          ..moveTo(98, 16)
          ..relativeLineTo(10, 0)
          ..relativeLineTo(-10, 10)
          ..relativeLineTo(10, 0);
        c.drawPath(z, _stroke(C.sky, 3.5));
      case Mood.oops:
        _eyes(c, 7.5, 82, rx: 5.5);
        final m = Path()
          ..moveTo(48, 102)
          ..quadraticBezierTo(54, 95, 60, 102)
          ..quadraticBezierTo(66, 109, 72, 102);
        c.drawPath(m, _stroke(_ink, 4));
        final drop = Path()
          ..moveTo(100, 44)
          ..cubicTo(100, 44, 106, 52, 106, 56)
          ..arcToPoint(const Offset(94, 56), radius: const Radius.circular(6))
          ..cubicTo(94, 52, 100, 44, 100, 44)
          ..close();
        c.drawPath(drop, _fill(C.sky));
        c.drawPath(drop, _stroke(_ink, 2.5));
    }
  }

  @override
  bool shouldRepaint(BeanPainter old) => old.mood != mood || old.blink != blink;
}

bool reduceMotion(BuildContext c) =>
    MediaQuery.maybeOf(c)?.disableAnimations ?? false;

/// Bean with a gentle idle float and blink.
class Bean extends StatefulWidget {
  final Mood mood;
  final double size;
  final bool idle;

  const Bean({
    super.key,
    this.mood = Mood.happy,
    this.size = 100,
    this.idle = true,
  });

  @override
  State<Bean> createState() => _BeanState();
}

class _BeanState extends State<Bean> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4500),
  );

  @override
  void initState() {
    super.initState();
    if (widget.idle) _c.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
    } else if (widget.idle && !_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.size * 146 / 136;
    return Semantics(
      label: 'Bean the mascot',
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final blink = (t > 0.91 && t < 0.97)
              ? (t < 0.94
                    ? 1 - (t - 0.91) / 0.03 * 0.9
                    : 0.1 + (t - 0.94) / 0.03 * 0.9)
              : 1.0;
          final bob = widget.idle ? math.sin(t * 2 * math.pi * 1.32) * 3 : 0.0;
          return Transform.translate(
            offset: Offset(0, bob),
            child: SizedBox(
              width: widget.size,
              height: h,
              child: CustomPaint(
                painter: BeanPainter(widget.mood, blink: blink),
              ),
            ),
          );
        },
      ),
    );
  }
}

double _ease(double t) => t < 0.5 ? 2 * t * t : 1 - math.pow(-2 * t + 2, 2) / 2;

/// Bean demonstrating a move, looping with the 3 s down / 1 s up rhythm.
class BeanDemo extends StatefulWidget {
  final Motion motion;
  final double size;
  final Mood mood;

  const BeanDemo({
    super.key,
    required this.motion,
    this.size = 110,
    this.mood = Mood.focused,
  });

  @override
  State<BeanDemo> createState() => _BeanDemoState();
}

class _BeanDemoState extends State<BeanDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// 0 = start position, 1 = deepest point (3 s down, 1 s hold + rise).
  double _depth(double t) {
    if (t < 0.75) return _ease(t / 0.75);
    if (t < 0.85) return 1;
    return 1 - _ease((t - 0.85) / 0.15);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final d = _depth(_c.value);
        final k = s / 110;
        double dx = 0, dy = 0, sx = 1, sy = 1, rot = 0;
        switch (widget.motion) {
          case Motion.squat:
            dy = 14 * d * k;
            sy = 1 - 0.22 * d;
            sx = 1 + 0.1 * d;
          case Motion.lunge:
            dy = 12 * d * k;
            dx = 10 * d * k;
            sy = 1 - 0.18 * d;
            sx = 1 + 0.08 * d;
          case Motion.pushup:
            rot = (78 + 8 * d) * math.pi / 180;
            dx = 8 * d * k;
          case Motion.bridge:
            rot = 90 * math.pi / 180;
            dx = -14 * d * k;
          case Motion.plank:
            rot = 90 * math.pi / 180;
            sy = 1 + 0.02 * math.sin(_c.value * 2 * math.pi * 2);
          case Motion.row:
            rot = 78 * math.pi / 180;
            dx = -14 * d * k;
          case Motion.deadbug:
            rot = (90 + 8 * math.sin(_c.value * 2 * math.pi)) * math.pi / 180;
          case Motion.hold:
            sx = 1 + 0.03 * math.sin(_c.value * 2 * math.pi * 2);
            sy = sx;
          case Motion.calf:
            dy = -12 * d * k;
          case Motion.back:
            rot = 90 * math.pi / 180;
            dx = -10 * d * k;
        }
        // Rotating about the feet swings Bean sideways; pull him back to centre.
        dx -= s * 146 / 136 / 2 * math.sin(rot);
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..rotateZ(rot)
              ..scaleByDouble(sx, sy, 1.0, 1.0),
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: s,
        height: s * 146 / 136,
        child: CustomPaint(painter: BeanPainter(widget.mood)),
      ),
    );
  }
}
