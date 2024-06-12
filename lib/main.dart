import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/notifications_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService();
  await authService.checkAuthStatus(); // Espera a que se complete checkAuthStatus
  runApp(
    ChangeNotifierProvider(
      create: (context) => authService,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (!authService.isInitialized) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        return MaterialApp(
          title: 'Trade Monitoring App',
          theme: ThemeData(
            primarySwatch: Colors.green,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              color: Colors.green,
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20.0),
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(fontSize: 24.0, color: Colors.black),
              bodyLarge: TextStyle(fontSize: 18.0, color: Colors.black87),
            ),
            buttonTheme: const ButtonThemeData(
              buttonColor: Colors.green,
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          home: authService.isAuthenticated ? const HomePage() : const LoginPage(),
          routes: {
            '/login': (context) => const LoginPage(),
            '/home': (context) => const HomePage(),
            '/profile': (context) => const ProfilePage(),
            '/notifications': (context) => const NotificationsPage(),
          },
        );
      },
    );
  }
}
