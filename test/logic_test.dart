import 'package:flutter_test/flutter_test.dart';
import 'package:mighty_bean/data/ladders.dart';
import 'package:mighty_bean/logic/nutrition.dart';
import 'package:mighty_bean/logic/planner.dart';
import 'package:mighty_bean/logic/progression.dart';
import 'package:mighty_bean/models.dart';

Profile _p({Sex sex = Sex.male, double w = 85, double goal = 75}) => Profile(
  sex: sex,
  age: 19,
  heightCm: 175,
  startWeight: w,
  goalWeight: goal,
  startDate: DateTime(2026, 9, 21),
);

AppData _data() =>
    AppData(profile: _p(), ladders: initialLadders(pushups: 3, active: false));

void main() {
  group('nutrition', () {
    test('plan for the 19 year old, 175 cm, 85 kg male', () {
      final t = targetsFor(_p(), 85);
      expect(t.kcal, inInclusiveRange(1950, 2100));
      expect(t.protein, inInclusiveRange(145, 160));
      expect(t.deficit, inInclusiveRange(500, 600));
      expect(t.waterL, closeTo(2.8, 0.15));
      expect(t.carbs, greaterThan(150));
    });

    test('never goes below the calorie floor', () {
      final p = _p(w: 60, goal: 55)..paceKg = 1.0;
      final t = targetsFor(p, 60);
      expect(t.kcal, greaterThanOrEqualTo(kcalFloor(p)));
    });

    test('maintenance when already at goal', () {
      final t = targetsFor(_p(w: 75, goal: 75), 75);
      expect(t.deficit, 0);
    });

    test('goal date and healthy minimum weight', () {
      final d = goalDate(85, 75, 0.5, DateTime(2026, 10, 9))!;
      expect(d.difference(DateTime(2026, 10, 9)).inDays, 140);
      expect(minGoalWeight(_p()), closeTo(56.7, 0.2));
    });
  });

  group('planner', () {
    test('program clock: three build weeks then a deload', () {
      final start = DateTime(2026, 9, 21);
      expect(clockFor(start, DateTime(2026, 9, 21)).weekInBlock, 0);
      expect(clockFor(start, DateTime(2026, 10, 9)).weekInBlock, 2);
      final d = clockFor(start, DateTime(2026, 10, 14));
      expect(d.deload, true);
      expect(clockFor(start, DateTime(2026, 10, 19)).block, 1);
      expect(
        clockFor(start, DateTime(2026, 10, 19)).emphasis,
        Emphasis.tension,
      );
    });

    test('4 training days map to push, legs, pull, core', () {
      final d = _data();
      // Mon 5 Oct 2026
      expect(workoutFor(d, DateTime(2026, 10, 5))!.title, 'Push');
      expect(workoutFor(d, DateTime(2026, 10, 6))!.title, 'Legs and glutes');
      expect(workoutFor(d, DateTime(2026, 10, 7)), isNull); // Wed rest
      expect(workoutFor(d, DateTime(2026, 10, 8))!.title, 'Pull and back');
      expect(
        workoutFor(d, DateTime(2026, 10, 9))!.title,
        'Core and conditioning',
      );
    });

    test('build week 3 adds a set, deload removes one', () {
      final d = _data();
      final wk3 = workoutFor(d, DateTime(2026, 10, 5))!; // week index 2
      expect(wk3.clock.weekInBlock, 2);
      expect(wk3.exercises.first.sets, 5);
      final deload = workoutFor(d, DateTime(2026, 10, 12))!;
      expect(deload.deload, true);
      expect(deload.exercises.first.sets, 3);
    });

    test('eases back in after a long break', () {
      final d = _data()
        ..workouts.add(
          WorkoutLog(
            day: '2026-09-25',
            title: 'x',
            felt: Felt.ok,
            minutes: 30,
            deload: false,
            exercises: [],
          ),
        );
      expect(workoutFor(d, DateTime(2026, 10, 5))!.easedBack, true);
    });

    test('every ladder level has form cues and sane ranges', () {
      for (final l in ladders) {
        for (final lv in l.levels) {
          expect(lv.doThis, isNotEmpty, reason: lv.name);
          expect(lv.avoid, isNotEmpty, reason: lv.name);
          expect(lv.max, greaterThan(lv.min), reason: lv.name);
        }
      }
    });
  });

  group('progression', () {
    ExerciseLog log(Level lv, int target, List<int> sets, int idx) =>
        ExerciseLog(
          ladderId: 'squat',
          level: idx,
          name: lv.name,
          isTime: lv.isTime,
          target: target,
          sets: sets,
        );

    WorkoutLog wl(Felt f, ExerciseLog e) => WorkoutLog(
      day: '2026-10-05',
      title: 't',
      felt: f,
      minutes: 30,
      deload: false,
      exercises: [e],
    );

    const build = ProgramClock(0, 0, 0);

    test('hitting every set raises the rep target', () {
      final d = _data();
      final lv = ladderById('squat').levels[0];
      final offers = applyWorkout(
        d,
        wl(Felt.ok, log(lv, 10, [10, 10, 10], 0)),
        build,
      );
      expect(offers, isEmpty);
      expect(d.ladders['squat']!.target, 12);
    });

    test('feeling it was easy doubles the step', () {
      final d = _data();
      final lv = ladderById('squat').levels[0];
      applyWorkout(d, wl(Felt.easy, log(lv, 10, [10, 10, 10], 0)), build);
      expect(d.ladders['squat']!.target, 14);
    });

    test('top of the range offers a harder version', () {
      final d = _data();
      final lv = ladderById('squat').levels[0];
      final offers = applyWorkout(
        d,
        wl(Felt.ok, log(lv, 20, [20, 20, 20], 0)),
        build,
      );
      expect(offers, hasLength(1));
      expect(offers.single.to.name, 'Squat');
      setLadderLevel(d, 'squat', offers.single.toLevel);
      expect(d.ladders['squat']!.level, 1);
      expect(d.ladders['squat']!.target, 10);
    });

    test('missing reps twice lowers the target', () {
      final d = _data();
      final lv = ladderById('squat').levels[0];
      applyWorkout(d, wl(Felt.ok, log(lv, 14, [14, 10, 9], 0)), build);
      expect(d.ladders['squat']!.fails, 1);
      applyWorkout(d, wl(Felt.ok, log(lv, 14, [14, 10, 9], 0)), build);
      expect(d.ladders['squat']!.target, 12);
    });

    test('deload weeks do not change targets', () {
      final d = _data();
      final lv = ladderById('squat').levels[0];
      applyWorkout(
        d,
        wl(Felt.ok, log(lv, 10, [10, 10, 10], 0)),
        const ProgramClock(3, 0, 3),
      );
      expect(d.ladders['squat']!.target, 10);
    });
  });

  test('app data survives a save and load', () {
    final d = _data()
      ..weights['2026-10-05'] = 84.6
      ..water['2026-10-05'] = 750;
    final back = AppData.decode(d.encode());
    expect(back.profile!.heightCm, 175);
    expect(back.weights['2026-10-05'], 84.6);
    expect(back.ladders['pushup']!.level, 1);
  });
}
