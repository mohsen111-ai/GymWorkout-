import 'package:flutter/material.dart';

import '../data/ladders.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/bean.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';

class GuideScreen extends StatefulWidget {
  final String ladderId;
  final int levelIdx;

  const GuideScreen({
    super.key,
    required this.ladderId,
    required this.levelIdx,
  });

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  late int idx = widget.levelIdx;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final ladder = ladderById(widget.ladderId);
    final lv = ladder.levels[idx];
    final current = (s.data.ladders[ladder.id]?.level ?? 0).clamp(
      0,
      ladder.levels.length - 1,
    );
    final easier = idx > 0 ? ladder.levels[idx - 1] : null;
    final harder = idx + 1 < ladder.levels.length
        ? ladder.levels[idx + 1]
        : null;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                const BackCircle(),
                const SizedBox(width: 12),
                Expanded(child: Text(lv.name, style: T.display(24))),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: idx == current ? C.lime : C.pot,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Level ${idx + 1}',
                    style: T.body(
                      12,
                      color: idx == current ? C.ink : C.muted,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Panel(
              radius: 28,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                children: [
                  SizedBox(
                    height: 150,
                    child: Center(
                      child: BeanDemo(motion: lv.motion, size: 100),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lv.isTime
                        ? 'Hold steady and breathe'
                        : 'Lower 3 s · pause · rise 1 s',
                    style: T.body(13, color: C.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _stat('Sets', '3 to 4')),
                const SizedBox(width: 8),
                Expanded(
                  child: _stat(
                    lv.isTime ? 'Hold' : 'Reps',
                    '${lv.min} to ${lv.max}${lv.isTime ? ' s' : ''}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _stat('Rest', '30 to 60 s')),
              ],
            ),
            if (ladder.perSide)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Do the reps on each side.',
                  style: T.body(13, color: C.muted),
                ),
              ),
            const SizedBox(height: 12),
            Panel(
              radius: 22,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Label('Do this', color: C.lime),
                  const SizedBox(height: 10),
                  for (final t in lv.doThis) _bullet(t, true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Panel(
              radius: 22,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Label('Avoid', color: C.coral),
                  const SizedBox(height: 10),
                  for (final t in lv.avoid) _bullet(t, false),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Works: ${ladder.muscles}.',
                style: T.body(13, color: C.muted),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: PillButton(
                    easier == null
                        ? 'Easiest version'
                        : 'Easier: ${easier.name}',
                    height: 60,
                    fontSize: 13,
                    maxLines: 2,
                    outlined: true,
                    color: C.text,
                    onPressed: easier == null
                        ? null
                        : () => setState(() => idx--),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PillButton(
                    harder == null
                        ? 'Hardest version'
                        : 'Harder: ${harder.name}',
                    height: 60,
                    fontSize: 13,
                    maxLines: 2,
                    outlined: true,
                    color: C.lime,
                    onPressed: harder == null
                        ? null
                        : () => setState(() => idx++),
                  ),
                ),
              ],
            ),
            if (idx != current) ...[
              const SizedBox(height: 12),
              PillButton(
                'Use this version in my workouts',
                fontSize: 16,
                height: 56,
                onPressed: () async {
                  await s.swapLevel(ladder.id, idx);
                  if (context.mounted) {
                    toast(context, '${lv.name} is now in your plan');
                    setState(() {});
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Panel(
    radius: 18,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: T.body(12, color: C.muted)),
        const SizedBox(height: 2),
        Text(value, style: T.display(17)),
      ],
    ),
  );

  Widget _bullet(String text, bool good) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          good ? Icons.check_rounded : Icons.close_rounded,
          size: 20,
          color: good ? C.lime : C.coral,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: T.body(14))),
      ],
    ),
  );
}
