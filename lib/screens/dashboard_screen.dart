// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Future<void> _refresh() async {
    ref.invalidate(todayWaterProvider);
    ref.invalidate(todayMealKcalProvider);
    ref.invalidate(todayKcalOutProvider);
    ref.invalidate(meProvider);
  }

  // FIX: Sửa hàm logout để clear tất cả providers
  Future<void> _handleLogout() async {
    try {
      // Logout từ service
      await ref.read(authServiceProvider).logout();
      
      // Clear ALL providers
      ref.invalidate(meProvider);
      ref.invalidate(todayWaterProvider);
      ref.invalidate(todayMealKcalProvider);
      ref.invalidate(todayKcalOutProvider);
      
      if (mounted) {
        // Navigate to login và xóa toàn bộ navigation stack
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đăng xuất: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider);
    final water = ref.watch(todayWaterProvider);
    final inKcal = ref.watch(todayMealKcalProvider);
    final outKcal = ref.watch(todayKcalOutProvider);

    int? netKcal() {
      final i = inKcal.asData?.value;
      final o = outKcal.asData?.value;
      if (i == null || o == null) return null;
      return i - o;
    }

    return Scaffold(
      appBar: AppBar(
        title: me.when(
          data: (u) => Text('Chào, ${u['fullname'] ?? 'bạn'}'),
          loading: () => const Text('Tổng quan'),
          error: (_, __) => const Text('Tổng quan'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout, // FIX: Dùng hàm mới
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Today summary card
            _buildSummaryCard(water, inKcal, outKcal, netKcal()),
            const SizedBox(height: 20),
            
            // Quick actions
            Text('Ghi nhanh', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            
            // Stats cards
            Text('Hôm nay', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.water_drop,
                    iconColor: AppColors.waterBlue,
                    label: 'Nước',
                    value: water.when(
                      data: (v) => '$v ml',
                      loading: () => '...',
                      error: (_, __) => 'Lỗi',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.restaurant,
                    iconColor: Colors.orange,
                    label: 'Kcal nạp',
                    value: inKcal.when(
                      data: (v) => '$v',
                      loading: () => '...',
                      error: (_, __) => 'Lỗi',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.fitness_center,
                    iconColor: AppColors.primary,
                    label: 'Kcal tiêu',
                    value: outKcal.when(
                      data: (v) => '$v',
                      loading: () => '...',
                      error: (_, __) => 'Lỗi',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.balance,
                    iconColor: Colors.purple,
                    label: 'Kcal net',
                    value: netKcal()?.toString() ?? '...',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    AsyncValue<int> water,
    AsyncValue<int> inKcal,
    AsyncValue<int> outKcal,
    int? net,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan hôm nay',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                '💧',
                water.asData?.value.toString() ?? '...',
                'ml nước',
              ),
              _buildSummaryItem(
                '🔥',
                net?.toString() ?? '...',
                'Kcal net',
              ),
              _buildSummaryItem(
                '🏃',
                outKcal.asData?.value.toString() ?? '...',
                'Kcal tiêu',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          // ignore: deprecated_member_use
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.water_drop,
            color: AppColors.waterBlue,
            label: 'Uống nước',
            onTap: () async {
              await ref.read(waterServiceProvider).add(250);
              ref.invalidate(todayWaterProvider);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã ghi +250ml nước')),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionButton(
            icon: Icons.restaurant,
            color: Colors.orange,
            label: 'Ghi bữa ăn',
            onTap: () => Navigator.pushNamed(context, '/meals'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionButton(
            icon: Icons.fitness_center,
            color: AppColors.primary,
            label: 'Vận động',
            onTap: () => Navigator.pushNamed(context, '/activity'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}