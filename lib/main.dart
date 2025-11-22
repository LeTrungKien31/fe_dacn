import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/water_log_screen.dart';
import 'screens/meal_log_screen.dart';
import 'screens/activity_log_screen.dart';

void main() => runApp(const ProviderScope(child: PHMApp()));

class PHMApp extends StatelessWidget {
  const PHMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PHM',
      theme: ThemeData(useMaterial3: true),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/log/water': (_) => const WaterLogScreen(),
        '/log/meal': (_) => const MealLogScreen(),
        '/log/activity': (_) => const ActivityLogScreen(),
      },
    );
  }
}
