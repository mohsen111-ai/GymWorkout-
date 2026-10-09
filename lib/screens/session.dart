import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/planner.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/bean.dart';
import '../widgets/common.dart';
import '../widgets/dialogs.dart';
import 'guide.dart';
import 'levelup.dart';

enum _Phase { work, rest, finish }

/// Runs a workout: set by set, with a rest timer and Bean demonstrating form.
class SessionScreen extends StatefulWidget {
  final Workout workout;
  const SessionScreen({super.key, required this.workout});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late final List<List<int>> _sets = [
    for (final _ in widget.workout.exercises) <int>[],
  ];
  int _ei = 0;
  int _si = 0;
  late int _value = _ex.target;
  _Phase _phase = _Phase.work;
  Timer? _timer;
  int _restLeft = 0;
  int _restTotal = 1;
  int _holdLeft = 0;
  bool _holding = false;
  Felt _felt = Felt.ok;
  bool _saving = false;
  final DateTime _started = DateTime.now();

  List<PlannedExercise> get _list => widget.workout.exercises;
  PlannedExercise get _ex => _list[_ei];
  bool get _lastSet => _si + 1 >= _ex.sets;
  bool get _lastExercise => _ei + 1 >= _list.length;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _completeSet() {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    _sets[_ei].add(_value);
    final rest = _ex.restSec;
    if (!_lastSet) {
      setState(() => _si++);
    } else if (!_lastExercise) {
      setState(() {
        _ei++;
        _si = 0;
      });
    } else {
      setState(() {
        _phase = _Phase.finish;
        _holding = false;
      });
      return;
    }
    _startRest(rest);
  }

  void _startRest(int secs) {
    _timer?.cancel();
    setState(() {
      _phase = _Phase.rest;
      _holding = false;
      _restLeft = secs;
      _restTotal = max(1, secs);
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_restLeft <= 1) {
        HapticFeedback.heavyImpact();
        _endRest();
      } else {
        setState(() => _restLeft--);
      }
    });
  }

  void _endRest() {
    _timer?.cancel();
    setState(() {
      _phase = _Phase.work;
      _value = _ex.target;
    });
  }

  void _startHold() {
    _timer?.cancel();
    setState(() {
      _holding = true;
      _holdLeft = _value;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_holdLeft <= 1) {
        t.cancel();
        HapticFeedback.heavyImpact();
        _holdLeft = 0;
        _holding = false;
        _completeSet();
      } else {
        setState(() => _holdLeft--);
      }
    });
  }

  void _stopHold() {
    final elapsed = _value - _holdLeft;
    _timer?.cancel();
    setState(() {
      _holding = false;
      _value = max(1, elapsed);
    });
  }

  Future<void> _exit() async {
    final leave = await confirm(
      context,
      title: 'End this workout?',
      message: _phase == _Phase.finish
          ? 'Your workout is not saved yet.'
          : 'Your progress in this session will not be saved.',
      yes: 'End workout',
      no: 'Keep going',
      danger: true,
    );
    if (leave && mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final s = AppScope.of(context);
    final minutes = max(1, DateTime.now().difference(_started).inMinutes);
    final offers = await s.completeWorkout(
      widget.workout,
      _sets,
      _felt,
      minutes,
    );
    if (!mounted) return;
    for (final o in offers) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LevelUpScreen(offer: o)),
      );
      if (!mounted) return;
    }
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  String _lastTime(AppState s) {
    final ex = _ex;
    final logs = [...s.data.workouts]..sort((a, b) => b.day.compareTo(a.day));
    for (final w in logs) {
      for (final e in w.exercises) {
        if (e.ladderId == ex.ladder.id &&
            e.level == ex.levelIdx &&
            e.sets.isNotEmpty) {
          return '${e.sets.reduce(max)}';
        }
      }
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (_phase) {
      _Phase.work => _work(context),
      _Phase.rest => _rest(context),
      _Phase.finish => _finish(context),
    };
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(body: SafeArea(child: body)),
    );
  }

  // ------------------------------------------------------------------ work

  Widget _work(BuildContext context) {
    final s = AppScope.of(context);
    final ex = _ex;
    final lv = ex.level;
    final cue = lv.doThis.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              Semantics(
                button: true,
                label: 'End workout',
                child: GestureDetector(
                  onTap: _exit,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: C.pot,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.workout.title, style: T.display(20)),
                    Text(
                      'Move ${_ei + 1} of ${_list.length}',
                      style: T.body(13, color: C.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: C.pot,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'No jumping',
                  style: T.body(13, color: C.lime, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < _list.length; i++) ...[
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: i < _ei
                          ? C.lime
                          : (i == _ei ? C.lime.withAlpha(140) : C.line),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                if (i < _list.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Panel(
              radius: 28,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const Label('Follow Bean'),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GuideScreen(
                                ladderId: ex.ladder.id,
                                levelIdx: ex.levelIdx,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Form tips',
                            style: TextStyle(
                              color: C.lime,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: _holding
                          ? Ring(
                              value: 1 - _holdLeft / max(1, _value),
                              size: 170,
                              stroke: 14,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('$_holdLeft', style: T.display(56)),
                                  Text(
                                    'seconds left',
                                    style: T.body(13, color: C.muted),
                                  ),
                                ],
                              ),
                            )
                          : BeanDemo(motion: lv.motion, size: 150),
                    ),
                  ),
                  Text(
                    cue,
                    textAlign: TextAlign.center,
                    style: T.body(14, color: C.soft),
                  ),
                  const SizedBox(height: 10),
                  Text(ex.tempoText, style: T.body(13, color: C.muted)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(ex.name, style: T.display(30)),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${ex.ladder.muscles}${ex.ladder.perSide ? ' · each side' : ''}',
              style: T.body(14, color: C.muted),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _tile('Set', '${_si + 1}', ' / ${ex.sets}', C.text),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _tile(
                  'Target',
                  '${ex.target}',
                  ex.isTime ? ' s' : ' reps',
                  C.text,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _tile('Last time', _lastTime(s), '', C.coral)),
            ],
          ),
          const SizedBox(height: 10),
          Panel(
            radius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ex.isTime ? 'Seconds held' : 'Reps done this set',
                    style: T.body(14, weight: FontWeight.w500),
                  ),
                ),
                _stepButton(
                  Icons.remove_rounded,
                  'Fewer',
                  C.line,
                  _holding
                      ? null
                      : () => setState(
                          () => _value = max(0, _value - (ex.isTime ? 5 : 1)),
                        ),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    '$_value',
                    textAlign: TextAlign.center,
                    style: T.display(30),
                  ),
                ),
                _stepButton(
                  Icons.add_rounded,
                  'More',
                  C.lime,
                  _holding
                      ? null
                      : () => setState(() => _value += (ex.isTime ? 5 : 1)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (ex.isTime && !_holding)
            Row(
              children: [
                Expanded(
                  child: PillButton(
                    'Start timer',
                    outlined: true,
                    fontSize: 17,
                    height: 60,
                    icon: Icons.timer_outlined,
                    onPressed: _startHold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PillButton(
                    _doneLabel(short: true),
                    fontSize: 17,
                    onPressed: _completeSet,
                  ),
                ),
              ],
            )
          else if (_holding)
            PillButton('Stop', color: C.coral, onPressed: _stopHold)
          else
            PillButton(_doneLabel(), onPressed: _completeSet),
        ],
      ),
    );
  }

  String _doneLabel({bool short = false}) {
    if (_lastSet && _lastExercise) return short ? 'Finish' : 'Finish workout';
    if (_lastSet) return 'Move done';
    if (short) return 'Set done';
    return 'Set done · rest ${_ex.restSec} s';
  }

  Widget _tile(String label, String big, String small, Color c) => Panel(
    radius: 18,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: T.body(12, color: C.muted, weight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: big,
                style: T.display(24, color: c),
              ),
              TextSpan(
                text: small,
                style: T.body(13, color: C.muted, weight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _stepButton(
    IconData icon,
    String label,
    Color border,
    VoidCallback? onTap,
  ) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap();
            },
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: onTap == null ? C.line : border,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: onTap == null ? C.muted : (border == C.lime ? C.lime : C.text),
        ),
      ),
    ),
  );

  // ------------------------------------------------------------------ rest

  Widget _rest(BuildContext context) {
    final ex = _ex;
    final nextIsNewMove = _si == 0;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          const Bean(mood: Mood.sleepy, size: 90),
          const SizedBox(height: 16),
          Text('Rest', style: T.display(34)),
          const SizedBox(height: 18),
          Ring(
            value: _restLeft / _restTotal,
            size: 200,
            stroke: 14,
            color: C.sky,
            child: Text('$_restLeft', style: T.display(72)),
          ),
          const SizedBox(height: 22),
          Text(
            nextIsNewMove ? 'Next move' : 'Up next',
            style: T.body(13, color: C.muted),
          ),
          const SizedBox(height: 4),
          Text(ex.name, style: T.display(24)),
          Text(
            nextIsNewMove
                ? ex.prescription
                : 'Set ${_si + 1} of ${ex.sets} · ${ex.target} ${ex.isTime ? 's' : 'reps'}',
            style: T.body(15, color: C.soft),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: PillButton(
                  '+15 s',
                  outlined: true,
                  color: C.text,
                  fontSize: 17,
                  onPressed: () => setState(() {
                    _restLeft += 15;
                    _restTotal += 15;
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PillButton(
                  'Skip rest',
                  fontSize: 17,
                  onPressed: _endRest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- finish

  Widget _finish(BuildContext context) {
    final totalSets = _sets.fold<int>(0, (a, b) => a + b.length);
    final minutes = max(1, DateTime.now().difference(_started).inMinutes);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 12),
        const Center(child: Bean(mood: Mood.cheer, size: 130)),
        const SizedBox(height: 12),
        Center(
          child: Text('Workout complete!', style: T.display(32, color: C.lime)),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            '$totalSets sets · $minutes min · ${_list.length} moves',
            style: T.body(15, color: C.soft),
          ),
        ),
        const SizedBox(height: 24),
        const Label('How did it feel?'),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final f in Felt.values) ...[
              Expanded(
                child: Chip2(
                  switch (f) {
                    Felt.easy => 'Too easy',
                    Felt.ok => 'Just right',
                    Felt.hard => 'Too hard',
                  },
                  selected: _felt == f,
                  color: f == Felt.hard ? C.coral : C.lime,
                  onTap: () => setState(() => _felt = f),
                ),
              ),
              if (f != Felt.hard) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Text(switch (_felt) {
          Felt.easy => 'Bean will raise your targets faster next time.',
          Felt.ok => 'Bean will add a little more when you hit every set.',
          Felt.hard =>
            'Bean will hold your targets steady until it feels better.',
        }, style: T.body(13, color: C.muted)),
        const SizedBox(height: 22),
        const Label('Your sets'),
        const SizedBox(height: 8),
        for (var i = 0; i < _list.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Panel(
              radius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _list[i].name,
                      style: T.body(15, weight: FontWeight.w700),
                    ),
                  ),
                  Text(_sets[i].join(' · '), style: T.body(14, color: C.muted)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 14),
        PillButton(
          _saving ? 'Saving...' : 'Save workout',
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}
