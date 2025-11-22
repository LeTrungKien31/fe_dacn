import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider.dart';

class ActivityLogScreen extends ConsumerWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outKcal = ref.watch(todayKcalOutProvider);

    // ignore: no_leading_underscores_for_local_identifiers
    Future<void> _add() async {
      await ref
          .read(activityServiceProvider)
          .add(name: 'Chạy bộ', met: 7.5, minutes: 20, weightKg: 65);
      ref.invalidate(todayKcalOutProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã ghi chạy bộ 20p')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ghi vận động')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            outKcal.when(
              data: (x) => Text(
                'Kcal tiêu hôm nay: $x',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              loading: () => const Text('Đang tải...'),
              error: (e, _) => Text('Lỗi: $e'),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _add, child: const Text('Chạy bộ 20 phút')),
          ],
        ),
      ),
    );
  }
}
