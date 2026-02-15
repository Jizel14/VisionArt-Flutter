import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/api_client.dart';
import 'core/auth_service.dart';
import 'core/app_config.dart';
import 'core/signature_storage.dart';
import 'core/preferences_service.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/auth/auth_screen.dart';
import 'presentation/screens/preferences/preferences_screen.dart';
import 'screens/home_screen.dart';

const String _keyThemeMode = 'theme_mode';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize configuration from .env file (or dart-define as fallback)
  await AppConfig.init();

  // Initialize API client
  await ApiClient.init();

  final authService = AuthService();
  final token = await authService.getToken;
  if (token != null && token.isNotEmpty) {
    ApiClient.setToken(token);
  }

  runApp(VisionArtApp(authService: authService));
}

class VisionArtApp extends StatefulWidget {
  const VisionArtApp({super.key, required this.authService});

  final AuthService authService;

  @override
  State<VisionArtApp> createState() => _VisionArtAppState();

  /// Global method to change theme from anywhere in the app
  static _VisionArtAppState? of(BuildContext context) {
    return context.findRootAncestorStateOfType<_VisionArtAppState>();
  }
}

class _VisionArtAppState extends State<VisionArtApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyThemeMode);
    ThemeMode newMode = ThemeMode.dark; // default

    if (value == 'light') {
      newMode = ThemeMode.light;
    } else if (value == 'dark') {
      newMode = ThemeMode.dark;
    } else if (value == 'auto') {
      newMode = ThemeMode.system;
    }

    if (mounted) {
      setState(() => _themeMode = newMode);
    }
  }

  Future<void> _toggleTheme() async {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyThemeMode,
      _themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  /// Change theme from preferences screen
  Future<void> changeTheme(String themeString) async {
    ThemeMode newMode;
    switch (themeString) {
      case 'light':
        newMode = ThemeMode.light;
        break;
      case 'dark':
        newMode = ThemeMode.dark;
        break;
      case 'auto':
        newMode = ThemeMode.system;
        break;
      default:
        newMode = ThemeMode.system;
    }

    setState(() {
      _themeMode = newMode;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, themeString);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VisionArt',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      home: _AppLoader(
        authService: widget.authService,
        onToggleTheme: _toggleTheme,
      ),
      routes: {
        '/preferences': (context) => PreferencesScreen(
          apiClient: null,
          onPreferencesUpdated: () {
            // Callback when preferences are updated
          },
        ),
      },
    );
  }
}

class _AppLoader extends StatefulWidget {
  const _AppLoader({required this.authService, required this.onToggleTheme});

  final AuthService authService;
  final VoidCallback onToggleTheme;

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  bool _showSplash = true;
  bool _initialized = false;
  Uint8List? _signatureBytes;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final bytes = await SignatureStorage.load();
    if (mounted)
      setState(() {
        _signatureBytes = bytes;
        _initialized = true;
      });
  }

  void _onSplashComplete() {
    if (mounted) setState(() => _showSplash = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_showSplash) {
      return SplashScreen(
        onComplete: _onSplashComplete,
        signatureBytes: _signatureBytes,
      );
    }
    return AuthGate(
      authService: widget.authService,
      onToggleTheme: widget.onToggleTheme,
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.authService,
    required this.onToggleTheme,
  });

  final AuthService authService;
  final VoidCallback onToggleTheme;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checked = false;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final ok = await widget.authService.isLoggedIn;
    if (mounted) {
      setState(() {
        _checked = true;
        _loggedIn = ok;
      });
    }
  }

  void _goHome() {
    setState(() => _loggedIn = true);
  }

  void _goLogin() {
    setState(() => _loggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loggedIn) {
      return HomeScreen(
        authService: widget.authService,
        onLogout: _goLogin,
        onToggleTheme: widget.onToggleTheme,
      );
    }
    return AuthScreen(
      authService: widget.authService,
      onSuccess: _goHome,
      onToggleTheme: widget.onToggleTheme,
    );
  }
}
