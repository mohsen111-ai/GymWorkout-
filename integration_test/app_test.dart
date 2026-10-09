import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mighty_bean/main.dart';
import 'package:mighty_bean/notifications.dart';
import 'package:mighty_bean/screens/shell.dart';
import 'package:mighty_bean/state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runs on a real Android emulator: fresh install, sign up, log food, do a
/// whole workout, check the weekly screen and that reminders are queued.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> settle(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(milliseconds: 700));
  }

  Future<void> shot(WidgetTester t, String name) async {
    await settle(t);
    await binding.takeScreenshot(name);
  }

  Future<void> tap(WidgetTester t, Finder f) async {
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
    await settle(t);
  }

  testWidgets('fresh install to finished workout', (t) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    final state = await AppState.load();
    await Notifier.init();
    await binding.convertFlutterSurfaceToImage();
    await t.pumpWidget(MightyBeanApp(state: state));
    await settle(t);

    // ---- sign up
    expect(find.textContaining('Hi, I'), findsOneWidget);
    await shot(t, '01_welcome');
    await t.scrollUntilVisible(
      find.text('Start my plan'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await shot(t, '02_plan_preview');
    await tap(t, find.text('Start my plan'));
    expect(state.hasProfile, true);
    expect(find.text('kcal left'), findsOneWidget);
    await shot(t, '03_today');

    // ---- water and food
    await tap(t, find.text('+ Glass'));
    expect(state.waterOn(state.today), 250);
    await tap(t, find.text('Food'));
    await tap(t, find.textContaining('+ Chicken breast'));
    expect(state.proteinOn(state.today), greaterThan(40));
    await shot(t, '04_food');

    // ---- plan tab
    await tap(t, find.text('Train'));
    expect(find.text('Your plan'), findsOneWidget);
    await shot(t, '05_plan');

    // ---- reminders are really queued with Android
    await Notifier.reschedule(state);
    final queued = await Notifier.pendingCount();
    // ignore: avoid_print
    print('queued reminders: $queued');
    expect(queued, greaterThan(0));

    // ---- a whole workout. Make sure today is a training day whatever
    // day the test runs on.
    final today = state.today;
    await state.updateProfile(
      (p) => p.trainDays = {...p.trainDays, today.weekday}.toList()..sort(),
    );
    tabIndex.value = 0;
    await settle(t);
    await tap(t, find.text('Start'));
    await shot(t, '06_preview');
    await tap(t, find.text('Start workout'));
    final w = state.workoutOn(today)!;
    final total = w.exercises.fold<int>(0, (a, e) => a + e.sets);
    await shot(t, '07_session');
    for (var i = 0; i < total; i++) {
      final done = find.textContaining(RegExp(r'Set done|Move done|Finish'));
      expect(done, findsOneWidget, reason: 'set ${i + 1} of $total');
      await tap(t, done);
      if (i == 0) await shot(t, '08_rest');
      if (i < total - 1) await tap(t, find.text('Skip rest'));
    }
    await shot(t, '09_finished');
    await tap(t, find.text('Save workout'));
    await t.pump(const Duration(seconds: 1));
    expect(state.workoutDone(today), true);

    // ---- progress tab
    await tap(t, find.text('Progress'));
    expect(find.text('This week'), findsWidgets);
    await shot(t, '10_progress');

    // ---- it survives a restart: data is read back from the phone
    final reloaded = await AppState.load();
    expect(reloaded.hasProfile, true);
    expect(reloaded.waterOn(reloaded.today), 250);
  });
}
