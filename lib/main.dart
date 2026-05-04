import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/calculator_screen.dart';
import 'screens/onboarding_screen.dart';

ThemeMode _themeModeFromString(String? value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

String _themeModeToString(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
    default:
      return 'system';
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
  final themeMode = _themeModeFromString(prefs.getString('themeMode'));

  runApp(
    MyApp(
      hasSeenOnboarding: hasSeenOnboarding,
      initialThemeMode: themeMode,
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool hasSeenOnboarding;
  final ThemeMode initialThemeMode;

  const MyApp({
    super.key,
    required this.hasSeenOnboarding,
    required this.initialThemeMode,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _themeModeToString(mode));
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calcify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2F6FED),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2F6FED),
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,
      home: widget.hasSeenOnboarding
          ? CalculatorScreen(
              themeMode: _themeMode,
              onThemeChanged: _setThemeMode,
            )
          : OnboardingScreen(
              themeMode: _themeMode,
              onThemeChanged: _setThemeMode,
            ),
    );
  }
}
