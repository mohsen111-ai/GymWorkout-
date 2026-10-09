import 'package:flutter/material.dart';

import '../logic/planner.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'guide.dart';
import 'session.dart';

/// Shows a day's workout with every move, then starts it.
class WorkoutPreviewScreen extends StatelessWidget {
  final DateTime date;
  const WorkoutPreviewScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final w = s.workoutOn(date);
    if (w == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BackCircle(),
                const SizedBox(height: 20),
                Text('Rest day', style: T.display(30)),
              ],
            ),
          ),
        ),
      );
    }
    final done = s.workoutDone(date);
    final isFuture = date.isAfter(s.today);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  Row(
                    children: [
                      const BackCircle(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(w.title, style: T.display(26)),
                            Text(
                              niceDate(date),
                              style: T.body(13, color: C.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Panel(
                    radius: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _pill(Icons.timer_outlined, '${w.minutes} min'),
                            _pill(
                              Icons.fitness_center_rounded,
                              '${w.exercises.length} moves',
                            ),
                            _pill(Icons.block_rounded, 'No jumping'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          w.deload
                              ? 'Deload week: lighter sets and easier targets so you recover.'
                              : w.easedBack
                              ? 'Welcome back! Bean trimmed this session to ease you in.'
                              : 'Week ${w.clock.weekNumber} of 4 · ${emphasisName(w.clock.emphasis)} block. ${emphasisBlurb(w.clock.emphasis)}',
                          style: T.body(13, color: C.soft),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Label('Warm-up'),
                  const SizedBox(height: 8),
                  Panel(
                    radius: 18,
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      '3 to 4 minutes: march on the spot, arm circles, hip circles and 10 slow bodyweight squats. No jumping.',
                      style: T.body(14, color: C.soft),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Label('Your moves'),
                  const SizedBox(height: 8),
                  for (var i = 0; i < w.exercises.length; i++)
                    _exercise(context, w.exercises[i], i),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: PillButton(
                done
                    ? 'Do it again'
                    : (isFuture ? 'Preview only' : 'Start workout'),
                onPressed: isFuture
                    ? null
                    : () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SessionScreen(workout: w),
                        ),
                      ),
                icon: Icons.play_arrow_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(IconData i, String t) => Row(
    children: [
      Icon(i, size: 18, color: C.lime),
      const SizedBox(width: 6),
      Text(t, style: T.body(13, weight: FontWeight.w700)),
    ],
  );

  Widget _exercise(BuildContext context, PlannedExercise e, int i) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: C.pot,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                GuideScreen(ladderId: e.ladder.id, levelIdx: e.levelIdx),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: C.pot2,
                child: Text(
                  '${i + 1}',
                  style: T.body(14, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name, style: T.body(16, weight: FontWeight.w700)),
                    Text(
                      '${e.prescription} · rest ${e.restSec} s',
                      style: T.body(13, color: C.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_outline_rounded, color: C.lime),
            ],
          ),
        ),
      ),
    ),
  );
}
