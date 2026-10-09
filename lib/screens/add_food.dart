import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';

Future<void> showAddFood(BuildContext context, DateTime day, Meal meal) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => AddFoodSheet(day: day, meal: meal),
  );
}

class AddFoodSheet extends StatefulWidget {
  final DateTime day;
  final Meal meal;
  const AddFoodSheet({super.key, required this.day, required this.meal});

  @override
  State<AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<AddFoodSheet> {
  final _search = TextEditingController();
  Food? _picked;
  double _servings = 1;
  bool _custom = false;

  final _name = TextEditingController();
  final _serving = TextEditingController(text: '1 serving');
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();

  @override
  void dispose() {
    for (final c in [_search, _name, _serving, _kcal, _protein, _carbs, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: _picked != null
            ? _amount(context)
            : (_custom ? _customForm(context) : _list(context)),
      ),
    );
  }

  Widget _list(BuildContext context) {
    final s = AppScope.of(context);
    final q = _search.text.trim().toLowerCase();
    final foods = s.allFoods
        .where((f) => q.isEmpty || f.name.toLowerCase().contains(q))
        .toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Add to ${mealName(widget.meal).toLowerCase()}',
                  style: T.display(24),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search foods',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _custom = true),
              icon: const Icon(Icons.add_rounded, color: C.lime),
              label: const Text(
                'Create your own food',
                style: TextStyle(color: C.lime, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            child: foods.isEmpty
                ? Center(
                    child: Text(
                      'No match. Create your own food.',
                      style: T.body(15, color: C.muted),
                    ),
                  )
                : ListView.builder(
                    itemCount: foods.length,
                    itemBuilder: (context, i) {
                      final f = foods[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          f.name,
                          style: T.body(15, weight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${f.serving} · ${f.kcal.round()} kcal',
                          style: T.body(13, color: C.muted),
                        ),
                        trailing: Text(
                          '${f.protein.round()} g protein',
                          style: T.body(
                            13,
                            color: C.coral,
                            weight: FontWeight.w700,
                          ),
                        ),
                        onTap: () => setState(() {
                          _picked = f;
                          _servings = 1;
                        }),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _amount(BuildContext context) {
    final f = _picked!;
    final s = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _picked = null),
                icon: const Icon(Icons.chevron_left_rounded, size: 30),
              ),
              Expanded(child: Text(f.name, style: T.display(22))),
            ],
          ),
          const SizedBox(height: 6),
          Text('1 serving = ${f.serving}', style: T.body(14, color: C.muted)),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.outlined(
                onPressed: _servings <= 0.5
                    ? null
                    : () => setState(() => _servings -= 0.5),
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(
                width: 120,
                child: Column(
                  children: [
                    Text(
                      _servings == _servings.roundToDouble()
                          ? '${_servings.round()}'
                          : '$_servings',
                      style: T.display(48),
                    ),
                    Text(
                      _servings == 1 ? 'serving' : 'servings',
                      style: T.body(13, color: C.muted),
                    ),
                  ],
                ),
              ),
              IconButton.outlined(
                onPressed: () => setState(() => _servings += 0.5),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Panel(
            radius: 22,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _macro('kcal', (f.kcal * _servings).round(), C.text),
                _macro('protein', (f.protein * _servings).round(), C.coral),
                _macro('carbs', (f.carbs * _servings).round(), C.butter),
                _macro('fat', (f.fat * _servings).round(), C.sky),
              ],
            ),
          ),
          const Spacer(),
          PillButton(
            'Add to ${mealName(widget.meal).toLowerCase()}',
            onPressed: () async {
              await s.addFood(widget.day, widget.meal, f, _servings);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _macro(String label, int v, Color c) => Column(
    children: [
      Text('$v', style: T.display(26, color: c)),
      Text(label, style: T.body(12, color: C.muted)),
    ],
  );

  Widget _customForm(BuildContext context) {
    final s = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _custom = false),
              icon: const Icon(Icons.chevron_left_rounded, size: 30),
            ),
            Text('Your own food', style: T.display(22)),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _serving,
          decoration: const InputDecoration(labelText: 'One serving is'),
        ),
        const SizedBox(height: 12),
        Text('Per serving', style: T.body(13, color: C.muted)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: NumField(controller: _kcal, label: 'kcal'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: NumField(
                controller: _protein,
                label: 'Protein g',
                highlight: true,
                highlightColor: C.coral,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: NumField(controller: _carbs, label: 'Carbs g'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: NumField(controller: _fat, label: 'Fat g'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        PillButton(
          'Save and add',
          onPressed: () async {
            final name = _name.text.trim();
            final kcal = parseNum(_kcal.text);
            if (name.isEmpty || kcal == null) {
              toast(context, 'Add a name and the calories');
              return;
            }
            final f = Food(
              id: 'c_${DateTime.now().microsecondsSinceEpoch}',
              name: name,
              serving: _serving.text.trim().isEmpty
                  ? '1 serving'
                  : _serving.text.trim(),
              kcal: kcal,
              protein: parseNum(_protein.text) ?? 0,
              carbs: parseNum(_carbs.text) ?? 0,
              fat: parseNum(_fat.text) ?? 0,
            );
            await s.addCustomFood(f);
            await s.addFood(widget.day, widget.meal, f, 1);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
