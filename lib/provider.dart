import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth/providers.dart';
import 'meal/data/meal_service.dart';
import 'activity/data/activity_service.dart';

// Re-export auth providers
export 'auth/providers.dart';

// Meal providers
final mealServiceProvider = Provider<MealService>((ref) {
  final dio = ref.read(dioClientProvider);
  return MealService(dio);
});

final todayMealKcalProvider = FutureProvider<int>((ref) async {
  return ref.watch(mealServiceProvider).todayKcal();
});

// Activity providers
final activityServiceProvider = Provider<ActivityService>((ref) {
  final dio = ref.read(dioClientProvider);
  return ActivityService(dio);
});

final todayKcalOutProvider = FutureProvider<int>((ref) async {
  return ref.watch(activityServiceProvider).todayKcalOut();
});