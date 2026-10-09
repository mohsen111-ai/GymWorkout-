import 'package:flutter/material.dart';

import '../logic/nutrition.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';
import 'reminders.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late final AppState s = AppScope.of(context);
  late final _cw = TextEditingController(
    text: s.currentWeight.toStringAsFixed(1),
  );
  late final _gw = TextEditingController(text: _trim(s.profile.goalWeight));
  late final _waist = TextEditingController(
    text: s.profile.waistCm == null ? '' : _trim(s.profile.waistCm!),
  );
  late final _goalWaist = TextEditingController(
    text: s.profile.goalWaistCm == null ? '' : _trim(s.profile.goalWaistCm!),
  );
  late final _steps = TextEditingController(text: '${s.profile.stepGoal}');
  late double _pace = s.profile.paceKg;
  late double _activity = s.profile.activity;
  String? _error;

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

  @override
  void dispose() {
    for (final c in [_cw, _gw, _waist, _goalWaist, _steps]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final p = s.profile;
    final cw = parseNum(_cw.text);
    final gw = parseNum(_gw.text);
    final steps = parseNum(_steps.text)?.round();
    if (cw == null || cw < 30 || cw > 300) {
      setState(() => _error = 'Enter your current weight in kg.');
      return;
    }
    if (gw == null || gw < minGoalWeight(p)) {
      setState(
        () => _error =
            'Goal weight should be at least ${minGoalWeight(p).ceil()} kg for your height.',
      );
      return;
    }
    if (steps == null || steps < 1000) {
      setState(() => _error = 'Step goal should be at least 1,000.');
      return;
    }
    final waist = parseNum(_waist.text);
    final goalWaist = parseNum(_goalWaist.text);
    await s.updateProfile((p) {
      p.goalWeight = gw;
      p.paceKg = _pace;
      p.activity = _activity;
      p.stepGoal = steps;
      p.waistCm = waist;
      p.goalWaistCm = goalWaist;
    });
    if ((cw - s.currentWeight).abs() > 0.04) await s.setWeight(s.today, cw);
    if (waist != null) await s.setWaist(s.today, waist);
    if (mounted) {
      toast(context, 'Goals saved');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = s.profile;
    final now = parseNum(_cw.text) ?? s.currentWeight;
    final goal = parseNum(_gw.text) ?? p.goalWeight;
    final lost = (p.startWeight - now);
    final toGo = (now - goal);
    final prog = (p.startWeight - goal) <= 0
        ? 1.0
        : (lost / (p.startWeight - goal));
    final draft = _draftProfile(goal);
    final t = targetsFor(draft, now);
    final date = goalDate(now, goal, _pace, s.today);
    final bf = estimatedBodyFat(p, now);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                const BackCircle(),
                const SizedBox(width: 12),
                Text('My goals', style: T.display(28)),
              ],
            ),
            const SizedBox(height: 16),
            Panel(
              radius: 28,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _col(
                        'Start',
                        p.startWeight.toStringAsFixed(1),
                        C.text,
                        22,
                      ),
                      _col(
                        'Now',
                        now.toStringAsFixed(1),
                        C.lime,
                        40,
                        tagColor: C.lime,
                      ),
                      _col(
                        'Goal',
                        goal.toStringAsFixed(1),
                        C.butter,
                        22,
                        tagColor: C.butter,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Bar(prog, height: 14),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${lost.abs().toStringAsFixed(1)} kg',
                              style: T.body(13, weight: FontWeight.w800),
                            ),
                            TextSpan(
                              text: lost >= 0 ? ' lost' : ' gained',
                              style: T.body(13, color: C.soft),
                            ),
                          ],
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  '${toGo.clamp(0, 999).toStringAsFixed(1)} kg',
                              style: T.body(13, weight: FontWeight.w800),
                            ),
                            TextSpan(
                              text: ' to go',
                              style: T.body(13, color: C.soft),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: NumField(
                    controller: _cw,
                    label: 'Current weight (kg)',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NumField(
                    controller: _gw,
                    label: 'Goal weight (kg)',
                    highlight: true,
                    highlightColor: C.butter,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Panel(
              radius: 22,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pace per week',
                        style: T.body(15, weight: FontWeight.w700),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Goal reached: ',
                              style: T.body(13, color: C.muted),
                            ),
                            TextSpan(
                              text: toGo <= 0
                                  ? 'now'
                                  : (date == null ? '--' : monthWord(date)),
                              style: T.body(
                                13,
                                color: C.butter,
                                weight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final v in [0.25, 0.5, 0.75, 1.0])
                        Chip2(
                          '${v.toString()} kg',
                          selected: _pace == v,
                          color: v == 1.0 ? C.coral : C.lime,
                          onTap: () => setState(() => _pace = v),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '1.0 kg a week is the fastest we allow and needs about 1,000 kcal under maintenance. 0.5 is best for keeping muscle.',
                    style: T.body(12, color: C.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: NumField(controller: _waist, label: 'Waist now (cm)'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NumField(
                    controller: _goalWaist,
                    label: 'Waist goal (cm)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Panel(
              radius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Body fat (estimate)',
                      style: T.body(14, color: C.soft),
                    ),
                  ),
                  Text('${bf.round()}%', style: T.display(22)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'A rough guess from height, weight and age. A tape measure tells you more.',
              style: T.body(12, color: C.muted),
            ),
            const SizedBox(height: 16),
            const Label('Activity level'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, v) in [
                  ('Mostly sitting', 1.4),
                  ('Exercising a bit', 1.5),
                  ('Already active', 1.6),
                ])
                  Chip2(
                    label,
                    selected: _activity == v,
                    onTap: () => setState(() => _activity = v),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Panel(
              radius: 22,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Label('Daily targets'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _target(fmtNum(t.kcal), 'kcal', C.text),
                      _target('${t.protein} g', 'protein', C.coral),
                      _target('${t.carbs} g', 'carbs', C.butter),
                      _target('${t.fat} g', 'fat', C.sky),
                      _target(
                        '${t.waterL.toStringAsFixed(1)} L',
                        'water',
                        C.sky,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Calories and protein update automatically as your weight changes.',
                    style: T.body(12, color: C.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            NumField(
              controller: _steps,
              label: 'Daily step goal',
              decimal: false,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: T.body(14, color: C.coral, weight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 18),
            PillButton(
              'Save goals',
              height: 56,
              fontSize: 19,
              onPressed: _save,
            ),
            const SizedBox(height: 12),
            PillButton(
              'Reminders',
              height: 52,
              fontSize: 16,
              outlined: true,
              color: C.text,
              icon: Icons.notifications_none_rounded,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RemindersScreen()),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                final ok = await confirm(
                  context,
                  title: 'Start over?',
                  message: 'This deletes your profile, weigh-ins, meals and workouts from this phone. It cannot be undone.',
                  yes: 'Delete everything',
                  danger: true,
                );
                if (ok) {
                  await s.resetAll();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  }
                }
              },
              child: Text(
                'Reset all my data',
                style: T.body(14, color: C.coral, weight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A copy of the profile with the pending edits, to preview targets.
  Profile _draftProfile(double goal) {
    final p = s.profile;
    return Profile(
      sex: p.sex,
      age: p.age,
      heightCm: p.heightCm,
      startWeight: p.startWeight,
      goalWeight: goal,
      paceKg: _pace,
      activity: _activity,
      trainDays: p.trainDays,
      startDate: p.startDate,
      stepGoal: p.stepGoal,
    );
  }

  Widget _col(String tag, String v, Color c, double size, {Color? tagColor}) =>
      Column(
        children: [
          Text(
            tag,
            style: T.body(
              12,
              color: tagColor ?? C.muted,
              weight: tagColor == null ? FontWeight.w400 : FontWeight.w700,
            ),
          ),
          Text(v, style: T.display(size, color: c)),
        ],
      );

  Widget _target(String big, String small, Color c) => Column(
    children: [
      Text(big, style: T.display(16, color: c)),
      Text(small, style: T.body(11, color: C.muted)),
    ],
  );
}
