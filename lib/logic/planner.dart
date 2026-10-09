import 'dart:math';

import '../data/ladders.dart';
import '../models.dart';

enum Emphasis { volume, tension, challenge }

String emphasisName(Emphasis e) => switch (e) {
  Emphasis.volume => 'Volume',
  Emphasis.tension => 'Tension',
  Emphasis.challenge => 'Challenge',
};

String emphasisBlurb(Emphasis e) => switch (e) {
  Emphasis.volume => 'More reps with a steady tempo.',
  Emphasis.tension => 'Slower lowering and pauses. Fewer, harder reps.',
  Emphasis.challenge => 'Shorter rests and harder versions.',
};

/// Where you are in the 4-week blocks: three build weeks, then a lighter week.
class ProgramClock {
  final int weekIndex;
  final int block;
  final int weekInBlock;

  const ProgramClock(this.weekIndex, this.block, this.weekInBlock);

  bool get deload => weekInBlock == 3;
  int get weekNumber => weekInBlock + 1;
  Emphasis get emphasis => Emphasis.values[block % 3];
}

ProgramClock clockFor(DateTime start, DateTime today) {
  final days = max(0, dateOnly(today).difference(dateOnly(start)).inDays);
  final week = days ~/ 7;
  return ProgramClock(week, week ~/ 4, week % 4);
}

class SlotSpec {
  final String ladder;
  final int sets;
  const SlotSpec(this.ladder, this.sets);
}

class SessionTemplate {
  final String title;
  final String subtitle;
  final List<SlotSpec> slots;
  const SessionTemplate(this.title, this.subtitle, this.slots);
}

const _push = SessionTemplate('Push', 'Chest, shoulders, triceps', [
  SlotSpec('pushup', 4),
  SlotSpec('pike', 3),
  SlotSpec('dip', 3),
  SlotSpec('plank', 2),
]);
const _legs = SessionTemplate('Legs and glutes', 'Squats, lunges, bridges', [
  SlotSpec('squat', 4),
  SlotSpec('lunge', 3),
  SlotSpec('bridge', 3),
  SlotSpec('calf', 3),
  SlotSpec('wallsit', 2),
]);
const _pull = SessionTemplate('Pull and back', 'Rows, back raises, core', [
  SlotSpec('row', 4),
  SlotSpec('rsnow', 3),
  SlotSpec('deadbug', 3),
  SlotSpec('sideplank', 2),
]);
const _core = SessionTemplate(
  'Core and conditioning',
  'Planks, bird dogs, bridges',
  [
    SlotSpec('plank', 3),
    SlotSpec('birddog', 3),
    SlotSpec('deadbug', 3),
    SlotSpec('bridge', 3),
    SlotSpec('pushup', 3),
  ],
);
const _fullA = SessionTemplate('Full body A', 'Squat, push, row, plank', [
  SlotSpec('squat', 3),
  SlotSpec('pushup', 3),
  SlotSpec('row', 3),
  SlotSpec('plank', 3),
]);
const _fullB = SessionTemplate('Full body B', 'Lunge, press, back, glutes', [
  SlotSpec('lunge', 3),
  SlotSpec('pike', 3),
  SlotSpec('rsnow', 3),
  SlotSpec('bridge', 3),
]);
const _fullC = SessionTemplate('Full body C', 'Dips, rows, legs, core', [
  SlotSpec('wallsit', 2),
  SlotSpec('dip', 3),
  SlotSpec('row', 3),
  SlotSpec('deadbug', 3),
  SlotSpec('calf', 2),
]);
const _fullD = SessionTemplate('Full body', 'Squat, push, row, bridge, plank', [
  SlotSpec('squat', 3),
  SlotSpec('pushup', 3),
  SlotSpec('row', 3),
  SlotSpec('bridge', 3),
  SlotSpec('plank', 3),
]);

List<SessionTemplate> templatesFor(int daysPerWeek) {
  switch (daysPerWeek) {
    case <= 2:
      return [_fullA, _fullB];
    case 3:
      return [_fullA, _fullB, _fullC];
    case 4:
      return [_push, _legs, _pull, _core];
    default:
      return [_push, _legs, _pull, _core, _fullD];
  }
}

List<int> defaultTrainDays(int n) => switch (n) {
  <= 2 => [2, 5],
  3 => [1, 3, 5],
  4 => [1, 2, 4, 5],
  _ => [1, 2, 3, 5, 6],
};

class PlannedExercise {
  final Ladder ladder;
  final int levelIdx;
  final int sets;
  final int target;
  final int restSec;
  final int down;
  final int pause;
  final int up;

  const PlannedExercise({
    required this.ladder,
    required this.levelIdx,
    required this.sets,
    required this.target,
    required this.restSec,
    required this.down,
    required this.pause,
    required this.up,
  });

  Level get level => ladder.levels[levelIdx];
  bool get isTime => level.isTime;
  String get name => level.name;

  /// "4 x 12 reps" or "3 x 30 s"
  String get prescription {
    final side = ladder.perSide ? ' each side' : '';
    return isTime ? '$sets x $target s$side' : '$sets x $target reps$side';
  }

  String get tempoText => isTime
      ? 'Hold steady'
      : 'Lower $down s'
            '${pause > 0 ? ', pause $pause s' : ''}, rise $up s';

  int get secondsEstimate {
    final work = isTime ? target : target * (down + pause + up);
    final mult = ladder.perSide ? 2 : 1;
    return sets * (work * mult + restSec);
  }
}

class Workout {
  final DateTime date;
  final SessionTemplate template;
  final List<PlannedExercise> exercises;
  final ProgramClock clock;
  final bool easedBack;

  const Workout({
    required this.date,
    required this.template,
    required this.exercises,
    required this.clock,
    required this.easedBack,
  });

  String get title => template.title;
  bool get deload => clock.deload;

  int get minutes {
    final secs = exercises.fold<int>(0, (a, e) => a + e.secondsEstimate);
    return ((secs + 240) / 60 / 5).round() * 5; // includes a 4 minute warm-up
  }
}

LadderState ladderState(AppData d, Ladder l) {
  final s = d.ladders[l.id];
  if (s != null) return s;
  return LadderState(level: 0, target: l.levels[0].min);
}

int effectiveCap(Level lv, Emphasis e) {
  if (lv.isTime) return lv.max;
  return e == Emphasis.tension ? max(lv.min, lv.max - 3) : lv.max;
}

(int, int, int) tempoFor(Emphasis e) => switch (e) {
  Emphasis.volume => (2, 0, 1),
  Emphasis.tension => (4, 1, 1),
  Emphasis.challenge => (2, 1, 1),
};

int restFor(Emphasis e, bool deload) {
  final base = switch (e) {
    Emphasis.volume => 45,
    Emphasis.tension => 60,
    Emphasis.challenge => 30,
  };
  return deload ? base + 15 : base;
}

/// The weekday sessions in the order they run, e.g. Mon Push, Tue Legs...
SessionTemplate? templateForDate(Profile p, DateTime date) {
  final days = [...p.trainDays]..sort();
  final i = days.indexOf(date.weekday);
  if (i < 0) return null;
  final t = templatesFor(days.length);
  return t[min(i, t.length - 1)];
}

/// Whether the last workout was more than a week ago, so we ease back in.
bool needsEaseBack(AppData d, DateTime date) {
  if (d.workouts.isEmpty) return false;
  final last = d.workouts
      .map((w) => parseDay(w.day))
      .reduce((a, b) => a.isAfter(b) ? a : b);
  return dateOnly(date).difference(last).inDays > 7;
}

Workout? workoutFor(AppData d, DateTime date) {
  final p = d.profile;
  if (p == null) return null;
  final template = templateForDate(p, date);
  if (template == null) return null;
  final clock = clockFor(p.startDate, date);
  final eased = needsEaseBack(d, date);
  final (down, pause, up) = tempoFor(clock.emphasis);
  final exercises = <PlannedExercise>[];
  for (final slot in template.slots) {
    final ladder = ladderById(slot.ladder);
    final state = ladderState(d, ladder);
    final levelIdx = state.level.clamp(0, ladder.levels.length - 1);
    final lv = ladder.levels[levelIdx];
    var sets = slot.sets;
    if (clock.weekInBlock == 2) sets = min(5, sets + 1);
    if (clock.deload) sets = max(2, sets - 1);
    if (eased) sets = max(2, sets - 1);
    final cap = effectiveCap(lv, clock.emphasis);
    var target = state.target.clamp(lv.min, cap);
    if (clock.deload || eased) target = lv.min;
    exercises.add(
      PlannedExercise(
        ladder: ladder,
        levelIdx: levelIdx,
        sets: sets,
        target: target,
        restSec: restFor(clock.emphasis, clock.deload),
        down: down,
        pause: pause,
        up: up,
      ),
    );
  }
  return Workout(
    date: dateOnly(date),
    template: template,
    exercises: exercises,
    clock: clock,
    easedBack: eased,
  );
}
