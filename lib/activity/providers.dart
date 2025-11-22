import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/activity_service.dart';
import '../auth/providers.dart'; // để dùng dioClientProvider

// Inject DioClient vào ActivityService
final activityServiceProvider = Provider<ActivityService>((ref) {
  final dioClient = ref.read(dioClientProvider);
  return ActivityService(dioClient);
});

// Tổng kcal tiêu hôm nay
final todayKcalOutProvider = FutureProvider<int>((ref) async {
  return ref.watch(activityServiceProvider).todayKcalOut();
});
