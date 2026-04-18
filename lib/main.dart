import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'core/supabase/supabase_client.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'core/widgets/no_connection_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseClientInstance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AB Business AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
      ),
      home: StreamBuilder<List<ConnectivityResult>>(
        stream: Connectivity().onConnectivityChanged,
        builder: (context, connectivitySnapshot) {
          // While waiting for the first result, we can assume online to avoid a flicker
          // or show a loader if preferred. Let's proceed to Auth Guard for now.
          final results = connectivitySnapshot.data;
          
          if (connectivitySnapshot.connectionState == ConnectionState.active) {
            // Case where we are offline
            if (results == null || results.isEmpty || results.contains(ConnectivityResult.none)) {
              return const NoConnectionPage();
            }
          }

          // If online or still connecting, proceed with Auth Guard
          return StreamBuilder<AuthState>(
            stream: Supabase.instance.client.auth.onAuthStateChange,
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator(color: Color(0xFF00FFA3))),
                );
              }

              final session = authSnapshot.data?.session;
              if (session != null) {
                return const HomePage();
              } else {
                return const AuthPage();
              }
            },
          );
        },
      ),
    );
  }
}
