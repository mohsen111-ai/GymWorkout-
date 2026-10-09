import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/foods.dart';
import 'logic/nutrition.dart';
import 'logic/planner.dart';
import 'logic/progression.dart';
import 'models.dart';

class WeekStats {
  final DateTime start;
  final int workoutsDone;
  final int workoutsPlanned;
  final double? avgKcal;
  final int daysLogged;
  final int proteinDays;
  final double? avgWeight;
  final double? prevAvgWeight;

  const WeekStats({
    required this.start,
    required this.workoutsDone,
    required this.workoutsPlanned,
    required this.avgKcal,
    required this.daysLogged,
    required this.proteinDays,
    required this.avgWeight,
    required this.prevAvgWeight,
  });

  double? get change => (avgWeight != null && prevAvgWeight != null)
      ? avgWeight! - prevAvgWeight!
      : null;
}

class AppState extends ChangeNotifier {
  AppData data;
  final SharedPreferences? _prefs;
  final DateTime Function() clock;

  AppState(this.data, this._prefs, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  static const _key = 'mighty_bean_state_v1';

  static Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    var data = AppData();
    if (raw != null) {
      try {
        data = AppData.decode(raw);
      } catch (_) {
        data = AppData();
      }
    }
    return AppState(data, prefs);
  }

  Future<void> _commit() async {
    notifyListeners();
    await _prefs?.setString(_key, data.encode());
  }

  // ---------------------------------------------------------------- basics

  DateTime get today => dateOnly(clock());
  String get todayKey => dayKey(today);
  bool get hasProfile => data.profile != null;
  Profile get profile => data.profile!;

  double get currentWeight {
    if (data.weights.isEmpty) return profile.startWeight;
    final keys = data.weights.keys.toList()..sort();
    return data.weights[keys.last]!;
  }

  Targets get targets => targetsFor(profile, currentWeight);
  ProgramClock get programClock => clockFor(profile.startDate, today);

  Future<void> createProfile(
    Profile p,
    Map<String, LadderState> ladders,
  ) async {
    data = AppData(profile: p, ladders: ladders, reminders: data.reminders);
    data.weights[dayKey(today)] = p.startWeight;
    if (p.waistCm != null) data.waists[dayKey(today)] = p.waistCm!;
    await _commit();
  }

  Future<void> updateProfile(void Function(Profile p) edit) async {
    edit(profile);
    await _commit();
  }

  Future<void> resetAll() async {
    data = AppData(reminders: data.reminders);
    await _commit();
  }

  // ---------------------------------------------------------------- weight

  Future<void> setWeight(DateTime day, double kg) async {
    data.weights[dayKey(day)] = kg;
    await _commit();
  }

  Future<void> removeWeight(DateTime day) async {
    data.weights.remove(dayKey(day));
    await _commit();
  }

  Future<void> setWaist(DateTime day, double cm) async {
    data.waists[dayKey(day)] = cm;
    await _commit();
  }

  double? weightOn(DateTime day) => data.weights[dayKey(day)];

  /// Average of logged weights in [start, start + 7 days).
  double? averageWeight(DateTime start) {
    final vals = <double>[];
    for (var i = 0; i < 7; i++) {
      final w = data.weights[dayKey(start.add(Duration(days: i)))];
      if (w != null) vals.add(w);
    }
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  // ----------------------------------------------------------------- water

  int waterOn(DateTime day) => data.water[dayKey(day)] ?? 0;

  Future<void> addWater(DateTime day, int ml) async {
    final k = dayKey(day);
    final next = ((data.water[k] ?? 0) + ml).clamp(0, 8000);
    data.water[k] = next;
    await _commit();
  }

  int stepsOn(DateTime day) => data.steps[dayKey(day)] ?? 0;

  Future<void> setSteps(DateTime day, int steps) async {
    data.steps[dayKey(day)] = steps.clamp(0, 100000);
    await _commit();
  }

  // ------------------------------------------------------------------ food

  List<Food> get allFoods => [...data.customFoods, ...builtInFoods];

  Food? foodById(String id) {
    for (final f in allFoods) {
      if (f.id == id) return f;
    }
    return null;
  }

  List<FoodEntry> entriesOn(DateTime day) {
    final k = dayKey(day);
    return data.foods.where((e) => e.day == k).toList();
  }

  double _sum(DateTime day, double Function(FoodEntry) f) =>
      entriesOn(day).fold(0.0, (a, e) => a + f(e));

  double kcalOn(DateTime day) => _sum(day, (e) => e.kcal);
  double proteinOn(DateTime day) => _sum(day, (e) => e.protein);
  double carbsOn(DateTime day) => _sum(day, (e) => e.carbs);
  double fatOn(DateTime day) => _sum(day, (e) => e.fat);

  Future<void> addFood(
    DateTime day,
    Meal meal,
    Food food,
    double servings,
  ) async {
    data.foods.add(
      FoodEntry(
        id: DateTime.now().microsecondsSinceEpoch,
        day: dayKey(day),
        meal: meal,
        food: food,
        servings: servings,
      ),
    );
    await _commit();
  }

  Future<void> removeFood(int id) async {
    data.foods.removeWhere((e) => e.id == id);
    await _commit();
  }

  Future<void> addCustomFood(Food f) async {
    data.customFoods.removeWhere((e) => e.id == f.id);
    data.customFoods.insert(0, f);
    await _commit();
  }

  // -------------------------------------------------------------- workouts

  Workout? workoutOn(DateTime day) => workoutFor(data, day);

  bool workoutDone(DateTime day) {
    final k = dayKey(day);
    return data.workouts.any((w) => w.day == k);
  }

  Future<List<LevelOffer>> completeWorkout(
    Workout w,
    List<List<int>> sets,
    Felt felt,
    int minutes,
  ) async {
    final log = WorkoutLog(
      day: dayKey(w.date),
      title: w.title,
      felt: felt,
      minutes: minutes,
      deload: w.deload,
      exercises: [
        for (var i = 0; i < w.exercises.length; i++)
          ExerciseLog(
            ladderId: w.exercises[i].ladder.id,
            level: w.exercises[i].levelIdx,
            name: w.exercises[i].name,
            isTime: w.exercises[i].isTime,
            target: w.exercises[i].target,
            sets: sets[i],
          ),
      ],
    );
    data.workouts.removeWhere((x) => x.day == log.day);
    data.workouts.add(log);
    final offers = applyWorkout(data, log, w.clock);
    await _commit();
    return offers;
  }

  Future<void> acceptOffer(LevelOffer o) async {
    setLadderLevel(data, o.ladderId, o.toLevel);
    await _commit();
  }

  Future<void> swapLevel(String ladderId, int level) async {
    setLadderLevel(data, ladderId, level);
    await _commit();
  }

  // ------------------------------------------------------------- reminders

  Future<void> saveReminders(ReminderSettings r) async {
    data.reminders = r;
    await _commit();
  }

  // ------------------------------------------------------------- summaries

  bool activeOn(DateTime day) =>
      workoutDone(day) || entriesOn(day).isNotEmpty || weightOn(day) != null;

  /// Consecutive active days ending today (or yesterday if today is empty).
  int get streak {
    var d = today;
    if (!activeOn(d)) d = d.subtract(const Duration(days: 1));
    var n = 0;
    while (activeOn(d)) {
      n++;
      d = d.subtract(const Duration(days: 1));
      if (n > 3650) break;
    }
    return n;
  }

  WeekStats weekStats(DateTime start) {
    final s = weekStartOf(start);
    final target = targets;
    var done = 0;
    var kcalSum = 0.0;
    var logged = 0;
    var proteinDays = 0;
    for (var i = 0; i < 7; i++) {
      final d = s.add(Duration(days: i));
      if (workoutDone(d)) done++;
      if (entriesOn(d).isNotEmpty) {
        logged++;
        kcalSum += kcalOn(d);
        if (proteinOn(d) >= target.protein * 0.9) proteinDays++;
      }
    }
    return WeekStats(
      start: s,
      workoutsDone: done,
      workoutsPlanned: profile.trainDays.length,
      avgKcal: logged == 0 ? null : kcalSum / logged,
      daysLogged: logged,
      proteinDays: proteinDays,
      avgWeight: averageWeight(s),
      prevAvgWeight: averageWeight(s.subtract(const Duration(days: 7))),
    );
  }

  /// Weekly average weights since the program began, oldest first.
  List<(DateTime, double)> weeklyWeights() {
    final out = <(DateTime, double)>[];
    var s = weekStartOf(profile.startDate);
    final end = weekStartOf(today);
    while (!s.isAfter(end)) {
      final a = averageWeight(s);
      if (a != null) out.add((s, a));
      s = s.add(const Duration(days: 7));
    }
    return out;
  }

  /// Weight forecast one week ahead and the goal date, from real data.
  double? get nextWeekEstimate {
    final series = weeklyWeights();
    final pace = profile.paceKg;
    if (series.isEmpty) return null;
    return series.last.$2 - pace;
  }

  DateTime? get goalDateEstimate =>
      goalDate(currentWeight, profile.goalWeight, profile.paceKg, today);

  double get goalProgress {
    final total = profile.startWeight - profile.goalWeight;
    if (total <= 0) return 1;
    return ((profile.startWeight - currentWeight) / total).clamp(0.0, 1.0);
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(s != null, 'AppScope missing');
    return s!.notifier!;
  }
}
