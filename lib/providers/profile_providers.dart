// lib/providers/profile_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/providers.dart';
import '../services/profile_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  final dio = ref.read(dioClientProvider);
  return ProfileService(dio);
});

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    return await ref.watch(profileServiceProvider).getProfile();
  } catch (e) {
    return null;
  }
});

final healthInsightsProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    return await ref.watch(profileServiceProvider).getHealthInsights();
  } catch (e) {
    return null;
  }
});