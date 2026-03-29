// ============================================================
//  main.dart
//  Ponto de entrada do Trackly.
//  Inicializa o Firebase e configura os Providers globais.
// ============================================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';
import 'providers/friends_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'utils/constants.dart';

Future<void> main() async {
  // Garante que o binding Flutter esteja pronto antes de usar plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase com as opções geradas pelo FlutterFire CLI
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TracklyApp());
}

class TracklyApp extends StatelessWidget {
  const TracklyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Autenticação — criado primeiro pois outros dependem do userId
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Localização — inicializado pela HomeScreen após login
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        // Amigos — inicializado pela HomeScreen após login
        ChangeNotifierProvider(create: (_) => FriendsProvider()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Roboto',
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

/// Decide qual tela exibir com base no estado de autenticação.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Aguarda o Firebase verificar o estado de autenticação persistido
    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 56, color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                AppStrings.appName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ],
          ),
        ),
      );
    }

    // Usuário autenticado → tela principal
    if (auth.isAuthenticated) return const HomeScreen();

    // Não autenticado → login
    return const LoginScreen();
  }
}
