import 'dart:math';

import 'package:flutter/material.dart';

import '../logic/nutrition.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/bean.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';
import 'goals.dart';

class Verdict {
  final String status;
  final String text;
  final Mood mood;
  final Color color;
  const Verdict(this.status, this.text, this.mood, this.color);
}

Verdict verdictFor(WeekStats w, Targets t, {required bool finished}) {
  final parts = <String>[];
  final missed = w.workoutsPlanned - w.workoutsDone;
  var good = 0;
  var bad = 0;

  if (w.workoutsDone >= w.workoutsPlanned) {
    parts.add('All ${w.workoutsPlanned} workouts done.');
    good++;
  } else if (finished) {
    parts.add(
      '$missed workout${missed == 1 ? '' : 's'} missed. Even a short one counts.',
    );
    bad++;
  } else {
    parts.add(
      '${w.workoutsDone} of ${w.workoutsPlanned} workouts done so far.',
    );
  }

  if (w.daysLogged >= 3) {
    if (w.proteinDays >= 5) {
      parts.add('Protein was on point.');
      good++;
    } else {
      parts.add(
        'Protein hit your target ${w.proteinDays} of ${w.daysLogged} days. Add a snack.',
      );
      bad++;
    }
  } else {
    parts.add('Log your meals on more days so Bean can give you real numbers.');
  }

  final c = w.change;
  if (c != null) {
    if (c <= -1.2) {
      parts.add(
        'You lost ${c.abs().toStringAsFixed(1)} kg, which is fast. Make sure you are eating enough protein.',
      );
    } else if (c <= -0.2) {
      parts.add('Down ${c.abs().toStringAsFixed(1)} kg: right on track.');
      good++;
    } else if (c < 0.3) {
      parts.add('Weight is steady. That is normal. Stick with it.');
    } else {
      parts.add(
        'Up ${c.toStringAsFixed(1)} kg. Water and salt swings are common; trust the weekly average.',
      );
      bad++;
    }
  }

  if (good >= 2 && bad == 0) {
    return Verdict('On track', parts.join(' '), Mood.cheer, C.lime);
  }
  if (bad >= 2) {
    return Verdict('Reset', parts.join(' '), Mood.happy, C.coral);
  }
  return Verdict('Building', parts.join(' '), Mood.happy, C.butter);
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _thisWeek = true;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = s.targets;
    final start = _thisWeek
        ? weekStartOf(s.today)
        : weekStartOf(s.today).subtract(const Duration(days: 7));
    final w = s.weekStats(start);
    final v = verdictFor(w, t, finished: !_thisWeek);
    final end = start.add(const Duration(days: 6));
    final change = w.change;
    final next = s.nextWeekEstimate;
    final date = s.goalDateEstimate;
    final p = s.profile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _thisWeek ? 'This week' : 'Last week recap',
                    style: T.display(28),
                  ),
                  Text(
                    '${shortDate(start)} to ${shortDate(end)}',
                    style: T.body(14, color: C.muted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: C.pot,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                v.status,
                style: T.body(14, color: v.color, weight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Chip2(
              'Last week',
              selected: !_thisWeek,
              onTap: () => setState(() => _thisWeek = false),
            ),
            const SizedBox(width: 8),
            Chip2(
              'This week',
              selected: _thisWeek,
              onTap: () => setState(() => _thisWeek = true),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Panel(
          radius: 28,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Average weight',
                          style: T.body(13, color: C.muted),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: w.avgWeight == null
                                    ? '--'
                                    : w.avgWeight!.toStringAsFixed(1),
                                style: T.display(40),
                              ),
                              TextSpan(
                                text: ' kg',
                                style: T.body(
                                  18,
                                  color: C.muted,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (change != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            change <= 0
                                ? Icons.south_rounded
                                : Icons.north_rounded,
                            size: 18,
                            color: change <= 0 ? C.lime : C.coral,
                          ),
                          Text(
                            '${change.abs().toStringAsFixed(1)} kg',
                            style: T.body(
                              18,
                              color: change <= 0 ? C.lime : C.coral,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(height: 140, child: _WeightChart(state: s)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _stat(
                'Workouts',
                '${w.workoutsDone}',
                ' / ${w.workoutsPlanned}',
                C.text,
                w.workoutsDone / max(1, w.workoutsPlanned),
                C.lime,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _stat(
                'Avg calories',
                w.avgKcal == null ? '--' : fmtNum(w.avgKcal!.round()),
                '',
                C.text,
                null,
                C.lime,
                foot: 'target ${fmtNum(t.kcal)}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _stat(
                'Protein days',
                w.daysLogged == 0 ? '--' : '${w.proteinDays}',
                w.daysLogged == 0 ? '' : ' / ${w.daysLogged}',
                C.coral,
                w.daysLogged == 0 ? 0 : w.proteinDays / w.daysLogged,
                C.coral,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Panel(
          radius: 24,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Label('Forecast'),
              const SizedBox(height: 10),
              _row(
                'Next week, estimated',
                next == null ? '--' : '${next.toStringAsFixed(1)} kg',
                C.text,
              ),
              const SizedBox(height: 6),
              _row(
                '${p.goalWeight.toStringAsFixed(0)} kg goal, at this pace',
                s.currentWeight <= p.goalWeight
                    ? 'Reached!'
                    : (date == null ? '--' : monthWord(date)),
                C.butter,
              ),
              const SizedBox(height: 8),
              Text(
                'Based on your goal pace of ${p.paceKg} kg a week and your logged weights. Real life wiggles, so trust the weekly average.',
                style: T.body(12, color: C.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: v.color,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Bean(mood: v.mood, size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  v.text,
                  style: T.body(14, color: C.ink, weight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: PillButton(
                'Log weight',
                height: 48,
                fontSize: 14,
                outlined: true,
                color: C.text,
                onPressed: () async {
                  final x = await askNumber(
                    context,
                    title: 'Your weight today',
                    unit: 'kg',
                    initial: s.currentWeight,
                    min: 30,
                    max: 300,
                  );
                  if (x != null) await s.setWeight(s.today, x);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PillButton(
                'Log waist',
                height: 48,
                fontSize: 14,
                outlined: true,
                color: C.text,
                onPressed: () async {
                  final last = s.data.waists.isEmpty
                      ? null
                      : s.data.waists[(s.data.waists.keys.toList()..sort())
                            .last];
                  final x = await askNumber(
                    context,
                    title: 'Waist at the belly button',
                    unit: 'cm',
                    initial: last,
                    min: 40,
                    max: 250,
                  );
                  if (x != null) await s.setWaist(s.today, x);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        PillButton(
          'My goals',
          height: 48,
          fontSize: 14,
          outlined: true,
          color: C.lime,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GoalsScreen()),
          ),
        ),
        const SizedBox(height: 18),
        _history(context, s),
      ],
    );
  }

  Widget _history(BuildContext context, AppState s) {
    final keys = s.data.weights.keys.toList()..sort((a, b) => b.compareTo(a));
    if (keys.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Label('Recent weigh-ins'),
        const SizedBox(height: 8),
        for (final k in keys.take(7))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Panel(
              radius: 16,
              padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      niceDate(parseDay(k)),
                      style: T.body(14, color: C.soft),
                    ),
                  ),
                  Text(
                    '${s.data.weights[k]!.toStringAsFixed(1)} kg',
                    style: T.body(15, weight: FontWeight.w700),
                  ),
                  IconButton(
                    tooltip: 'Delete weigh-in',
                    onPressed: () async {
                      if (s.data.weights.length <= 1) {
                        toast(context, 'Keep at least one weigh-in');
                        return;
                      }
                      if (await confirm(
                        context,
                        title: 'Delete this weigh-in?',
                        message:
                            '${niceDate(parseDay(k))} · ${s.data.weights[k]!.toStringAsFixed(1)} kg',
                        yes: 'Delete',
                        danger: true,
                      )) {
                        await s.removeWeight(parseDay(k));
                      }
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: C.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _row(String l, String r, Color c) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(child: Text(l, style: T.body(15))),
      Text(r, style: T.display(21, color: c)),
    ],
  );

  Widget _stat(
    String label,
    String big,
    String small,
    Color c,
    double? bar,
    Color barColor, {
    String? foot,
  }) => Panel(
    radius: 22,
    padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: T.body(
            12,
            color: label == 'Protein days' ? C.coral : C.muted,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: big,
                style: T.display(26, color: c),
              ),
              TextSpan(
                text: small,
                style: T.body(14, color: C.muted, weight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (bar != null)
          Bar(bar, color: barColor, height: 6)
        else
          Text(foot ?? '', style: T.body(12, color: C.muted)),
      ],
    ),
  );
}

class _WeightChart extends StatelessWidget {
  final AppState state;
  const _WeightChart({required this.state});

  @override
  Widget build(BuildContext context) {
    final keys = state.data.weights.keys.toList()..sort();
    final pts = <(DateTime, double)>[
      for (final k in keys.length > 60 ? keys.sublist(keys.length - 60) : keys)
        (parseDay(k), state.data.weights[k]!),
    ];
    if (pts.length < 2) {
      return Center(
        child: Text(
          'Log your weight on a few days to see your trend.',
          textAlign: TextAlign.center,
          style: T.body(14, color: C.muted),
        ),
      );
    }
    return CustomPaint(
      size: Size.infinite,
      painter: _ChartPainter(
        pts,
        state.profile.goalWeight,
        state.profile.paceKg,
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<(DateTime, double)> pts;
  final double goal;
  final double pace;
  _ChartPainter(this.pts, this.goal, this.pace);

  @override
  void paint(Canvas canvas, Size size) {
    const left = 4.0, right = 36.0, top = 8.0, bottom = 18.0;
    final w = size.width - left - right;
    final h = size.height - top - bottom;
    final t0 = pts.first.$1.millisecondsSinceEpoch.toDouble();
    final t1 = pts.last.$1
        .add(const Duration(days: 7))
        .millisecondsSinceEpoch
        .toDouble();
    var lo = pts.map((e) => e.$2).reduce(min) - 0.6;
    var hi = pts.map((e) => e.$2).reduce(max) + 0.6;
    final proj = pts.last.$2 - pace;
    lo = min(lo, proj - 0.3);
    final range = max(0.5, hi - lo);
    double x(DateTime d) =>
        left + (d.millisecondsSinceEpoch - t0) / (t1 - t0) * w;
    double y(double v) => top + (1 - (v - lo) / range) * h;

    final grid = Paint()
      ..color = C.line
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final gy = top + h * i / 2;
      canvas.drawLine(Offset(left, gy), Offset(left + w, gy), grid);
      final val = hi - range * i / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: val.toStringAsFixed(1),
          style: T.body(10, color: C.muted),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(left + w + 6, gy - tp.height / 2));
    }

    final line = Path();
    for (var i = 0; i < pts.length; i++) {
      final o = Offset(x(pts[i].$1), y(pts[i].$2));
      i == 0 ? line.moveTo(o.dx, o.dy) : line.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = C.lime
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // projection
    final last = pts.last;
    final from = Offset(x(last.$1), y(last.$2));
    final to = Offset(x(last.$1.add(const Duration(days: 7))), y(proj));
    final dash = Paint()
      ..color = C.muted
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const steps = 8;
    for (var i = 0; i < steps; i += 2) {
      canvas.drawLine(
        Offset.lerp(from, to, i / steps)!,
        Offset.lerp(from, to, (i + 1) / steps)!,
        dash,
      );
    }
    canvas.drawCircle(to, 5, Paint()..color = C.ink);
    canvas.drawCircle(
      to,
      5,
      Paint()
        ..color = C.muted
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    for (var i = 0; i < pts.length; i++) {
      final o = Offset(x(pts[i].$1), y(pts[i].$2));
      final isLast = i == pts.length - 1;
      canvas.drawCircle(
        o,
        isLast ? 6 : 3.5,
        Paint()..color = isLast ? C.lime : C.ink,
      );
      if (!isLast && pts.length <= 14) {
        canvas.drawCircle(
          o,
          3.5,
          Paint()
            ..color = C.lime
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ChartPainter o) =>
      o.pts != pts || o.goal != goal || o.pace != pace;
}
