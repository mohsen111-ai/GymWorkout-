import 'dart:convert';

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime parseDay(String k) {
  final p = k.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

/// Monday of the week containing [d].
DateTime weekStartOf(DateTime d) {
  final o = dateOnly(d);
  return DateTime(o.year, o.month, o.day - (o.weekday - 1));
}

enum Sex { male, female }

enum Meal { breakfast, lunch, dinner, snack }

String mealName(Meal m) => switch (m) {
  Meal.breakfast => 'Breakfast',
  Meal.lunch => 'Lunch',
  Meal.dinner => 'Dinner',
  Meal.snack => 'Snack',
};

class Profile {
  Sex sex;
  int age;
  double heightCm;
  double startWeight;
  double goalWeight;
  double paceKg;
  double activity;
  List<int> trainDays;
  DateTime startDate;
  double? waistCm;
  double? goalWaistCm;
  int stepGoal;

  Profile({
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.startWeight,
    required this.goalWeight,
    this.paceKg = 0.5,
    this.activity = 1.4,
    this.trainDays = const [1, 2, 4, 5],
    DateTime? startDate,
    this.waistCm,
    this.goalWaistCm,
    this.stepGoal = 8000,
  }) : startDate = startDate ?? dateOnly(DateTime.now());

  Map<String, dynamic> toJson() => {
    'sex': sex.name,
    'age': age,
    'heightCm': heightCm,
    'startWeight': startWeight,
    'goalWeight': goalWeight,
    'paceKg': paceKg,
    'activity': activity,
    'trainDays': trainDays,
    'startDate': dayKey(startDate),
    'waistCm': waistCm,
    'goalWaistCm': goalWaistCm,
    'stepGoal': stepGoal,
  };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    sex: Sex.values.byName(j['sex'] as String),
    age: j['age'] as int,
    heightCm: (j['heightCm'] as num).toDouble(),
    startWeight: (j['startWeight'] as num).toDouble(),
    goalWeight: (j['goalWeight'] as num).toDouble(),
    paceKg: (j['paceKg'] as num).toDouble(),
    activity: (j['activity'] as num).toDouble(),
    trainDays: (j['trainDays'] as List).cast<int>(),
    startDate: parseDay(j['startDate'] as String),
    waistCm: (j['waistCm'] as num?)?.toDouble(),
    goalWaistCm: (j['goalWaistCm'] as num?)?.toDouble(),
    stepGoal: j['stepGoal'] as int? ?? 8000,
  );
}

class Food {
  final String id;
  final String name;
  final String serving;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  const Food({
    required this.id,
    required this.name,
    required this.serving,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'serving': serving,
    'kcal': kcal,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };

  factory Food.fromJson(Map<String, dynamic> j) => Food(
    id: j['id'] as String,
    name: j['name'] as String,
    serving: j['serving'] as String,
    kcal: (j['kcal'] as num).toDouble(),
    protein: (j['protein'] as num).toDouble(),
    carbs: (j['carbs'] as num).toDouble(),
    fat: (j['fat'] as num).toDouble(),
  );
}

class FoodEntry {
  final int id;
  final String day;
  final Meal meal;
  final Food food;
  final double servings;

  FoodEntry({
    required this.id,
    required this.day,
    required this.meal,
    required this.food,
    required this.servings,
  });

  double get kcal => food.kcal * servings;
  double get protein => food.protein * servings;
  double get carbs => food.carbs * servings;
  double get fat => food.fat * servings;

  Map<String, dynamic> toJson() => {
    'id': id,
    'day': day,
    'meal': meal.name,
    'food': food.toJson(),
    'servings': servings,
  };

  factory FoodEntry.fromJson(Map<String, dynamic> j) => FoodEntry(
    id: j['id'] as int,
    day: j['day'] as String,
    meal: Meal.values.byName(j['meal'] as String),
    food: Food.fromJson(j['food'] as Map<String, dynamic>),
    servings: (j['servings'] as num).toDouble(),
  );
}

/// How far a ladder (a chain of harder and harder versions of one move) has got.
class LadderState {
  int level;
  int target;
  int fails;

  LadderState({this.level = 0, this.target = 0, this.fails = 0});

  Map<String, dynamic> toJson() => {
    'level': level,
    'target': target,
    'fails': fails,
  };

  factory LadderState.fromJson(Map<String, dynamic> j) => LadderState(
    level: j['level'] as int,
    target: j['target'] as int,
    fails: j['fails'] as int? ?? 0,
  );
}

class ExerciseLog {
  final String ladderId;
  final int level;
  final String name;
  final bool isTime;
  final int target;
  final List<int> sets;

  ExerciseLog({
    required this.ladderId,
    required this.level,
    required this.name,
    required this.isTime,
    required this.target,
    required this.sets,
  });

  Map<String, dynamic> toJson() => {
    'ladderId': ladderId,
    'level': level,
    'name': name,
    'isTime': isTime,
    'target': target,
    'sets': sets,
  };

  factory ExerciseLog.fromJson(Map<String, dynamic> j) => ExerciseLog(
    ladderId: j['ladderId'] as String,
    level: j['level'] as int,
    name: j['name'] as String,
    isTime: j['isTime'] as bool,
    target: j['target'] as int,
    sets: (j['sets'] as List).cast<int>(),
  );
}

enum Felt { easy, ok, hard }

class WorkoutLog {
  final String day;
  final String title;
  final Felt felt;
  final int minutes;
  final bool deload;
  final List<ExerciseLog> exercises;

  WorkoutLog({
    required this.day,
    required this.title,
    required this.felt,
    required this.minutes,
    required this.deload,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
    'day': day,
    'title': title,
    'felt': felt.name,
    'minutes': minutes,
    'deload': deload,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  factory WorkoutLog.fromJson(Map<String, dynamic> j) => WorkoutLog(
    day: j['day'] as String,
    title: j['title'] as String,
    felt: Felt.values.byName(j['felt'] as String),
    minutes: j['minutes'] as int,
    deload: j['deload'] as bool? ?? false,
    exercises: (j['exercises'] as List)
        .map((e) => ExerciseLog.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class ReminderSettings {
  bool workout;
  int workoutMinutes;
  bool weighIn;
  int weighInMinutes;
  bool meals;
  bool protein;
  int proteinMinutes;
  bool water;
  bool weekly;
  bool streak;
  int quietStartMinutes;
  int quietEndMinutes;
  int maxPerDay;

  ReminderSettings({
    this.workout = true,
    this.workoutMinutes = 17 * 60 + 30,
    this.weighIn = true,
    this.weighInMinutes = 7 * 60 + 30,
    this.meals = true,
    this.protein = true,
    this.proteinMinutes = 20 * 60 + 30,
    this.water = true,
    this.weekly = true,
    this.streak = true,
    this.quietStartMinutes = 22 * 60,
    this.quietEndMinutes = 7 * 60,
    this.maxPerDay = 4,
  });

  Map<String, dynamic> toJson() => {
    'workout': workout,
    'workoutMinutes': workoutMinutes,
    'weighIn': weighIn,
    'weighInMinutes': weighInMinutes,
    'meals': meals,
    'protein': protein,
    'proteinMinutes': proteinMinutes,
    'water': water,
    'weekly': weekly,
    'streak': streak,
    'quietStartMinutes': quietStartMinutes,
    'quietEndMinutes': quietEndMinutes,
    'maxPerDay': maxPerDay,
  };

  factory ReminderSettings.fromJson(Map<String, dynamic> j) {
    final d = ReminderSettings();
    return ReminderSettings(
      workout: j['workout'] as bool? ?? d.workout,
      workoutMinutes: j['workoutMinutes'] as int? ?? d.workoutMinutes,
      weighIn: j['weighIn'] as bool? ?? d.weighIn,
      weighInMinutes: j['weighInMinutes'] as int? ?? d.weighInMinutes,
      meals: j['meals'] as bool? ?? d.meals,
      protein: j['protein'] as bool? ?? d.protein,
      proteinMinutes: j['proteinMinutes'] as int? ?? d.proteinMinutes,
      water: j['water'] as bool? ?? d.water,
      weekly: j['weekly'] as bool? ?? d.weekly,
      streak: j['streak'] as bool? ?? d.streak,
      quietStartMinutes: j['quietStartMinutes'] as int? ?? d.quietStartMinutes,
      quietEndMinutes: j['quietEndMinutes'] as int? ?? d.quietEndMinutes,
      maxPerDay: j['maxPerDay'] as int? ?? d.maxPerDay,
    );
  }
}

/// Everything the app stores, saved as one JSON blob on the phone.
class AppData {
  Profile? profile;
  Map<String, double> weights;
  Map<String, double> waists;
  Map<String, int> water;
  Map<String, int> steps;
  List<FoodEntry> foods;
  List<Food> customFoods;
  List<WorkoutLog> workouts;
  Map<String, LadderState> ladders;
  ReminderSettings reminders;

  AppData({
    this.profile,
    Map<String, double>? weights,
    Map<String, double>? waists,
    Map<String, int>? water,
    Map<String, int>? steps,
    List<FoodEntry>? foods,
    List<Food>? customFoods,
    List<WorkoutLog>? workouts,
    Map<String, LadderState>? ladders,
    ReminderSettings? reminders,
  }) : weights = weights ?? {},
       waists = waists ?? {},
       water = water ?? {},
       steps = steps ?? {},
       foods = foods ?? [],
       customFoods = customFoods ?? [],
       workouts = workouts ?? [],
       ladders = ladders ?? {},
       reminders = reminders ?? ReminderSettings();

  Map<String, dynamic> toJson() => {
    'v': 1,
    'profile': profile?.toJson(),
    'weights': weights,
    'waists': waists,
    'water': water,
    'steps': steps,
    'foods': foods.map((e) => e.toJson()).toList(),
    'customFoods': customFoods.map((e) => e.toJson()).toList(),
    'workouts': workouts.map((e) => e.toJson()).toList(),
    'ladders': ladders.map((k, v) => MapEntry(k, v.toJson())),
    'reminders': reminders.toJson(),
  };

  String encode() => jsonEncode(toJson());

  factory AppData.decode(String s) {
    final j = jsonDecode(s) as Map<String, dynamic>;
    return AppData(
      profile: j['profile'] == null
          ? null
          : Profile.fromJson(j['profile'] as Map<String, dynamic>),
      weights: (j['weights'] as Map? ?? {}).map(
        (k, v) => MapEntry(k as String, (v as num).toDouble()),
      ),
      waists: (j['waists'] as Map? ?? {}).map(
        (k, v) => MapEntry(k as String, (v as num).toDouble()),
      ),
      water: (j['water'] as Map? ?? {}).map(
        (k, v) => MapEntry(k as String, v as int),
      ),
      steps: (j['steps'] as Map? ?? {}).map(
        (k, v) => MapEntry(k as String, v as int),
      ),
      foods: (j['foods'] as List? ?? [])
          .map((e) => FoodEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      customFoods: (j['customFoods'] as List? ?? [])
          .map((e) => Food.fromJson(e as Map<String, dynamic>))
          .toList(),
      workouts: (j['workouts'] as List? ?? [])
          .map((e) => WorkoutLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      ladders: (j['ladders'] as Map? ?? {}).map(
        (k, v) => MapEntry(
          k as String,
          LadderState.fromJson(v as Map<String, dynamic>),
        ),
      ),
      reminders: j['reminders'] == null
          ? null
          : ReminderSettings.fromJson(j['reminders'] as Map<String, dynamic>),
    );
  }
}
