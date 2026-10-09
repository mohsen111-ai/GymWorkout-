import 'package:flutter/material.dart';

import '../theme.dart';
import 'food.dart';
import 'plan.dart';
import 'progress.dart';
import 'today.dart';

/// Lets any screen jump to another tab (0 Today, 1 Train, 2 Food, 3 Progress).
final ValueNotifier<int> tabIndex = ValueNotifier(0);

class Shell extends StatelessWidget {
  const Shell({super.key});

  static const _tabs = [
    (Icons.home_rounded, Icons.home_outlined, 'Today'),
    (Icons.directions_run_rounded, Icons.directions_run_outlined, 'Train'),
    (Icons.restaurant_rounded, Icons.restaurant_outlined, 'Food'),
    (Icons.show_chart_rounded, Icons.show_chart_rounded, 'Progress'),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: tabIndex,
      builder: (context, i, _) => Scaffold(
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: i,
            children: const [
              TodayScreen(),
              PlanScreen(),
              FoodScreen(),
              ProgressScreen(),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: C.pot,
            border: Border(top: BorderSide(color: C.line)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 68,
              child: Row(
                children: [
                  for (var n = 0; n < _tabs.length; n++)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: n == i,
                        label: _tabs[n].$3,
                        child: InkWell(
                          onTap: () => tabIndex.value = n,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                n == i ? _tabs[n].$1 : _tabs[n].$2,
                                color: n == i ? C.lime : C.muted,
                                size: 26,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _tabs[n].$3,
                                style: T.body(
                                  12,
                                  color: n == i ? C.lime : C.muted,
                                  weight: n == i
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
