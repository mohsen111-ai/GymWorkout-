import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';
import 'state.dart';

class PlannedReminder {
  final DateTime when;
  final int slot;
  final int priority;
  final String title;
  final String body;

  PlannedReminder(this.when, this.slot, this.priority, this.title, this.body);
}

/// Daily reminders from Bean. All local to the phone, no account or internet.
///
/// Instead of one repeating alarm per reminder, the next 10 days are planned
/// each time the app opens or you log something. That lets us skip a reminder
/// you have already finished today.
class Notifier {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const _windowDays = 10;

  static bool get supported => !kIsWeb && Platform.isAndroid;

  static Future<void> init() async {
    if (!supported || _ready) return;
    try {
      tzdata.initializeTimeZones();
      final name = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(name));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_bean'),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Notifier init failed: $e');
    }
  }

  static Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'bean_reminders',
      'Bean reminders',
      channelDescription: 'Workout, meal, water and weigh-in reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  );

  static Future<void> showNow(String title, String body) async {
    if (!_ready) return;
    await _plugin.show(
      id: 9999,
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }

  static bool _inQuiet(int minutes, ReminderSettings r) {
    final s = r.quietStartMinutes;
    final e = r.quietEndMinutes;
    if (s == e) return false;
    return s < e
        ? (minutes >= s && minutes < e)
        : (minutes >= s || minutes < e);
  }

  /// Pure planning step, kept separate so it can be tested.
  static List<PlannedReminder> plan(AppState st, DateTime now) {
    if (!st.hasProfile) return [];
    final r = st.data.reminders;
    final targets = st.targets;
    final out = <PlannedReminder>[];
    final today = DateTime(now.year, now.month, now.day);

    for (var i = 0; i < _windowDays; i++) {
      final day = today.add(Duration(days: i));
      final isToday = i == 0;
      final list = <PlannedReminder>[];

      DateTime at(int minutes) =>
          DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);
      void add(int slot, int prio, int minutes, String title, String body) {
        if (_inQuiet(minutes, r)) return;
        final when = at(minutes);
        if (when.isBefore(now.add(const Duration(minutes: 1)))) return;
        list.add(PlannedReminder(when, slot, prio, title, body));
      }

      final workout = st.workoutOn(day);
      if (r.workout && workout != null && !(isToday && st.workoutDone(day))) {
        add(
          0,
          0,
          r.workoutMinutes,
          "${workout.title} day!",
          "${workout.minutes} minutes, no jumping. Bean's ready when you are.",
        );
      }
      if (r.weekly && day.weekday == DateTime.sunday) {
        add(
          1,
          0,
          18 * 60,
          'Your week is ready',
          'See how this week went: workouts, protein and weight.',
        );
      }
      if (r.protein &&
          !(isToday && st.proteinOn(day) >= targets.protein * 0.9)) {
        add(
          2,
          1,
          r.proteinMinutes,
          'Protein check',
          isToday
              ? '${(targets.protein - st.proteinOn(day)).round()} g to go. A Greek yogurt or tuna would help.'
              : 'Have you hit ${targets.protein} g of protein today?',
        );
      }
      if (r.streak && !(isToday && st.activeOn(day))) {
        final n = st.streak;
        add(
          3,
          2,
          21 * 60,
          n > 1 ? 'Keep your $n-day streak' : 'Quick check-in',
          'Log a meal, your weight or a workout so Bean can cheer for you.',
        );
      }
      if (r.weighIn && !(isToday && st.weightOn(day) != null)) {
        add(
          4,
          3,
          r.weighInMinutes,
          'Morning weigh-in',
          'Step on the scale before breakfast. Takes ten seconds.',
        );
      }
      if (r.meals) {
        const meals = [
          (5, 9 * 60, 'breakfast'),
          (6, 13 * 60, 'lunch'),
          (7, 19 * 60 + 30, 'dinner'),
        ];
        for (final m in meals) {
          final logged =
              isToday && st.entriesOn(day).any((e) => e.meal.name == m.$3);
          if (!logged) {
            add(
              m.$1,
              4,
              m.$2,
              'Log your ${m.$3}',
              'Add what you ate so your calories and protein stay accurate.',
            );
          }
        }
      }
      if (r.water && !(isToday && st.waterOn(day) >= targets.waterL * 1000)) {
        for (final (slot, min) in [(8, 11 * 60), (9, 15 * 60), (10, 18 * 60)]) {
          add(
            slot,
            5,
            min,
            'Drink some water',
            'Tap a glass in Bean to log it.',
          );
        }
      }

      list.sort((a, b) {
        final p = a.priority.compareTo(b.priority);
        return p != 0 ? p : a.when.compareTo(b.when);
      });
      out.addAll(list.take(r.maxPerDay));
    }
    return out;
  }

  static Future<void> reschedule(AppState st) async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      final now = DateTime.now();
      for (final n in plan(st, now)) {
        final dayOffset = DateTime(
          n.when.year,
          n.when.month,
          n.when.day,
        ).difference(DateTime(now.year, now.month, now.day)).inDays;
        await _plugin.zonedSchedule(
          id: dayOffset * 20 + n.slot,
          title: n.title,
          body: n.body,
          scheduledDate: tz.TZDateTime.from(n.when, tz.local),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('Notifier reschedule failed: $e');
    }
  }
}
