import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/supabase/supabase_client.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'core/widgets/no_connection_page.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Supabase
    await SupabaseClientInstance.initialize();

    // Load preferences
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    runApp(MyApp(hasSeenOnboarding: hasSeenOnboarding));
  } catch (e) {
    debugPrint('Critical Initialization Error: $e');
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Erreur critique au démarrage: $e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final bool hasSeenOnboarding;
  const MyApp({super.key, required this.hasSeenOnboarding});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<ConnectivityResult> _currentConnectivity = [];

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() => _currentConnectivity = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AB Business AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00FFA3),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
      ),
      builder: (context, child) {
        return StreamBuilder<List<ConnectivityResult>>(
          stream: Connectivity().onConnectivityChanged,
          builder: (context, snapshot) {
            final connectivityResults = snapshot.data ?? _currentConnectivity;

            // Si pas de résultats ou résultat "none", on affiche l'écran de blocage
            if (connectivityResults.isEmpty ||
                connectivityResults.contains(ConnectivityResult.none)) {
              return const NoConnectionPage();
            }

            return child ?? const SizedBox.shrink();
          },
        );
      },
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, authSnapshot) {
          final session =
              authSnapshot.data?.session ??
              Supabase.instance.client.auth.currentSession;

          if (authSnapshot.connectionState == ConnectionState.waiting &&
              session == null) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF00FFA3)),
              ),
            );
          }

          if (session != null) {
            return const HomePage();
          } else {
            // Si l'utilisateur a déjà vu l'onboarding, on l'envoie sur AuthPage direct
            return widget.hasSeenOnboarding
                ? const AuthPage()
                : const OnboardingPage();
          }
        },
      ),
    );
  }
}
