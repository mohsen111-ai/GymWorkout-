import 'package:flutter/material.dart';

import '../models.dart';
import '../notifications.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/bean.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late final AppState s = AppScope.of(context);
  late ReminderSettings r = ReminderSettings.fromJson(
    s.data.reminders.toJson(),
  );

  Future<void> _commit() async {
    await s.saveReminders(r);
    setState(() {});
  }

  Future<void> _pick(int minutes, ValueChanged<int> set) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (t != null) {
      set(t.hour * 60 + t.minute);
      await _commit();
    }
  }

  Widget _time(int minutes, ValueChanged<int> set) => TextButton(
    onPressed: () => _pick(minutes, set),
    child: Text(
      clock12(minutes),
      style: T.body(14, color: C.lime, weight: FontWeight.w800),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                const BackCircle(),
                const SizedBox(width: 12),
                Text('Reminders', style: T.display(28)),
              ],
            ),
            const SizedBox(height: 14),
            const BeanSays(
              'I will nudge you gently. You choose when, and quiet hours stay quiet.',
              mood: Mood.happy,
            ),
            const SizedBox(height: 16),
            SwitchRow(
              title: 'Workout',
              subtitle: 'On training days',
              value: r.workout,
              trailing: _time(r.workoutMinutes, (m) => r.workoutMinutes = m),
              onChanged: (v) {
                r.workout = v;
                _commit();
              },
            ),
            const SizedBox(height: 8),
            SwitchRow(
              title: 'Morning weigh-in',
              subtitle: 'Before breakfast',
              value: r.weighIn,
              trailing: _time(r.weighInMinutes, (m) => r.weighInMinutes = m),
              onChanged: (v) {
                r.weighIn = v;
                _commit();
              },
            ),
            const SizedBox(height: 8),
            SwitchRow(
              title: 'Meals',
              subtitle: 'Log breakfast, lunch and dinner',
              value: r.meals,
              onChanged: (v) {
                r.meals = v;
                _commit();
              },
            ),
            const SizedBox(height: 8),
            SwitchRow(
              title: 'Protein check',
              subtitle: 'Only if you are behind',
              value: r.protein,
              trailing: _time(r.proteinMinutes, (m) => r.proteinMinutes = m),
              onChanged: (v) {
                r.protein = v;
                _commit();
              },
            ),
            const SizedBox(height: 8),
            SwitchRow(
              title: 'Water',
              subtitle: 'A few nudges during the day',
              value: r.water,
              onChanged: (v) {
                r.water = v;
                _commit();
              },
            ),
            const SizedBox(height: 8),
            SwitchRow(
              title: 'Weekly recap',
              subtitle: 'Sundays at 6:00 PM',
              value: r.weekly,
              onChanged: (v) {
                r.weekly = v;
                _commit();
              },
            ),
            const SizedBox(height: 8),
            SwitchRow(
              title: 'Streak saver',
              subtitle: 'Evening heads-up if the day is empty',
              value: r.streak,
              onChanged: (v) {
                r.streak = v;
                _commit();
              },
            ),
            const SizedBox(height: 18),
            Panel(
              radius: 20,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quiet hours',
                    style: T.body(16, weight: FontWeight.w700),
                  ),
                  Text(
                    'No reminders in this window.',
                    style: T.body(13, color: C.muted),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('From', style: T.body(14, color: C.soft)),
                      _time(
                        r.quietStartMinutes,
                        (m) => r.quietStartMinutes = m,
                      ),
                      Text('to', style: T.body(14, color: C.soft)),
                      _time(r.quietEndMinutes, (m) => r.quietEndMinutes = m),
                    ],
                  ),
                  const Divider(color: C.line, height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Most reminders per day',
                          style: T.body(15, weight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fewer',
                        onPressed: r.maxPerDay <= 1
                            ? null
                            : () {
                                r.maxPerDay--;
                                _commit();
                              },
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                      ),
                      Text('${r.maxPerDay}', style: T.display(22)),
                      IconButton(
                        tooltip: 'More',
                        onPressed: r.maxPerDay >= 8
                            ? null
                            : () {
                                r.maxPerDay++;
                                _commit();
                              },
                        icon: const Icon(Icons.add_circle_outline_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Reminders skip things you already did today, like a logged workout or a full water goal. They run on your phone, with no account or internet.',
              style: T.body(13, color: C.muted),
            ),
            const SizedBox(height: 16),
            PillButton(
              'Allow notifications',
              height: 52,
              fontSize: 16,
              outlined: true,
              color: C.lime,
              onPressed: () async {
                final ok = await Notifier.requestPermission();
                if (context.mounted) {
                  toast(
                    context,
                    ok
                        ? 'Notifications are on'
                        : 'Allow notifications in Android settings',
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            PillButton(
              'Send a test from Bean',
              height: 52,
              fontSize: 16,
              outlined: true,
              color: C.text,
              onPressed: () async {
                await Notifier.showNow(
                  'Hi from Bean!',
                  'Reminders are working. Time to move!',
                );
                if (context.mounted) toast(context, 'Test sent');
              },
            ),
            const SizedBox(height: 14),
            Text(
              'Tip: some phones (Xiaomi, Samsung, Oppo) stop background apps. If reminders arrive late, open Android Settings, Apps, Mighty Bean, Battery, and choose Unrestricted.',
              style: T.body(12, color: C.muted),
            ),
          ],
        ),
      ),
    );
  }
}
