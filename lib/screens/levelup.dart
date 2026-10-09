import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/progression.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/bean.dart';
import '../widgets/common.dart';

class LevelUpScreen extends StatefulWidget {
  final LevelOffer offer;
  const LevelUpScreen({super.key, required this.offer});

  @override
  State<LevelUpScreen> createState() => _LevelUpScreenState();
}

class _LevelUpScreenState extends State<LevelUpScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
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

  @override
  Widget build(BuildContext context) {
    final o = widget.offer;
    final ladder = o.ladder;
    final s = AppScope.of(context);
    const colors = [C.coral, C.butter, C.sky, C.lime, C.coral, C.butter];
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // confetti
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) =>
                      CustomPaint(painter: _Confetti(_c.value, colors)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const Bean(mood: Mood.cheer, size: 130),
                  const SizedBox(height: 10),
                  Text('Level up!', style: T.display(42, color: C.lime)),
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'You hit '),
                        TextSpan(
                          text:
                              '${o.reps} ${o.from.isTime ? 'seconds' : 'reps'} on every set',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: C.text,
                          ),
                        ),
                        TextSpan(text: ' of ${o.from.name.toLowerCase()}.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: T.body(16, color: C.soft),
                  ),
                  const SizedBox(height: 22),
                  Panel(
                    radius: 28,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Label('Time for a harder version'),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _box(
                                'Before',
                                o.from.name,
                                '${o.from.min} to ${o.from.max}',
                                false,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: C.lime,
                                size: 28,
                              ),
                            ),
                            Expanded(
                              child: _box(
                                'Now',
                                o.to.name,
                                'start at ${o.to.min}',
                                true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Fewer reps on a harder move is normal. Build back up over the next few weeks.',
                          style: T.body(13, color: C.soft),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Panel(
                    radius: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Label('Your ${ladder.name.toLowerCase()} journey'),
                        const SizedBox(height: 12),
                        _journey(ladder.levels.length, o.toLevel),
                      ],
                    ),
                  ),
                  const Spacer(),
                  PillButton(
                    'Accept the challenge',
                    onPressed: () async {
                      await s.acceptOffer(o);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Keep the current version for now',
                      style: T.body(
                        15,
                        color: C.muted,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _box(String tag, String name, String sub, bool hot) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: hot ? C.lime : C.ink,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      children: [
        Text(
          tag,
          style: T.body(12, color: hot ? C.ink.withAlpha(190) : C.muted),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          textAlign: TextAlign.center,
          style: T.body(
            15,
            color: hot ? C.ink : C.text,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: T.body(12, color: hot ? C.ink.withAlpha(200) : C.muted),
        ),
      ],
    ),
  );

  Widget _journey(int n, int current) => Row(
    children: [
      for (var i = 0; i < n; i++) ...[
        Container(
          width: i == current ? 18 : 12,
          height: i == current ? 18 : 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i <= current ? C.lime : C.line,
            border: i == current ? Border.all(color: C.ink, width: 3) : null,
            boxShadow: i == current
                ? [const BoxShadow(color: C.lime, spreadRadius: 2)]
                : null,
          ),
        ),
        if (i < n - 1)
          Expanded(
            child: Container(height: 3, color: i < current ? C.lime : C.line),
          ),
      ],
    ],
  );
}

class _Confetti extends CustomPainter {
  final double t;
  final List<Color> colors;
  _Confetti(this.t, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 18; i++) {
      final phase = (t + i * 0.137) % 1.0;
      final x = ((i * 53) % 100) / 100 * size.width;
      final y = phase * size.height * 0.8;
      final p = Paint()
        ..color = colors[i % colors.length].withAlpha(
          (255 * (1 - phase)).round(),
        );
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(phase * math.pi * 3 + i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, -7, 8, 14),
          const Radius.circular(2),
        ),
        p,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Confetti o) => o.t != t;
}
