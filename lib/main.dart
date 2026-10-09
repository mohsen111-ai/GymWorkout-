import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'notifications.dart';
import 'screens/onboarding.dart';
import 'screens/shell.dart';
import 'state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: C.pot,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  final state = await AppState.load();
  await Notifier.init();
  runApp(MightyBeanApp(state: state));
}

class MightyBeanApp extends StatelessWidget {
  final AppState state;
  const MightyBeanApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) => AppScope(
    state: state,
    child: MaterialApp(
      title: 'Mighty Bean',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const _Root(),
    ),
  );
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> with WidgetsBindingObserver {
  AppState? _state;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppScope.of(context);
    if (!identical(s, _state)) {
      _state?.removeListener(_schedule);
      _state = s..addListener(_schedule);
      _schedule();
    }
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      final s = _state;
      if (s != null && s.hasProfile) Notifier.reschedule(s);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState l) {
    if (l == AppLifecycleState.resumed) _schedule();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _state?.removeListener(_schedule);
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return s.hasProfile ? const Shell() : const OnboardingScreen();
  }
}
