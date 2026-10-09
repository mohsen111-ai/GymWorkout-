import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mighty_bean/logic/progression.dart';
import 'package:mighty_bean/main.dart';
import 'package:mighty_bean/models.dart';
import 'package:mighty_bean/notifications.dart';
import 'package:mighty_bean/screens/shell.dart';
import 'package:mighty_bean/state.dart';

// Monday 5 Oct 2026, mid-morning. Program started three weeks earlier.
final _now = DateTime(2026, 10, 5, 10, 0);

AppState _state({bool profile = true}) {
  final data = AppData();
  if (profile) {
    data.profile = Profile(
      sex: Sex.male,
      age: 19,
      heightCm: 175,
      startWeight: 85,
      goalWeight: 75,
      startDate: DateTime(2026, 9, 14),
    );
    data.ladders = initialLadders(pushups: 3, active: false);
    data.weights['2026-10-05'] = 84.6;
  }
  return AppState(data, null, clock: () => _now);
}

/// The test font (Ahem) is about twice as wide as real text, so layout
/// overflow reports in tests are noise. Everything else still fails the test.
void _ignoreOverflow() {
  final orig = FlutterError.onError;
  FlutterError.onError = (d) {
    if (d.exceptionAsString().contains('overflowed')) return;
    orig?.call(d);
  };
  addTearDown(() => FlutterError.onError = orig);
}

void _phone(WidgetTester t) {
  _ignoreOverflow();
  t.view.physicalSize = const Size(1080, 2400);
  t.view.devicePixelRatio = 2.75;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

/// Scrolls the first scrollable until [f] is on screen, then taps it.
Future<void> _tap(WidgetTester t, Finder f) async {
  if (f.evaluate().isEmpty) {
    await t.scrollUntilVisible(
      f,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await t.ensureVisible(f);
  await t.pump();
  await t.tap(f);
  await _pump(t);
}

Future<void> _pump(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 600));
}

void main() {
  setUp(() => tabIndex.value = 0);

  testWidgets('first launch shows the plan and starts the app', (t) async {
    _phone(t);
    final s = _state(profile: false);
    await t.pumpWidget(MightyBeanApp(state: s));
    await _pump(t);
    await t.scrollUntilVisible(
      find.text('Start my plan'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('YOUR DAILY PLAN'), findsOneWidget);
    await _tap(t, find.text('Start my plan'));
    expect(s.hasProfile, true);
    expect(find.text('Today'), findsWidgets);
    expect(find.text('kcal left'), findsOneWidget);
  });

  testWidgets('rejects an unhealthy goal weight', (t) async {
    _phone(t);
    final s = _state(profile: false);
    await t.pumpWidget(MightyBeanApp(state: s));
    await _pump(t);
    await t.enterText(find.byType(TextField).at(3), '40');
    await _pump(t);
    await _tap(t, find.text('Start my plan'));
    expect(s.hasProfile, false);
    expect(find.textContaining('at least'), findsOneWidget);
  });

  testWidgets('every tab renders', (t) async {
    _phone(t);
    final s = _state();
    await t.pumpWidget(MightyBeanApp(state: s));
    await _pump(t);
    expect(find.text('Push'), findsWidgets);

    await t.tap(find.text('Train'));
    await _pump(t);
    expect(find.text('Your plan'), findsOneWidget);
    expect(
      find.text('Week 4 of 4'),
      findsOneWidget,
    ); // 3 weeks in = deload week

    await t.tap(find.text('Food'));
    await _pump(t);
    expect(find.text('Breakfast'), findsOneWidget);

    await t.tap(find.text('Progress'));
    await _pump(t);
    expect(find.text('This week'), findsWidgets);
  });

  testWidgets('logging food updates protein', (t) async {
    _phone(t);
    final s = _state();
    await t.pumpWidget(MightyBeanApp(state: s));
    await _pump(t);
    await t.tap(find.text('Food'));
    await _pump(t);
    await _tap(t, find.textContaining('+ Chicken breast'));
    expect(s.proteinOn(s.today), closeTo(46, 0.1));
    expect(s.kcalOn(s.today), closeTo(248, 0.1));
  });

  testWidgets('water glass button adds 250 ml', (t) async {
    _phone(t);
    final s = _state();
    await t.pumpWidget(MightyBeanApp(state: s));
    await _pump(t);
    await _tap(t, find.text('+ Glass'));
    expect(s.waterOn(s.today), 250);
  });

  testWidgets('complete a whole workout and save it', (t) async {
    _phone(t);
    final s = _state();
    await t.pumpWidget(MightyBeanApp(state: s));
    await _pump(t);

    final w = s.workoutOn(s.today)!;
    final total = w.exercises.fold<int>(0, (a, e) => a + e.sets);

    await _tap(t, find.text('Start'));
    expect(find.text('Start workout'), findsOneWidget);
    await _tap(t, find.text('Start workout'));

    for (var i = 0; i < total; i++) {
      final done = find.textContaining(RegExp(r'Set done|Move done|Finish'));
      expect(done, findsOneWidget, reason: 'set ${i + 1} of $total');
      await t.tap(done);
      await _pump(t);
      if (i < total - 1) {
        expect(find.text('Rest'), findsOneWidget);
        await t.tap(find.text('Skip rest'));
        await _pump(t);
      }
    }
    expect(find.text('Workout complete!'), findsOneWidget);
    await _tap(t, find.text('Save workout'));
    await t.pump(const Duration(seconds: 1));
    expect(s.data.workouts, hasLength(1));
    expect(s.data.workouts.single.exercises, hasLength(w.exercises.length));
    expect(s.workoutDone(s.today), true);
  });

  test('notification plan respects quiet hours and the daily cap', () {
    final s = _state();
    final plan = Notifier.plan(s, _now);
    expect(plan, isNotEmpty);
    final perDay = <String, int>{};
    for (final r in plan) {
      final m = r.when.hour * 60 + r.when.minute;
      expect(
        m >= 7 * 60 && m < 22 * 60,
        true,
        reason: 'quiet hours: ${r.when}',
      );
      expect(r.when.isAfter(_now), true);
      perDay.update(dayKey(r.when), (v) => v + 1, ifAbsent: () => 1);
    }
    expect(perDay.values.every((n) => n <= 4), true);
  });

  test('notification plan skips things already done today', () async {
    final s = _state();
    await s.completeWorkout(
      s.workoutOn(s.today)!,
      [
        for (final e in s.workoutOn(s.today)!.exercises)
          List.filled(e.sets, e.target),
      ],
      Felt.ok,
      30,
    );
    final today = Notifier.plan(
      s,
      _now,
    ).where((r) => dayKey(r.when) == dayKey(_now));
    expect(today.any((r) => r.title.contains('day!')), false);
  });
}
