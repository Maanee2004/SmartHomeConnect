import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smart_home/screens/auth/login_screen.dart';
import 'package:smart_home/screens/admin/admin_shell_screen.dart';
import 'package:smart_home/screens/home/home_shell_screen.dart';
import 'package:smart_home/services/app_startup.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/services/user_preferences_service.dart';
import 'package:smart_home/l10n/app_localizations.dart';
import 'theme/app_theme_scope.dart';
import 'theme/custom_theme.dart';
import 'package:smart_home/widgets/alert_listener.dart';
import 'package:smart_home/widgets/offline_banner.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    AppStartup.ensureFirebase(),
    UserPreferencesService.instance.init(),
    AuthService.instance.initSession(),
  ]);

  runApp(const MyApp());
  // Auth anonyme + Firestore streams sans bloquer le premier frame.
  AppStartup.warmUpInBackground();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _prefs = UserPreferencesService.instance;

  @override
  void initState() {
    super.initState();
    _prefs.notifier.addListener(_onPrefsChanged);
    _applyOverlay(_prefs.prefs.themeMode);
  }

  void _onPrefsChanged() => _applyOverlay(_prefs.prefs.themeMode);

  @override
  void dispose() {
    _prefs.notifier.removeListener(_onPrefsChanged);
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
      notifier: _prefs.themeModeNotifier,
      child: ListenableBuilder(
        listenable: _prefs.notifier,
        builder: (context, _) {
          final p = _prefs.prefs;
          return MaterialApp(
            navigatorKey: appNavigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Smart Home',
            locale: p.locale,
            supportedLocales: const [
              Locale('fr'),
              Locale('en'),
              Locale('ar'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: CustomTheme.lightTheme(fontFamily: p.fontFamily),
            darkTheme: CustomTheme.darkTheme(fontFamily: p.fontFamily),
            themeMode: p.themeMode,
            themeAnimationDuration: Duration.zero,
            themeAnimationCurve: Curves.linear,
            builder: (context, child) {
              final scaled = MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(p.fontScale),
              );
              return MediaQuery(
                data: scaled,
                child: AlertListener(
                  navigatorKey: appNavigatorKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const OfflineBanner(),
                      Expanded(child: child ?? const SizedBox.shrink()),
                    ],
                  ),
                ),
              );
            },
            home: ListenableBuilder(
              listenable: AuthService.instance.authNotifier,
              builder: (context, _) {
                if (!AuthService.instance.isLoggedIn) {
                  return const LoginScreen();
                }
                return AuthService.instance.isAdmin
                    ? const AdminShellScreen()
                    : const HomeShellScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
