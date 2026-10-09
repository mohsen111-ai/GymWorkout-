// Exercise library. Every move belongs to a "ladder": a chain of versions that
// get harder as you get stronger. No equipment, no jumping.

enum Motion {
  squat,
  lunge,
  pushup,
  bridge,
  plank,
  row,
  deadbug,
  hold,
  calf,
  back,
}

enum Group { push, pull, legs, core }

class Level {
  final String name;
  final bool isTime;
  final int min;
  final int max;
  final Motion motion;
  final List<String> doThis;
  final List<String> avoid;

  const Level(
    this.name,
    this.min,
    this.max,
    this.motion, {
    this.isTime = false,
    required this.doThis,
    required this.avoid,
  });

  /// Step size when progressing (reps +2, seconds +5).
  int get step => isTime ? 5 : 2;
  String get unit => isTime ? 's' : 'reps';
}

class Ladder {
  final String id;
  final String name;
  final String muscles;
  final Group group;
  final bool perSide;
  final List<Level> levels;

  const Ladder(
    this.id,
    this.name,
    this.muscles,
    this.group,
    this.levels, {
    this.perSide = false,
  });
}

const _tall = 'Keep your chest tall and your core tight';
const _control = 'Lower slowly, never bounce';
const _breathe = 'Breathe out as you push or lift';

const List<Ladder> ladders = [
  Ladder('pushup', 'Push-up', 'Chest, shoulders, triceps', Group.push, [
    Level(
      'Wall push-up',
      10,
      20,
      Motion.pushup,
      doThis: [
        'Stand an arm\'s length from the wall',
        'Keep your body in one straight line',
        _breathe,
      ],
      avoid: ['Letting your hips sag back', 'Flaring elbows wide'],
    ),
    Level(
      'Incline push-up',
      8,
      16,
      Motion.pushup,
      doThis: [
        'Hands on a sturdy table or sofa edge',
        'Body in a straight line from head to heels',
        'Lower your chest to the edge',
      ],
      avoid: ['Sagging hips', 'Shrugging shoulders to your ears'],
    ),
    Level(
      'Push-up',
      6,
      15,
      Motion.pushup,
      doThis: [
        'Hands just wider than shoulders',
        'Squeeze your glutes and core',
        'Lower until your chest is a fist from the floor',
      ],
      avoid: ['Hips sagging or piking up', 'Elbows flared at 90 degrees'],
    ),
    Level(
      'Feet-elevated push-up',
      6,
      14,
      Motion.pushup,
      doThis: [
        'Feet on a low, stable step or sofa',
        'Keep your core braced',
        _control,
      ],
      avoid: ['Letting your lower back dip', 'Rushing the reps'],
    ),
    Level(
      'Archer push-up',
      4,
      10,
      Motion.pushup,
      doThis: [
        'Wide hands, shift weight to one side',
        'Keep the other arm straight',
        'Alternate sides each rep',
      ],
      avoid: ['Twisting your hips', 'Going so wide you lose control'],
    ),
    Level(
      'Slow 5-second push-up',
      4,
      10,
      Motion.pushup,
      doThis: [
        'Lower for a full 5 seconds',
        'Pause 1 second above the floor',
        'Press up powerfully',
      ],
      avoid: ['Cheating the lowering phase', 'Holding your breath'],
    ),
  ]),
  Ladder('pike', 'Shoulder press', 'Shoulders, upper chest', Group.push, [
    Level(
      'Pike push-up',
      6,
      14,
      Motion.pushup,
      doThis: [
        'Hips high, body shaped like an upside-down V',
        'Lower your head toward the floor between your hands',
        _breathe,
      ],
      avoid: ['Letting your hips drop', 'Flaring elbows out'],
    ),
    Level(
      'Elevated pike push-up',
      5,
      12,
      Motion.pushup,
      doThis: [
        'Feet on a low, stable step',
        'Head travels in front of your hands',
        _control,
      ],
      avoid: ['Using a wobbly surface', 'Bending your back'],
    ),
    Level(
      'Wall pike hold',
      15,
      45,
      Motion.hold,
      isTime: true,
      doThis: [
        'Feet on a wall, hips high in an upside-down V',
        'Push the floor away through your shoulders',
        'Come down if you feel dizzy',
      ],
      avoid: ['Arching your back', 'Holding your breath'],
    ),
  ]),
  Ladder('dip', 'Triceps dip', 'Triceps, shoulders', Group.push, [
    Level(
      'Bent-knee chair dip',
      8,
      16,
      Motion.pushup,
      doThis: [
        'Hands on the edge of a sturdy chair',
        'Knees bent, feet flat',
        'Lower until elbows are about 90 degrees',
      ],
      avoid: [
        'Using a chair that slides',
        'Dipping so deep your shoulders hurt',
      ],
    ),
    Level(
      'Straight-leg chair dip',
      6,
      14,
      Motion.pushup,
      doThis: [
        'Legs straight, heels on the floor',
        'Elbows point straight back',
        _control,
      ],
      avoid: ['Letting elbows flare out', 'Shrugging your shoulders'],
    ),
    Level(
      'Feet-elevated chair dip',
      5,
      12,
      Motion.pushup,
      doThis: [
        'Feet up on a second sturdy chair',
        'Keep your hips close to the chair',
        _control,
      ],
      avoid: ['Letting the chairs move', 'Going deeper than comfortable'],
    ),
  ]),
  Ladder('squat', 'Squat', 'Quads, glutes', Group.legs, [
    Level(
      'Chair squat',
      10,
      20,
      Motion.squat,
      doThis: [
        'Sit back to lightly touch a chair, then stand',
        'Feet shoulder-width apart',
        _tall,
      ],
      avoid: ['Dropping onto the chair', 'Knees caving in'],
    ),
    Level(
      'Squat',
      10,
      20,
      Motion.squat,
      doThis: [
        'Sit your hips back and down',
        'Knees track over your toes',
        'Drive through your whole foot',
      ],
      avoid: ['Heels lifting off the floor', 'Knees caving inward'],
    ),
    Level(
      'Pause squat',
      8,
      16,
      Motion.squat,
      doThis: [
        'Squat down and hold 2 seconds at the bottom',
        'Stay tight, do not relax',
        'Stand up smoothly',
      ],
      avoid: ['Bouncing out of the bottom', 'Rounding your lower back'],
    ),
    Level(
      'Split squat',
      8,
      14,
      Motion.lunge,
      doThis: [
        'One foot forward, one back, stay in place',
        'Lower your back knee toward the floor',
        'Front knee over the ankle',
      ],
      avoid: ['Leaning forward', 'Short, shallow reps'],
    ),
    Level(
      'Bulgarian split squat',
      6,
      12,
      Motion.lunge,
      doThis: [
        'Back foot on a sofa or low step',
        'Lower straight down',
        'Most of your weight on the front foot',
      ],
      avoid: ['Front foot too close to the sofa', 'Rushing the reps'],
    ),
    Level(
      'Assisted shrimp squat',
      4,
      10,
      Motion.lunge,
      doThis: [
        'Hold a wall or door frame for balance',
        'Lower on one leg while the other bends behind',
        'Go down only as far as you control',
      ],
      avoid: ['Collapsing at the bottom', 'Letting the knee cave in'],
    ),
  ]),
  Ladder('lunge', 'Lunge', 'Quads, glutes, balance', Group.legs, [
    Level(
      'Assisted reverse lunge',
      8,
      14,
      Motion.lunge,
      doThis: [
        'Hold a wall or chair lightly for balance',
        'Step back and lower slowly',
        _tall,
      ],
      avoid: ['Pulling on the support', 'Short steps that tip you forward'],
    ),
    Level(
      'Reverse lunge',
      8,
      14,
      Motion.lunge,
      doThis: [
        'Step back and lower for 3 seconds',
        'Front knee over the ankle',
        'Push through the front heel to stand',
      ],
      avoid: ['Leaning forward', 'Bouncing at the bottom'],
    ),
    Level(
      'Reverse lunge with pause',
      6,
      12,
      Motion.lunge,
      doThis: [
        'Hold 2 seconds at the bottom',
        'Keep your chest tall',
        'Stand up smoothly',
      ],
      avoid: ['Resting your back knee on the floor', 'Rushing the pause'],
    ),
    Level(
      'Walking lunge',
      8,
      16,
      Motion.lunge,
      doThis: [
        'Take a long step and lower under control',
        'Push off the front foot into the next step',
        'Keep your torso upright',
      ],
      avoid: ['Tiny steps', 'Letting the knee cave in'],
    ),
  ], perSide: true),
  Ladder('bridge', 'Glute bridge', 'Glutes, hamstrings', Group.legs, [
    Level(
      'Glute bridge',
      12,
      20,
      Motion.bridge,
      doThis: [
        'Lie on your back, knees bent, feet flat',
        'Squeeze your glutes to lift your hips',
        'Pause 1 second at the top',
      ],
      avoid: ['Pushing with your lower back', 'Letting your ribs flare'],
    ),
    Level(
      'Marching bridge',
      8,
      16,
      Motion.bridge,
      doThis: [
        'Hold the bridge and lift one knee at a time',
        'Keep your hips level',
        'Squeeze the whole time',
      ],
      avoid: ['Hips tilting to one side', 'Dropping your hips'],
    ),
    Level(
      'Single-leg bridge',
      8,
      14,
      Motion.bridge,
      doThis: [
        'Extend one leg straight up',
        'Drive through the planted heel',
        'Keep your hips level',
      ],
      avoid: ['Twisting your hips', 'Overarching your back'],
    ),
    Level(
      'Shoulder-elevated hip thrust',
      6,
      12,
      Motion.bridge,
      doThis: [
        'Upper back on a sofa edge, one leg at a time',
        'Thrust your hips until your body is flat',
        'Pause and squeeze at the top',
      ],
      avoid: ['Sliding on the sofa', 'Overarching your lower back'],
    ),
  ], perSide: false),
  Ladder('calf', 'Calf raise', 'Calves', Group.legs, [
    Level(
      'Calf raise',
      12,
      25,
      Motion.calf,
      doThis: [
        'Rise slowly onto your toes',
        'Pause 1 second at the top',
        'Lower for 3 seconds',
      ],
      avoid: ['Bouncing', 'Rolling onto the outside of your feet'],
    ),
    Level(
      'Single-leg calf raise',
      8,
      18,
      Motion.calf,
      doThis: [
        'Hold a wall lightly for balance',
        'Full range, slow and smooth',
        'Pause at the top',
      ],
      avoid: ['Using the wall to pull yourself up', 'Rushing'],
    ),
  ]),
  Ladder('wallsit', 'Wall sit', 'Quads, endurance', Group.legs, [
    Level(
      'Wall sit',
      20,
      60,
      Motion.hold,
      isTime: true,
      doThis: [
        'Back flat on the wall, knees at about 90 degrees',
        'Feet slightly in front of your knees',
        'Breathe steadily',
      ],
      avoid: [
        'Resting your hands on your thighs',
        'Letting your knees go past your toes',
      ],
    ),
    Level(
      'Wall sit with leg lift',
      15,
      45,
      Motion.hold,
      isTime: true,
      doThis: [
        'Hold the wall sit and lift one heel off the floor',
        'Switch halfway through',
        'Keep your hips level',
      ],
      avoid: ['Sliding down the wall', 'Holding your breath'],
    ),
  ]),
  Ladder('row', 'Row', 'Back, biceps', Group.pull, [
    Level(
      'Backpack row',
      10,
      18,
      Motion.row,
      doThis: [
        'Load a backpack with books',
        'Hinge forward, flat back, and row it to your hip',
        'Squeeze your shoulder blades',
      ],
      avoid: ['Rounding your back', 'Jerking the bag up'],
    ),
    Level(
      'Table row (bent knees)',
      8,
      16,
      Motion.row,
      doThis: [
        'Lie under a very sturdy table, hold the edge',
        'Keep your body straight and pull your chest up',
        'Lower slowly',
      ],
      avoid: ['Using a table that can tip', 'Letting your hips sag'],
    ),
    Level(
      'Table row',
      6,
      14,
      Motion.row,
      doThis: [
        'Legs straight, heels on the floor',
        'Pull your chest to the edge',
        'Squeeze your shoulder blades',
      ],
      avoid: ['Sagging hips', 'Shrugging your shoulders'],
    ),
    Level(
      'Feet-elevated table row',
      5,
      12,
      Motion.row,
      doThis: [
        'Feet on a chair, body flat',
        'Pull your chest to the table edge',
        _control,
      ],
      avoid: ['Letting your hips drop', 'Relying on your biceps only'],
    ),
    Level(
      'Archer table row',
      4,
      10,
      Motion.row,
      doThis: [
        'Pull toward one hand while the other arm extends',
        'Alternate sides',
        'Keep your body rigid',
      ],
      avoid: ['Twisting your hips', 'Pulling with your neck'],
    ),
  ]),
  Ladder('rsnow', 'Back raise', 'Upper back, rear shoulders', Group.pull, [
    Level(
      'Superman hold',
      15,
      40,
      Motion.back,
      isTime: true,
      doThis: [
        'Lie face down, lift arms and legs slightly',
        'Look at the floor to keep your neck long',
        'Squeeze your glutes and back',
      ],
      avoid: ['Cranking your neck up', 'Holding your breath'],
    ),
    Level(
      'Reverse snow angel',
      8,
      16,
      Motion.back,
      doThis: [
        'Lie face down, lift your chest slightly',
        'Sweep your arms from your sides to overhead',
        'Move slowly',
      ],
      avoid: ['Jerking your arms', 'Lifting your head too high'],
    ),
    Level(
      'Swimmers',
      20,
      45,
      Motion.back,
      isTime: true,
      doThis: [
        'Lie face down, arms and legs lifted',
        'Flutter opposite arm and leg slowly',
        'Keep your neck neutral',
      ],
      avoid: ['Kicking wildly', 'Straining your lower back'],
    ),
  ]),
  Ladder('plank', 'Plank', 'Core, shoulders', Group.core, [
    Level(
      'Knee plank',
      20,
      45,
      Motion.plank,
      isTime: true,
      doThis: [
        'Forearms down, knees on the floor',
        'Straight line from head to knees',
        'Squeeze your core and glutes',
      ],
      avoid: ['Letting your hips sag', 'Holding your breath'],
    ),
    Level(
      'Plank',
      20,
      60,
      Motion.plank,
      isTime: true,
      doThis: [
        'Elbows under shoulders, body in a straight line',
        'Squeeze your glutes and thighs',
        'Breathe steadily',
      ],
      avoid: ['Hips too high or too low', 'Shrugging your shoulders'],
    ),
    Level(
      'Long plank',
      20,
      50,
      Motion.plank,
      isTime: true,
      doThis: [
        'Move your elbows forward past your shoulders',
        'Keep your ribs tucked in',
        'Stay tight',
      ],
      avoid: ['Arching your lower back', 'Letting your shoulders collapse'],
    ),
    Level(
      'Plank shoulder taps',
      20,
      50,
      Motion.plank,
      isTime: true,
      doThis: [
        'Hands on the floor, feet wide',
        'Tap one shoulder at a time',
        'Keep your hips still',
      ],
      avoid: ['Rocking your hips', 'Rushing the taps'],
    ),
  ]),
  Ladder('deadbug', 'Dead bug', 'Deep core', Group.core, [
    Level(
      'Dead bug',
      8,
      16,
      Motion.deadbug,
      doThis: [
        'Lie on your back, knees over hips, arms up',
        'Lower the opposite arm and leg slowly',
        'Press your lower back into the floor',
      ],
      avoid: ['Arching your back', 'Moving fast'],
    ),
    Level(
      'Straight-leg dead bug',
      6,
      14,
      Motion.deadbug,
      doThis: [
        'Extend the legs a little straighter',
        'Keep your lower back pressed down',
        'Move slowly',
      ],
      avoid: ['Lower back lifting off the floor', 'Holding your breath'],
    ),
    Level(
      'Hollow body hold',
      15,
      40,
      Motion.hold,
      isTime: true,
      doThis: [
        'Lower back pressed to the floor',
        'Arms overhead, legs low',
        'Lift your shoulders slightly',
      ],
      avoid: ['Lower back arching', 'Straining your neck'],
    ),
  ], perSide: false),
  Ladder('sideplank', 'Side plank', 'Obliques, hips', Group.core, [
    Level(
      'Knee side plank',
      15,
      40,
      Motion.plank,
      isTime: true,
      doThis: [
        'Elbow under shoulder, knees bent',
        'Lift your hips in a straight line',
        'Do both sides',
      ],
      avoid: ['Letting your hips sag', 'Rolling forward or back'],
    ),
    Level(
      'Side plank',
      15,
      45,
      Motion.plank,
      isTime: true,
      doThis: [
        'Stack your feet, lift your hips high',
        'Straight line from head to heels',
        'Do both sides',
      ],
      avoid: ['Sagging', 'Twisting your chest'],
    ),
    Level(
      'Side plank hip dip',
      8,
      16,
      Motion.plank,
      doThis: [
        'From a side plank, lower your hip an inch and lift',
        'Slow and controlled',
        'Do both sides',
      ],
      avoid: ['Bouncing', 'Going too deep'],
    ),
  ], perSide: true),
  Ladder('birddog', 'Bird dog', 'Core, lower back', Group.core, [
    Level(
      'Bird dog',
      8,
      16,
      Motion.deadbug,
      doThis: [
        'On hands and knees, extend opposite arm and leg',
        'Keep your hips level',
        'Hold 1 second, then switch',
      ],
      avoid: ['Twisting your hips', 'Arching your back'],
    ),
    Level(
      'Bird dog with crunch',
      8,
      14,
      Motion.deadbug,
      doThis: [
        'Extend, then draw your elbow to your knee',
        'Round your upper back a little',
        'Slow and smooth',
      ],
      avoid: ['Rushing', 'Losing your balance'],
    ),
  ]),
];

Ladder ladderById(String id) => ladders.firstWhere((l) => l.id == id);
