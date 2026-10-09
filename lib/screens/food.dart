import 'package:flutter/material.dart';

import '../data/foods.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';
import 'add_food.dart';

Meal defaultMeal() {
  final h = DateTime.now().hour;
  if (h < 11) return Meal.breakfast;
  if (h < 15) return Meal.lunch;
  if (h < 21) return Meal.dinner;
  return Meal.snack;
}

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  late DateTime _day = AppScope.of(context).today;

  IconData _icon(Meal m) => switch (m) {
    Meal.breakfast => Icons.wb_sunny_outlined,
    Meal.lunch => Icons.ramen_dining_outlined,
    Meal.dinner => Icons.dinner_dining_outlined,
    Meal.snack => Icons.cookie_outlined,
  };

  Color _color(Meal m) => switch (m) {
    Meal.breakfast => C.butter,
    Meal.lunch => C.lime,
    Meal.dinner => C.coral,
    Meal.snack => C.sky,
  };

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = s.targets;
    final protein = s.proteinOn(_day);
    final kcal = s.kcalOn(_day);
    final entries = s.entriesOn(_day);
    final isToday = _day == s.today;
    final left = (t.protein - protein).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Row(
          children: [
            Expanded(child: Text('Food', style: T.display(30))),
            IconButton(
              tooltip: 'Previous day',
              onPressed: () =>
                  setState(() => _day = _day.subtract(const Duration(days: 1))),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: C.pot,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isToday ? 'Today' : shortDate(_day),
                style: T.body(14, weight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'Next day',
              onPressed: isToday
                  ? null
                  : () => setState(
                      () => _day = _day.add(const Duration(days: 1)),
                    ),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Panel(
          radius: 28,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Protein',
                          style: T.body(
                            13,
                            color: C.coral,
                            weight: FontWeight.w700,
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${protein.round()}',
                                style: T.display(44),
                              ),
                              TextSpan(
                                text: ' / ${t.protein} g',
                                style: T.body(
                                  20,
                                  color: C.muted,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(fmtNum(kcal.round()), style: T.display(26)),
                      Text(
                        'of ${fmtNum(t.kcal)} kcal',
                        style: T.body(13, color: C.muted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Bar(protein / t.protein, color: C.coral, height: 14),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _mini('Carbs', s.carbsOn(_day), t.carbs, C.butter),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: _mini('Fat', s.fatOn(_day), t.fat, C.sky)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                left > 0
                    ? '$left g of protein to go. A chicken breast and a Greek yogurt would do it.'
                    : 'Protein target hit. Great job!',
                style: T.body(14, color: C.soft),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final id in quickFoodIds)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _quick(context, s, s.foodById(id)!),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final m in Meal.values) ...[
          _mealCard(context, s, m, entries.where((e) => e.meal == m).toList()),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _mini(String name, double v, int target, Color c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: T.body(13, color: c, weight: FontWeight.w700),
          ),
          Text('${v.round()} / $target g', style: T.body(13, color: C.muted)),
        ],
      ),
      const SizedBox(height: 5),
      Bar(v / target, color: c),
    ],
  );

  Widget _quick(BuildContext context, AppState s, Food f) => ActionChip(
    backgroundColor: C.ink,
    side: const BorderSide(color: C.line, width: 1.5),
    shape: const StadiumBorder(),
    labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    label: Text(
      '+ ${f.name.split(',').first} · ${f.protein.round()} g',
      style: T.body(14, weight: FontWeight.w600),
    ),
    onPressed: () async {
      await s.addFood(_day, defaultMeal(), f, 1);
      if (context.mounted) {
        toast(
          context,
          'Added ${f.name} to ${mealName(defaultMeal()).toLowerCase()}',
        );
      }
    },
  );

  Widget _mealCard(
    BuildContext context,
    AppState s,
    Meal m,
    List<FoodEntry> list,
  ) {
    final kcal = list.fold<double>(0, (a, e) => a + e.kcal);
    final protein = list.fold<double>(0, (a, e) => a + e.protein);
    return Panel(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: C.line,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon(m), color: _color(m), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealName(m),
                      style: T.body(16, weight: FontWeight.w700),
                    ),
                    Text(
                      list.isEmpty
                          ? 'Nothing logged yet'
                          : '${list.length} item${list.length == 1 ? '' : 's'}',
                      style: T.body(13, color: C.muted),
                    ),
                  ],
                ),
              ),
              if (list.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${fmtNum(kcal.round())} kcal',
                      style: T.body(15, weight: FontWeight.w700),
                    ),
                    Text(
                      '${protein.round()} g protein',
                      style: T.body(
                        13,
                        color: C.coral,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              IconButton(
                tooltip: 'Add to ${mealName(m).toLowerCase()}',
                onPressed: () => showAddFood(context, _day, m),
                icon: const Icon(
                  Icons.add_circle_rounded,
                  color: C.lime,
                  size: 30,
                ),
              ),
            ],
          ),
          for (final e in list)
            Dismissible(
              key: ValueKey(e.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: C.coral.withAlpha(60),
                child: const Icon(Icons.delete_outline_rounded, color: C.coral),
              ),
              onDismissed: (_) => s.removeFood(e.id),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(52, 8, 4, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${e.servings == 1 ? '' : '${_servings(e.servings)} x '}${e.food.name}',
                        style: T.body(14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${e.kcal.round()} kcal · ${e.protein.round()} g',
                      style: T.body(13, color: C.muted),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => s.removeFood(e.id),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: C.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _servings(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();
}
