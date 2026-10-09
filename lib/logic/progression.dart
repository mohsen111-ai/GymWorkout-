import 'dart:math';

import '../data/ladders.dart';
import '../models.dart';
import 'planner.dart';

/// A harder version of a move that Bean suggests once you've mastered one.
class LevelOffer {
  final String ladderId;
  final int fromLevel;
  final int toLevel;
  final int reps;

  const LevelOffer(this.ladderId, this.fromLevel, this.toLevel, this.reps);

  Ladder get ladder => ladderById(ladderId);
  Level get from => ladder.levels[fromLevel];
  Level get to => ladder.levels[toLevel];
}

/// Starting levels from a quick fitness check at sign-up.
Map<String, LadderState> initialLadders({
  required int pushups,
  required bool active,
}) {
  final out = <String, LadderState>{};
  for (final l in ladders) {
    var level = active ? 1 : 0;
    if (l.id == 'pushup') {
      level = pushups <= 0 ? 0 : (pushups <= 5 ? 1 : (pushups <= 12 ? 2 : 3));
    }
    level = min(level, l.levels.length - 1);
    out[l.id] = LadderState(level: level, target: l.levels[level].min);
  }
  return out;
}

/// Updates targets from a finished session and returns level-up offers.
List<LevelOffer> applyWorkout(AppData d, WorkoutLog log, ProgramClock clock) {
  final offers = <LevelOffer>[];
  for (final ex in log.exercises) {
    final ladder = ladderById(ex.ladderId);
    final state =
        d.ladders[ladder.id] ??
        LadderState(level: 0, target: ladder.levels[0].min);
    d.ladders[ladder.id] = state;
    if (ex.level != state.level) continue;
    if (clock.deload) continue;
    final lv = ladder.levels[state.level];
    final cap = effectiveCap(lv, clock.emphasis);
    final done = ex.sets.isNotEmpty && ex.sets.every((r) => r >= ex.target);
    if (done) {
      state.fails = 0;
      if (log.felt == Felt.hard) continue;
      if (ex.target >= cap) {
        if (state.level + 1 < ladder.levels.length) {
          offers.add(
            LevelOffer(ladder.id, state.level, state.level + 1, ex.target),
          );
        }
      } else {
        final bump = lv.step * (log.felt == Felt.easy ? 2 : 1);
        state.target = min(cap, ex.target + bump);
      }
    } else {
      state.fails += 1;
      if (state.fails >= 2) {
        state.target = max(lv.min, ex.target - lv.step);
        state.fails = 0;
      } else {
        state.target = max(lv.min, ex.target);
      }
    }
  }
  return offers;
}

void setLadderLevel(AppData d, String ladderId, int level) {
  final ladder = ladderById(ladderId);
  final l = level.clamp(0, ladder.levels.length - 1);
  d.ladders[ladderId] = LadderState(
    level: l,
    target: ladder.levels[l].min,
    fails: 0,
  );
}
