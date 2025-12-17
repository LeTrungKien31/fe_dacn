import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/water_tracking_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/meals_screen.dart';
import 'screens/meal_detail_screen.dart';
import 'screens/ingredients_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/profile_form_screen.dart';
import 'screens/statistics_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ================= TIMEZONE (BẮT BUỘC) =================
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

  // ================= NOTIFICATION =================
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: PHMApp()));
}

class PHMApp extends StatelessWidget {
  const PHMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());

          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterScreen());

          case '/dashboard':
          case '/home':
            return MaterialPageRoute(
              builder: (_) => const MainNavigationScreen(),
            );

          case '/water':
          case '/log/water':
            return MaterialPageRoute(
              builder: (_) => const WaterTrackingScreen(),
            );

          case '/activity':
          case '/log/activity':
            return MaterialPageRoute(builder: (_) => const ActivityScreen());

          case '/meals':
          case '/log/meal':
            return MaterialPageRoute(builder: (_) => const MealsScreen());

          case '/meal/detail':
            final meal = settings.arguments as MealModel?;
            return MaterialPageRoute(
              builder: (_) => MealDetailScreen(meal: meal),
            );

          case '/ingredients':
            return MaterialPageRoute(builder: (_) => const IngredientsScreen());

          case '/reminders':
            return MaterialPageRoute(builder: (_) => const RemindersScreen());

          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfileScreen());

          case '/profile/form':
            final existingProfile = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) =>
                  ProfileFormScreen(existingProfile: existingProfile),
            );

          case '/statistics':
            return MaterialPageRoute(builder: (_) => const StatisticsScreen());

          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }
}
