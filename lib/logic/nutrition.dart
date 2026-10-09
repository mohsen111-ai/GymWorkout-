import 'dart:math';

import '../models.dart';

/// Roughly 7,700 kcal of deficit is one kilogram of body fat.
const double kcalPerKg = 7700;

class Targets {
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;
  final double waterL;
  final int steps;
  final int deficit;

  const Targets({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.waterL,
    required this.steps,
    required this.deficit,
  });
}

/// Mifflin-St Jeor resting energy use.
double bmr(Profile p, double weightKg) {
  final base = 10 * weightKg + 6.25 * p.heightCm - 5 * p.age;
  return p.sex == Sex.male ? base + 5 : base - 161;
}

double maintenanceKcal(Profile p, double weightKg) =>
    bmr(p, weightKg) * p.activity;

int _round(double v, int step) => (v / step).round() * step;

int kcalFloor(Profile p) => p.sex == Sex.male ? 1700 : 1400;

Targets targetsFor(Profile p, double weightKg) {
  final maintenance = maintenanceKcal(p, weightKg);
  final losing = weightKg > p.goalWeight + 0.2;
  var deficit = losing ? p.paceKg * kcalPerKg / 7 : 0.0;
  var kcal = maintenance - deficit;
  if (kcal < kcalFloor(p)) {
    kcal = kcalFloor(p).toDouble();
    deficit = max(0, maintenance - kcal);
  }
  final kcalRounded = _round(kcal, 10);
  final protein = _round((1.8 * weightKg).clamp(90.0, 220.0), 5);
  final fat = _round((0.8 * weightKg).clamp(45.0, 110.0), 5);
  final carbs = max(80, _round((kcalRounded - protein * 4 - fat * 9) / 4, 5));
  return Targets(
    kcal: kcalRounded,
    protein: protein,
    carbs: carbs,
    fat: fat,
    waterL: (_round(weightKg * 33, 100) / 1000),
    steps: p.stepGoal,
    deficit: deficit.round(),
  );
}

/// Rough body-fat estimate from BMI (Deurenberg). Only a guide.
double estimatedBodyFat(Profile p, double weightKg) {
  final h = p.heightCm / 100;
  final bmi = weightKg / (h * h);
  final sex = p.sex == Sex.male ? 1 : 0;
  return (1.2 * bmi + 0.23 * p.age - 10.8 * sex - 5.4).clamp(5.0, 60.0);
}

double bmiOf(Profile p, double weightKg) {
  final h = p.heightCm / 100;
  return weightKg / (h * h);
}

/// Lowest weight we will accept as a goal (BMI 18.5).
double minGoalWeight(Profile p) {
  final h = p.heightCm / 100;
  return 18.5 * h * h;
}

/// Expected loss per week from the calories actually eaten.
double expectedWeeklyLoss(double maintenance, double avgKcal) =>
    (maintenance - avgKcal) * 7 / kcalPerKg;

DateTime? goalDate(double current, double goal, double pace, DateTime from) {
  if (current <= goal || pace <= 0) return null;
  final weeks = (current - goal) / pace;
  return from.add(Duration(days: (weeks * 7).round()));
}

String monthWord(DateTime d) {
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final part = d.day <= 10 ? 'early' : (d.day <= 20 ? 'mid' : 'late');
  return '$part ${m[d.month - 1]}';
}
