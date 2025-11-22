import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/providers.dart';
import 'data/meal_service.dart';

final mealServiceProvider = Provider((ref) => MealService(ref.read(dioClientProvider)));

final todayMealKcalProvider = FutureProvider<int>((ref) async {
  return ref.watch(mealServiceProvider).todayKcal();
});
