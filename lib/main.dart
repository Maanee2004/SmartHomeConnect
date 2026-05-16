import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_home/firebase_options.dart';
import 'package:smart_home/screens/auth/login_screen.dart';
import 'package:smart_home/services/firestore_home_repository.dart';
import 'theme/app_theme_scope.dart';
import 'theme/custom_theme.dart';
import 'package:smart_home/widgets/offline_banner.dart';

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
  try {
    if (Firebase.apps.isNotEmpty) {
      await FirestoreHomeRepository.instance.ensureLayoutResolved();
    }
  } catch (_) {
    // Détection Firestore : échec → résolution au premier watchRooms / watchDevices.
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

  /// Thèmes mis en cache pour éviter un recalcul lourd à chaque bascule clair/sombre.
  late final ThemeData _lightTheme = CustomTheme.lightTheme();
  late final ThemeData _darkTheme = CustomTheme.darkTheme();

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
            theme: _lightTheme,
            darkTheme: _darkTheme,
            themeMode: mode,
            builder: (context, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const OfflineBanner(),
                  Expanded(child: child ?? const SizedBox.shrink()),
                ],
              );
            },
            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}
