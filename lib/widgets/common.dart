import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'bean.dart';

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final double radius;
  final Color? border;

  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = C.pot,
    this.radius = 24,
    this.border,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: border == null ? null : Border.all(color: border!, width: 1.5),
    ),
    child: child,
  );
}

class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final double height;
  final double fontSize;
  final bool outlined;
  final IconData? icon;
  final int maxLines;

  const PillButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.color = C.lime,
    this.textColor = C.ink,
    this.height = 60,
    this.fontSize = 19,
    this.outlined = false,
    this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final fg = outlined ? color : textColor;
    return SizedBox(
      height: height,
      child: Material(
        color: outlined
            ? Colors.transparent
            : (onPressed == null ? C.line : color),
        shape: StadiumBorder(
          side: outlined
              ? BorderSide(color: color, width: 1.5)
              : BorderSide.none,
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onPressed!();
                },
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: fg, size: fontSize + 3),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: maxLines,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: T
                          .display(fontSize, color: fg)
                          .copyWith(letterSpacing: 0, height: 1.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Chip2 extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const Chip2(
    this.label, {
    super.key,
    required this.selected,
    required this.onTap,
    this.color = C.lime,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? color : C.line, width: 1.5),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: T.body(
              14,
              color: selected ? C.ink : C.text,
              weight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ),
  );
}

class Bar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;

  const Bar(this.value, {super.key, this.color = C.lime, this.height = 8});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height),
    child: TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0.0, 1.0)),
      duration: reduceMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, v, _) => LinearProgressIndicator(
        value: v,
        minHeight: height,
        backgroundColor: C.line,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    ),
  );
}

class RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final double stroke;

  RingPainter(this.value, this.color, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final r = (math.min(size.width, size.height) - stroke) / 2;
    final c = size.center(Offset.zero);
    final track = Paint()
      ..color = C.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(c, r, track);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * value.clamp(0.0, 1.0),
      false,
      p,
    );
  }

  @override
  bool shouldRepaint(RingPainter o) =>
      o.value != value || o.color != color || o.stroke != stroke;
}

class Ring extends StatelessWidget {
  final double value;
  final double size;
  final double stroke;
  final Color color;
  final Widget? child;

  const Ring({
    super.key,
    required this.value,
    this.size = 130,
    this.stroke = 12,
    this.color = C.lime,
    this.child,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0.0, 1.0)),
      duration: reduceMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 1100),
      curve: Curves.easeOut,
      builder: (context, v, _) => CustomPaint(
        painter: RingPainter(v, color, stroke),
        child: Center(child: child),
      ),
    ),
  );
}

/// Bean with a speech bubble.
class BeanSays extends StatelessWidget {
  final String text;
  final Mood mood;
  final double size;

  const BeanSays(
    this.text, {
    super.key,
    this.mood = Mood.happy,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Bean(mood: mood, size: size),
      const SizedBox(width: 10),
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: const BoxDecoration(
            color: C.pot,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
            ),
          ),
          child: Text(text, style: T.body(15)),
        ),
      ),
    ],
  );
}

class Label extends StatelessWidget {
  final String text;
  final Color color;
  const Label(this.text, {super.key, this.color = C.muted});

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: T.label(color: color));
}

/// Small round back button used on pushed screens.
class BackCircle extends StatelessWidget {
  const BackCircle({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Back',
    child: GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(color: C.pot, shape: BoxShape.circle),
        child: const Icon(Icons.chevron_left_rounded, size: 28),
      ),
    ),
  );
}

String fmtNum(num v, {int dec = 0}) {
  final s = v.toStringAsFixed(dec);
  final parts = s.split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );
  return parts.length > 1 ? '$whole.${parts[1]}' : whole;
}

String clock12(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  final hh = h % 12 == 0 ? 12 : h % 12;
  return '$hh:${m.toString().padLeft(2, '0')} ${h < 12 ? 'AM' : 'PM'}';
}

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
String dowName(int weekday) => _days[weekday - 1];
String niceDate(DateTime d) =>
    '${_days[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';
String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';
