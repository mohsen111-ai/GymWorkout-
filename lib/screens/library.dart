import 'package:flutter/material.dart';

import '../data/ladders.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'guide.dart';

String groupName(Group g) => switch (g) {
  Group.push => 'Push',
  Group.pull => 'Pull',
  Group.legs => 'Legs and glutes',
  Group.core => 'Core',
};

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                const BackCircle(),
                const SizedBox(width: 12),
                Text('Exercise library', style: T.display(26)),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 56),
              child: Text(
                'Every move has an easier and a harder version.',
                style: T.body(14, color: C.muted),
              ),
            ),
            for (final g in Group.values) ...[
              const SizedBox(height: 22),
              Label(groupName(g)),
              const SizedBox(height: 10),
              for (final l in ladders.where((x) => x.group == g)) ...[
                () {
                  final st = s.data.ladders[l.id];
                  final idx = (st?.level ?? 0).clamp(0, l.levels.length - 1);
                  return Padding(
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
                                GuideScreen(ladderId: l.id, levelIdx: idx),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.levels[idx].name,
                                      style: T.body(
                                        16,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${l.muscles} · level ${idx + 1} of ${l.levels.length}',
                                      style: T.body(13, color: C.muted),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: C.muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }(),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
