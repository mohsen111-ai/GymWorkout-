# Mighty Bean

A home workout and nutrition tracker for Android. No equipment, no jumping.
Bean, the mascot, guides you through workouts, keeps count of your meals and
protein, tracks your weight and tells you how the week went.

Built with Flutter. Everything is stored on the phone: no account, no server,
works offline.

## Features

- **Plan from your stats.** Calories, protein, carbs, fat and water targets from
  age, height, weight, goal weight and the weekly pace you pick (0.25 to 1.0 kg).
  Targets update as your weight changes and never drop below a safe floor.
- **Workouts that get harder.** 14 exercise "ladders" (push-up, squat, lunge,
  row, plank and more), each a chain of easier-to-harder versions. Bean
  demonstrates every move with an animation, plus do and avoid cues.
  - Sets, reps or hold time, tempo and rest timer.
  - Double progression: hit every set and the target goes up. At the top of the
    range Bean offers the next, harder version.
  - 4-week blocks: three build weeks (one with an extra set), then a lighter
    deload week. Each block changes emphasis (volume, tension, challenge).
  - Eases you back in after a week away. Easier and harder swap on every move.
- **Tracking.** Food log with a starter food list and your own foods, water,
  steps, weight, waist, streaks.
- **Weekly recap.** Workouts done, average calories, protein days, weight change,
  a weight chart with a forecast, and Bean's verdict.
- **Reminders.** Local notifications for workouts, weigh-ins, meals, protein,
  water, the weekly recap and streaks, with quiet hours and a daily cap. They
  skip anything you have already done today.

## Develop

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Build a release APK (signed with the debug key, fine for sideloading):

```sh
flutter build apk --release --split-per-abi
```

For the Play Store, add your own signing config in `android/app/build.gradle.kts`.

## Layout

```
lib/
  data/       exercise ladders, starter foods
  logic/      nutrition maths, weekly planner, progression rules
  screens/    one file per screen
  widgets/    Bean (CustomPainter mascot), rings, bars, dialogs
  models.dart everything that is saved, as one JSON blob
  state.dart  AppState (ChangeNotifier) and the AppScope inherited widget
  notifications.dart  plans the next 10 days of reminders
test/         unit tests for the logic and widget tests for the main flows
```

Not medical advice. If you have a health condition or injury, check with a
doctor before starting.
