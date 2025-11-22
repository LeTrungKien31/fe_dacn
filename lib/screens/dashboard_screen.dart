import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Đã có sẵn trong dự án của bạn:
import '../auth/providers.dart'; // meProvider, dioClientProvider
import '../provider.dart'; // todayWaterProvider, todayMealKcalProvider, todayKcalOutProvider

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _St();
}

class _St extends ConsumerState<DashboardScreen> {
  Future<void> _pingOpen() async {
    try {
      final r = await ref.read(dioClientProvider).dio.get('/api/v1/ping');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ping: ${r.data}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ping lỗi: $e')));
    }
  }

  Future<void> _pingMe() async {
    try {
      final r = await ref.read(dioClientProvider).dio.get('/api/v1/ping/me');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ping/me: ${r.data}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ping/me lỗi: $e')));
    }
  }

  Future<void> _refresh() async {
    // làm mới 3 chỉ số
    ref.invalidate(todayWaterProvider);
    ref.invalidate(todayMealKcalProvider);
    ref.invalidate(todayKcalOutProvider);
  }

  @override
  Widget build(BuildContext ctx) {
    final me = ref.watch(meProvider); // chào tên user
    final water = ref.watch(todayWaterProvider); // ml
    final inKcal = ref.watch(todayMealKcalProvider); // kcal nạp
    final outKcal = ref.watch(todayKcalOutProvider); // kcal tiêu

    // ignore: no_leading_underscores_for_local_identifiers
    int? _net() {
      final i = inKcal.asData?.value;
      final o = outKcal.asData?.value;
      if (i == null || o == null) return null;
      return i - o;
    }

    return Scaffold(
      appBar: AppBar(
        title: me.when(
          data: (u) => Text('Chào, ${u['fullname'] ?? ''}'),
          loading: () => const Text('Dashboard'),
          error: (_, __) => const Text('Dashboard'),
        ),
        actions: [
          TextButton(
            onPressed: _pingOpen,
            child: const Text('Ping', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: _pingMe,
            child: const Text('Ping/me', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Ô chỉ số nước
            _metricCard(
              title: 'Nước hôm nay',
              value: water.when(
                data: (v) => '$v ml',
                loading: () => '...',
                error: (e, _) => 'lỗi',
              ),
            ),
            const SizedBox(height: 12),

            // Hai ô Kcal
            Row(
              children: [
                Expanded(
                  child: _metricCard(
                    title: 'Kcal nạp',
                    value: inKcal.when(
                      data: (v) => '$v',
                      loading: () => '...',
                      error: (e, _) => 'lỗi',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricCard(
                    title: 'Kcal tiêu',
                    value: outKcal.when(
                      data: (v) => '$v',
                      loading: () => '...',
                      error: (e, _) => 'lỗi',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _metricCard(title: 'Kcal net', value: _net()?.toString() ?? '...'),
            const SizedBox(height: 16),

            Text('Ghi nhanh', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pushNamed('/log/water'),
                    child: const Text('Ghi nước'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pushNamed('/log/meal'),
                    child: const Text('Ghi bữa ăn'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(ctx).pushNamed('/log/activity'),
                    child: const Text('Ghi vận động'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard({required String title, required String value}) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 22)),
          ],
        ),
      ),
    );
  }
}
