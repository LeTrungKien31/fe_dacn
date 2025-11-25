import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/provider.dart';
import '../theme/app_theme.dart';
import '../providers/profile_providers.dart';
import '../auth/providers.dart'; // FIX: Import để có thể logout
import 'profile_form_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 25) return 'Bình thường';
    if (bmi < 30) return 'Thừa cân';
    return 'Béo phì';
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  // FIX: Thêm hàm logout
  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        // Logout từ service
        await ref.read(authServiceProvider).logout();
        
        // Clear ALL providers
        ref.invalidate(meProvider);
        ref.invalidate(todayWaterProvider);
        ref.invalidate(todayMealKcalProvider);
        ref.invalidate(todayKcalOutProvider);
        ref.invalidate(userProfileProvider);
        ref.invalidate(healthInsightsProvider);
        
        if (context.mounted) {
          // Navigate to login và xóa toàn bộ navigation stack
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false, // Remove all previous routes
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi đăng xuất: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final insights = ref.watch(healthInsightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HỒ SƠ CÁ NHÂN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileFormScreen(
                    existingProfile: profile.asData?.value,
                  ),
                ),
              ).then((_) {
                ref.invalidate(userProfileProvider);
                ref.invalidate(healthInsightsProvider);
              });
            },
          ),
          // FIX: Thêm nút logout
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context, ref),
          ),
        ],
      ),
      body: profile.when(
        data: (data) {
          if (data == null) {
            return _buildNoProfile(context);
          }
          return _buildProfileContent(context, data, insights.asData?.value);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildNoProfile(context),
      ),
    );
  }

  Widget _buildNoProfile(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Chưa có hồ sơ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Tạo hồ sơ để theo dõi sức khỏe',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileFormScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Tạo hồ sơ'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    Map<String, dynamic> profile,
    Map<String, dynamic>? insights,
  ) {
    final bmi = profile['bmi'] as double? ?? 0;
    final heightCm = profile['heightCm'] as double? ?? 0;
    final currentWeight = profile['currentWeightKg'] as double? ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BMI Card
          _buildBMICard(bmi, _getBMICategory(bmi), _getBMIColor(bmi)),
          const SizedBox(height: 20),

          // Basic Info
          _buildSectionTitle('Thông tin cơ bản'),
          const SizedBox(height: 12),
          _buildInfoCard([
            _buildInfoRow('Giới tính', _getGenderText(profile['gender'])),
            _buildInfoRow('Tuổi', _calculateAge(profile['dateOfBirth'])),
            _buildInfoRow('Chiều cao', '${heightCm.toInt()} cm'),
            _buildInfoRow('Cân nặng', '${currentWeight.toStringAsFixed(1)} kg'),
            if (profile['targetWeightKg'] != null)
              _buildInfoRow(
                'Mục tiêu',
                '${(profile['targetWeightKg'] as double).toStringAsFixed(1)} kg',
              ),
          ]),

          const SizedBox(height: 20),

          // Health Metrics
          if (insights != null) ...[
            _buildSectionTitle('Chỉ số sức khỏe'),
            const SizedBox(height: 12),
            _buildMetricsGrid(insights),
            const SizedBox(height: 20),
          ],

          // Activity & Goal
          _buildSectionTitle('Hoạt động & Mục tiêu'),
          const SizedBox(height: 12),
          _buildInfoCard([
            _buildInfoRow(
              'Mức độ vận động',
              _getActivityLevelText(profile['activityLevel']),
            ),
            _buildInfoRow('Mục tiêu', _getGoalText(profile['goal'])),
          ]),
        ],
      ),
    );
  }

  Widget _buildBMICard(double bmi, String category, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          // ignore: deprecated_member_use
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'CHỈ SỐ BMI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            bmi.toStringAsFixed(2),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
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
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> insights) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildMetricCard(
          'BMR',
          '${(insights['bmr'] as double?)?.toInt() ?? 0}',
          'kcal/ngày',
          AppColors.primary,
        ),
        _buildMetricCard(
          'TDEE',
          '${(insights['tdee'] as double?)?.toInt() ?? 0}',
          'kcal/ngày',
          AppColors.accent,
        ),
        _buildMetricCard(
          'Mục tiêu kcal',
          '${insights['dailyCalorieGoal'] ?? 0}',
          'kcal/ngày',
          Colors.orange,
        ),
        _buildMetricCard(
          'Mục tiêu nước',
          '${insights['dailyWaterGoalMl'] ?? 0}',
          'ml/ngày',
          AppColors.waterBlue,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unit,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _getGenderText(String? gender) {
    switch (gender?.toUpperCase()) {
      case 'MALE':
        return 'Nam';
      case 'FEMALE':
        return 'Nữ';
      default:
        return 'Khác';
    }
  }

  String _calculateAge(String? dateOfBirth) {
    if (dateOfBirth == null) return 'N/A';
    try {
      final dob = DateTime.parse(dateOfBirth);
      final age = DateTime.now().year - dob.year;
      return '$age tuổi';
    } catch (e) {
      return 'N/A';
    }
  }

  String _getActivityLevelText(String? level) {
    switch (level?.toUpperCase()) {
      case 'SEDENTARY':
        return 'Ít vận động';
      case 'LIGHTLY_ACTIVE':
        return 'Vận động nhẹ';
      case 'MODERATELY_ACTIVE':
        return 'Vận động vừa';
      case 'VERY_ACTIVE':
        return 'Vận động nhiều';
      case 'EXTRA_ACTIVE':
        return 'Vận động cực nhiều';
      default:
        return 'N/A';
    }
  }

  String _getGoalText(String? goal) {
    switch (goal?.toUpperCase()) {
      case 'LOSE_WEIGHT':
        return 'Giảm cân';
      case 'MAINTAIN':
        return 'Duy trì';
      case 'GAIN_WEIGHT':
        return 'Tăng cân';
      default:
        return 'N/A';
    }
  }
}