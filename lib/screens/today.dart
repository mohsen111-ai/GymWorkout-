import 'package:flutter/material.dart';

import '../logic/planner.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/bean.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';
import 'goals.dart';
import 'preview.dart';
import 'shell.dart';

(String, Mood) beanLine(AppState s) {
  final now = DateTime.now();
  final t = s.targets;
  final w = s.workoutOn(s.today);
  final done = s.workoutDone(s.today);
  final protein = s.proteinOn(s.today);
  final left = (t.protein - protein).round();
  if (s.weightOn(s.today) == null && now.hour < 12) {
    return (
      'Morning! Step on the scale and log your weight before breakfast.',
      Mood.happy,
    );
  }
  if (w != null && !done) {
    return (
      '${w.title} today: ${w.minutes} minutes, no jumping.${w.deload ? ' It is a lighter deload week, so take it easy.' : " You've got this."}',
      Mood.focused,
    );
  }
  if (left > 20 && now.hour >= 16) {
    return (
      'Protein is the one to watch: $left g to go. A yogurt or tuna would help.',
      Mood.happy,
    );
  }
  if (done) {
    return (
      'Workout done! Great job. Keep the protein up and rest well.',
      Mood.cheer,
    );
  }
  if (w == null) {
    return (
      'Rest day. Aim for ${fmtNum(t.steps)} steps and a gentle stretch.',
      Mood.sleepy,
    );
  }
  return ('Nice and steady. Log your meals and Bean keeps count.', Mood.happy);
}

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final today = s.today;
    final t = s.targets;
    final kcal = s.kcalOn(today);
    final protein = s.proteinOn(today);
    final carbs = s.carbsOn(today);
    final fat = s.fatOn(today);
    final water = s.waterOn(today);
    final glass = 250;
    final w = s.workoutOn(today);
    final done = s.workoutDone(today);
    final (line, mood) = beanLine(s);
    final left = t.kcal - kcal.round();
    final weightNow = s.currentWeight;
    final weekAvg = s.averageWeight(weekStartOf(today));
    final weekStartW = s.averageWeight(
      weekStartOf(today).subtract(const Duration(days: 7)),
    );
    final delta = (weekAvg != null && weekStartW != null)
        ? weekAvg - weekStartW
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(niceDate(today), style: T.body(14, color: C.muted)),
                  const SizedBox(height: 2),
                  Text(_greeting(), style: T.display(28)),
                ],
              ),
            ),
            if (s.streak > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: C.pot,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: C.butter,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${s.streak} ${s.streak == 1 ? 'day' : 'days'}',
                      style: T.body(
                        15,
                        color: C.butter,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'My goals',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GoalsScreen()),
              ),
              icon: const Icon(Icons.tune_rounded, color: C.muted),
            ),
          ],
        ),
        const SizedBox(height: 14),
        BeanSays(line, mood: mood),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => tabIndex.value = 2,
          child: Panel(
            radius: 28,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Ring(
                  value: t.kcal == 0 ? 0 : kcal / t.kcal,
                  size: 132,
                  color: kcal > t.kcal + 100 ? C.butter : C.lime,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(fmtNum(left.abs()), style: T.display(30)),
                      Text(
                        left >= 0 ? 'kcal left' : 'kcal over',
                        style: T.body(12, color: C.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    children: [
                      _macro('Protein', protein, t.protein.toDouble(), C.coral),
                      const SizedBox(height: 12),
                      _macro('Carbs', carbs, t.carbs.toDouble(), C.butter),
                      const SizedBox(height: 12),
                      _macro('Fat', fat, t.fat.toDouble(), C.sky),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Panel(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Water',
                      style: T.body(
                        13,
                        color: C.muted,
                        weight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: (water / 1000).toStringAsFixed(1),
                            style: T.display(26),
                          ),
                          TextSpan(
                            text: ' / ${t.waterL.toStringAsFixed(1)} L',
                            style: T.body(
                              15,
                              color: C.muted,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Bar(water / (t.waterL * 1000), color: C.sky),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: PillButton(
                            '+ Glass',
                            height: 42,
                            fontSize: 14,
                            outlined: true,
                            color: C.sky,
                            onPressed: () => s.addWater(today, glass),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 42,
                          child: IconButton(
                            tooltip: 'Remove a glass',
                            onPressed: water == 0
                                ? null
                                : () => s.addWater(today, -glass),
                            icon: const Icon(
                              Icons.remove_rounded,
                              color: C.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Panel(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.weightOn(today) == null
                          ? 'Latest weight'
                          : 'Weight today',
                      style: T.body(
                        13,
                        color: C.muted,
                        weight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: weightNow.toStringAsFixed(1),
                            style: T.display(26),
                          ),
                          TextSpan(
                            text: ' kg',
                            style: T.body(
                              15,
                              color: C.muted,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 18,
                      child: delta == null
                          ? Text(
                              'Weigh in daily',
                              style: T.body(13, color: C.muted),
                            )
                          : Row(
                              children: [
                                Icon(
                                  delta <= 0
                                      ? Icons.south_rounded
                                      : Icons.north_rounded,
                                  size: 14,
                                  color: delta <= 0 ? C.lime : C.coral,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${delta.abs().toStringAsFixed(1)} kg vs last week',
                                  style: T.body(
                                    13,
                                    color: delta <= 0 ? C.lime : C.coral,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 12),
                    PillButton(
                      'Log weight',
                      height: 42,
                      fontSize: 14,
                      outlined: true,
                      color: C.text,
                      onPressed: () async {
                        final v = await askNumber(
                          context,
                          title: 'Your weight today',
                          unit: 'kg',
                          initial: weightNow,
                          min: 30,
                          max: 300,
                        );
                        if (v != null) await s.setWeight(today, v);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _workoutCard(context, s, w, done),
        const SizedBox(height: 12),
        Panel(
          padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
          child: Row(
            children: [
              const Icon(Icons.directions_walk_rounded, color: C.butter),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Steps', style: T.body(13, color: C.muted)),
                    Text(
                      '${fmtNum(s.stepsOn(today))} / ${fmtNum(t.steps)}',
                      style: T.display(20),
                    ),
                    const SizedBox(height: 6),
                    Bar(s.stepsOn(today) / t.steps, color: C.butter, height: 6),
                  ],
                ),
              ),
              TextButton(
                onPressed: () async {
                  final v = await askNumber(
                    context,
                    title: 'Steps today',
                    unit: 'steps',
                    initial: s.stepsOn(today).toDouble(),
                    max: 100000,
                    decimals: 0,
                  );
                  if (v != null) await s.setSteps(today, v.round());
                },
                child: const Text(
                  'Update',
                  style: TextStyle(color: C.lime, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning, champ';
    if (h < 18) return 'Good afternoon, champ';
    return 'Good evening, champ';
  }

  Widget _macro(String name, double v, double target, Color c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: T.body(13, color: c, weight: FontWeight.w700),
          ),
          Text(
            '${v.round()} / ${target.round()} g',
            style: T.body(13, color: C.muted),
          ),
        ],
      ),
      const SizedBox(height: 5),
      Bar(v / target, color: c),
    ],
  );

  Widget _workoutCard(BuildContext context, AppState s, Workout? w, bool done) {
    if (w == null) {
      return Panel(
        radius: 28,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Bean(mood: Mood.sleepy, size: 54),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Label("Today"),
                  Text('Rest day', style: T.display(24)),
                  Text(
                    'Muscles grow while you recover.',
                    style: T.body(14, color: C.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        color: done ? C.pot : C.lime,
        borderRadius: BorderRadius.circular(28),
        border: done ? Border.all(color: C.lime, width: 1.5) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done ? "TODAY'S WORKOUT, DONE" : "TODAY'S WORKOUT",
                  style: T.label(color: done ? C.lime : C.ink.withAlpha(190)),
                ),
                const SizedBox(height: 2),
                Text(
                  w.title,
                  style: T.display(24, color: done ? C.text : C.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  '${w.minutes} min · ${w.exercises.length} moves · no jumping${w.deload ? ' · deload' : ''}',
                  style: T.body(
                    14,
                    color: done ? C.muted : C.ink.withAlpha(220),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (done)
            const Icon(Icons.check_circle_rounded, color: C.lime, size: 40)
          else
            PillButton(
              'Start',
              height: 52,
              fontSize: 17,
              color: C.ink,
              textColor: C.lime,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutPreviewScreen(date: s.today),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
