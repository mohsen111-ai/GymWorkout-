import 'package:flutter/material.dart';

import '../logic/nutrition.dart';
import '../logic/planner.dart';
import '../logic/progression.dart';
import '../models.dart';
import '../notifications.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _age = TextEditingController(text: '19');
  final _height = TextEditingController(text: '175');
  final _weight = TextEditingController(text: '85');
  final _goal = TextEditingController(text: '75');
  Sex _sex = Sex.male;
  double _pace = 0.5;
  int _days = 4;
  int _pushups = 1; // index into _pushOptions
  bool _active = false;
  double _activity = 1.4;
  String? _error;

  static const _pushOptions = ['None yet', '1 to 5', '6 to 12', '13 or more'];
  static const _pushValues = [0, 3, 9, 15];

  @override
  void dispose() {
    for (final c in [_age, _height, _weight, _goal]) {
      c.dispose();
    }
    super.dispose();
  }

  Profile? _draft() {
    final age = parseNum(_age.text)?.round();
    final h = parseNum(_height.text);
    final w = parseNum(_weight.text);
    final g = parseNum(_goal.text);
    if (age == null || h == null || w == null || g == null) return null;
    return Profile(
      sex: _sex,
      age: age,
      heightCm: h,
      startWeight: w,
      goalWeight: g,
      paceKg: _pace,
      activity: _activity,
      trainDays: defaultTrainDays(_days),
    );
  }

  String? _validate(Profile? p) {
    if (p == null) return 'Please fill in every number.';
    if (p.age < 16 || p.age > 80) return 'Age should be between 16 and 80.';
    if (p.heightCm < 120 || p.heightCm > 230) {
      return 'Height should be between 120 and 230 cm.';
    }
    if (p.startWeight < 35 || p.startWeight > 250) {
      return 'Weight should be between 35 and 250 kg.';
    }
    if (p.goalWeight < minGoalWeight(p)) {
      return 'Goal weight should be at least ${minGoalWeight(p).ceil()} kg for your height. Going lower is not healthy.';
    }
    return null;
  }

  Future<void> _start() async {
    final p = _draft();
    final err = _validate(p);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    final state = AppScope.of(context);
    await state.createProfile(
      p!,
      initialLadders(pushups: _pushValues[_pushups], active: _active),
    );
    await Notifier.requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    final p = _draft();
    final ok = p != null && _validate(p) == null;
    final t = ok ? targetsFor(p, p.startWeight) : null;
    final date = ok
        ? goalDate(p.startWeight, p.goalWeight, p.paceKg, DateTime.now())
        : null;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            const BeanSays(
              "Hi, I'm Bean! Tell me about you and I'll build your plan.",
              size: 100,
            ),
            const SizedBox(height: 20),
            Text(
              'Lose fat. Build muscle.\nFrom your living room.',
              style: T.display(32),
            ),
            const SizedBox(height: 6),
            Text(
              'No equipment. No jumping.',
              style: T.body(15, color: C.muted),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: NumField(
                    controller: _age,
                    label: 'Age',
                    decimal: false,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NumField(
                    controller: _height,
                    label: 'Height (cm)',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NumField(
                    controller: _weight,
                    label: 'Weight (kg)',
                    highlight: true,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Chip2(
                  'Male',
                  selected: _sex == Sex.male,
                  onTap: () => setState(() => _sex = Sex.male),
                ),
                const SizedBox(width: 10),
                Chip2(
                  'Female',
                  selected: _sex == Sex.female,
                  onTap: () => setState(() => _sex = Sex.female),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: NumField(
                    controller: _goal,
                    label: 'Goal weight (kg)',
                    highlight: true,
                    highlightColor: C.butter,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const Label('Push-ups with good form'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _pushOptions.length; i++)
                  Chip2(
                    _pushOptions[i],
                    selected: _pushups == i,
                    onTap: () => setState(() => _pushups = i),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            const Label('Right now I am'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip2(
                  'Mostly sitting',
                  selected: !_active && _activity == 1.4,
                  onTap: () => setState(() {
                    _active = false;
                    _activity = 1.4;
                  }),
                ),
                Chip2(
                  'Exercising a bit',
                  selected: _active && _activity == 1.5,
                  onTap: () => setState(() {
                    _active = true;
                    _activity = 1.5;
                  }),
                ),
                Chip2(
                  'Already active',
                  selected: _active && _activity == 1.6,
                  onTap: () => setState(() {
                    _active = true;
                    _activity = 1.6;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Label('Weight loss per week'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in [0.25, 0.5, 0.75, 1.0])
                  Chip2(
                    '${v == 0.25 ? '0.25' : v.toString()} kg',
                    selected: _pace == v,
                    color: v == 1.0 ? C.coral : C.lime,
                    onTap: () => setState(() => _pace = v),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _pace >= 1.0
                  ? 'The fastest we allow. It is harder to stick to and you can lose muscle. 0.5 is the sweet spot.'
                  : '0.5 kg a week is great for keeping muscle while you lose fat.',
              style: T.body(13, color: C.muted),
            ),
            const SizedBox(height: 18),
            const Label('Training days per week'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final d in [2, 3, 4, 5])
                  Chip2(
                    '$d days',
                    selected: _days == d,
                    onTap: () => setState(() => _days = d),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Panel(
              radius: 24,
              padding: const EdgeInsets.all(20),
              child: t == null
                  ? Text(
                      'Fill in your details to see your plan.',
                      style: T.body(15, color: C.muted),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Label('Your daily plan'),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _stat(fmtNum(t.kcal), 'kcal a day', C.text),
                            _stat('${t.protein} g', 'protein', C.coral),
                            _stat(
                              '${t.waterL.toStringAsFixed(1)} L',
                              'water',
                              C.sky,
                            ),
                          ],
                        ),
                        const Divider(color: C.line, height: 28),
                        Text(
                          t.deficit > 0
                              ? 'A ${t.deficit} kcal deficit. Expect about ${_pace.toString()} kg a week${date == null ? '' : ', reaching ${p!.goalWeight.toStringAsFixed(0)} kg around ${monthWord(date)}'}. Bean adjusts it as you lose weight.'
                              : 'You are at your goal, so this is a maintenance plan.',
                          style: T.body(14, color: C.soft),
                        ),
                      ],
                    ),
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
              'Start my plan',
              onPressed: ok
                  ? _start
                  : () => setState(() => _error = _validate(p)),
              icon: Icons.arrow_forward_rounded,
            ),
            const SizedBox(height: 14),
            Text(
              'Bean gives general fitness guidance, not medical advice. If you have a health condition or injury, check with a doctor first.',
              textAlign: TextAlign.center,
              style: T.body(12, color: C.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String big, String small, Color c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(big, style: T.display(30, color: c)),
      Text(small, style: T.body(13, color: C.muted)),
    ],
  );
}
