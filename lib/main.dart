import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_home/screens/auth/login_screen.dart';
import 'package:smart_home/firebase_options.dart';

import 'theme/app_theme_scope.dart';
import 'theme/custom_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Sur Web, Firebase nécessite des options (flutterfire configure).
    // On laisse l'app se lancer quand même pour éviter l'écran blanc.
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ValueNotifier<ThemeMode> _themeMode = ValueNotifier(ThemeMode.dark);

  @override
  void dispose() {
    _themeMode.dispose();
    super.dispose();
  }

  void _applyOverlay(ThemeMode mode) {
    final isDark = mode == ThemeMode.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarColor: Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeModeScope(
      notifier: _themeMode,
      child: ListenableBuilder(
        listenable: _themeMode,
        builder: (context, _) {
          final mode = _themeMode.value;
          _applyOverlay(mode);
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.edgeToEdge,
            overlays: const [],
          );
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Smart Home',
            theme: CustomTheme.lightTheme(),
            darkTheme: CustomTheme.darkTheme(),
            themeMode: mode,
            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}
