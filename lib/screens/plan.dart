import 'package:flutter/material.dart';

import '../logic/planner.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'library.dart';
import 'preview.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final clock = s.programClock;
    final start = weekStartOf(s.today);
    final p = s.profile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Text('Your plan', style: T.display(30)),
        const SizedBox(height: 2),
        Text(
          'Block ${clock.block + 1} · ${emphasisName(clock.emphasis)} · ${p.trainDays.length} training days a week',
          style: T.body(14, color: C.muted),
        ),
        const SizedBox(height: 14),
        Panel(
          radius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Week ${clock.weekNumber} of 4',
                    style: T.body(16, weight: FontWeight.w700),
                  ),
                  Text(
                    clock.deload ? 'Deload week' : 'Deload next: week 4',
                    style: T.body(13, color: clock.deload ? C.sky : C.muted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: i < clock.weekInBlock
                                  ? C.lime
                                  : (i == clock.weekInBlock
                                        ? (i == 3
                                              ? C.sky
                                              : C.lime.withAlpha(140))
                                        : C.line),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            i == 3 ? 'Deload' : 'Wk ${i + 1}',
                            style: T.body(
                              12,
                              color: i == clock.weekInBlock
                                  ? (i == 3 ? C.sky : C.lime)
                                  : (i == 3 ? C.sky.withAlpha(180) : C.muted),
                              weight: i == clock.weekInBlock
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < 3) const SizedBox(width: 6),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                clock.deload
                    ? 'Lighter week: fewer sets and easier targets so your body recovers and comes back stronger.'
                    : '${emphasisBlurb(clock.emphasis)} ${clock.weekInBlock == 2 ? 'This week adds an extra set.' : 'Targets rise as you hit them.'}',
                style: T.body(13, color: C.soft),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < 7; i++)
          _dayRow(context, s, start.add(Duration(days: i))),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: PillButton(
                'Change days',
                height: 48,
                fontSize: 14,
                outlined: true,
                color: C.text,
                onPressed: () => _changeDays(context, s),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PillButton(
                'Exercise library',
                height: 48,
                fontSize: 14,
                outlined: true,
                color: C.text,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LibraryScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dayRow(BuildContext context, AppState s, DateTime day) {
    final isToday = day == s.today;
    final w = s.workoutOn(day);
    final done = s.workoutDone(day);
    final past = day.isBefore(s.today) && !day.isBefore(s.profile.startDate);
    final rest = w == null;

    final content = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: rest ? Colors.transparent : C.pot,
        borderRadius: BorderRadius.circular(20),
        border: isToday
            ? Border.all(color: C.lime, width: 2)
            : (rest ? Border.all(color: C.line, width: 1.5) : null),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              isToday ? 'Today' : dowName(day.weekday),
              style: T.body(
                13,
                color: isToday ? C.lime : C.muted,
                weight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rest ? 'Rest' : w.title,
                  style: T.body(
                    15,
                    color: rest ? C.muted : C.text,
                    weight: FontWeight.w700,
                  ),
                ),
                Text(
                  rest
                      ? '${fmtNum(s.profile.stepGoal)} steps and a stretch'
                      : '${w.template.subtitle} · ${w.minutes} min',
                  style: T.body(12, color: C.muted),
                ),
              ],
            ),
          ),
          if (done)
            const CircleAvatar(
              radius: 14,
              backgroundColor: C.lime,
              child: Icon(Icons.check_rounded, size: 18, color: C.ink),
            )
          else if (!rest && isToday)
            const Icon(Icons.play_circle_fill_rounded, color: C.lime, size: 34)
          else if (!rest && past)
            Text('Missed', style: T.body(12, color: C.muted))
          else if (!rest)
            const Icon(Icons.chevron_right_rounded, color: C.muted),
        ],
      ),
    );
    if (rest) return content;
    return Semantics(
      button: true,
      label: '${w.title} on ${niceDate(day)}',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WorkoutPreviewScreen(date: day)),
        ),
        child: content,
      ),
    );
  }

  Future<void> _changeDays(BuildContext context, AppState s) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _DaysSheet(state: s),
    );
  }
}

class _DaysSheet extends StatefulWidget {
  final AppState state;
  const _DaysSheet({required this.state});

  @override
  State<_DaysSheet> createState() => _DaysSheetState();
}

class _DaysSheetState extends State<_DaysSheet> {
  late Set<int> days = widget.state.profile.trainDays.toSet();

  @override
  Widget build(BuildContext context) {
    final n = days.length;
    final ok = n >= 2 && n <= 5;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Training days', style: T.display(24)),
          const SizedBox(height: 4),
          Text(
            'Pick 2 to 5 days. Bean builds the right split for it.',
            style: T.body(14, color: C.muted),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var d = 1; d <= 7; d++)
                Chip2(
                  dowName(d),
                  selected: days.contains(d),
                  onTap: () {
                    setState(() {
                      days.contains(d) ? days.remove(d) : days.add(d);
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            n == 2
                ? '2 days: full body A and B.'
                : n == 3
                ? '3 days: full body A, B and C.'
                : n == 4
                ? '4 days: push, legs, pull, core.'
                : n == 5
                ? '5 days: push, legs, pull, core, full body.'
                : 'Choose between 2 and 5 days.',
            style: T.body(13, color: ok ? C.soft : C.coral),
          ),
          const SizedBox(height: 18),
          PillButton(
            'Save',
            onPressed: ok
                ? () async {
                    final list = days.toList()..sort();
                    await widget.state.updateProfile((p) => p.trainDays = list);
                    if (context.mounted) Navigator.pop(context);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
