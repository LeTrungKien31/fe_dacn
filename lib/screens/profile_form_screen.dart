import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/profile_providers.dart';

class ProfileFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingProfile;

  const ProfileFormScreen({super.key, this.existingProfile});

  @override
  ConsumerState<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends ConsumerState<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String _gender = 'MALE';
  DateTime _dateOfBirth = DateTime(2000, 1, 1);
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  String _activityLevel = 'SEDENTARY';
  String _goal = 'MAINTAIN';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingProfile != null) {
      _loadExistingProfile();
    }
  }

  void _loadExistingProfile() {
    final p = widget.existingProfile!;
    _gender = p['gender'] ?? 'MALE';
    if (p['dateOfBirth'] != null) {
      try {
        _dateOfBirth = DateTime.parse(p['dateOfBirth']);
      } catch (e) {
        // ignore
      }
    }
    _heightController.text = (p['heightCm'] as num?)?.toString() ?? '';
    _weightController.text = (p['currentWeightKg'] as num?)?.toString() ?? '';
    _targetWeightController.text =
        (p['targetWeightKg'] as num?)?.toString() ?? '';
    _activityLevel = p['activityLevel'] ?? 'SEDENTARY';
    _goal = p['goal'] ?? 'MAINTAIN';
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(profileServiceProvider)
          .saveProfile(
            gender: _gender,
            dateOfBirth: _dateOfBirth.toIso8601String().split('T')[0],
            heightCm: double.parse(_heightController.text),
            currentWeightKg: double.parse(_weightController.text),
            targetWeightKg: _targetWeightController.text.isNotEmpty
                ? double.parse(_targetWeightController.text)
                : null,
            activityLevel: _activityLevel,
            goal: _goal,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu hồ sơ')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingProfile == null ? 'TẠO HỒ SƠ' : 'CẬP NHẬT HỒ SƠ',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Thông tin cơ bản'),
              const SizedBox(height: 16),
              _buildGenderSelector(),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _heightController,
                label: 'Chiều cao (cm)',
                suffix: 'cm',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _weightController,
                label: 'Cân nặng (kg)',
                suffix: 'kg',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _targetWeightController,
                label: 'Cân nặng mục tiêu (kg) - Tùy chọn',
                suffix: 'kg',
                keyboardType: TextInputType.number,
                required: false,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Hoạt động & Mục tiêu'),
              const SizedBox(height: 16),
              _buildActivityLevelSelector(),
              const SizedBox(height: 16),
              _buildGoalSelector(),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('LƯU HỒ SƠ', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Giới tính', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildRadioOption(
                'Nam',
                'MALE',
                _gender,
                (v) => setState(() => _gender = v!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRadioOption(
                'Nữ',
                'FEMALE',
                _gender,
                (v) => setState(() => _gender = v!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRadioOption(
    String label,
    String value,
    String groupValue,
    Function(String?) onChanged,
  ) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              // ignore: deprecated_member_use
              ? AppColors.primary.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Radio<String>(
              value: value,
              // ignore: deprecated_member_use
              groupValue: groupValue,
              // ignore: deprecated_member_use
              onChanged: onChanged,
            ),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dateOfBirth,
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() => _dateOfBirth = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ngày sinh: ${_dateOfBirth.day}/${_dateOfBirth.month}/${_dateOfBirth.year}',
              style: const TextStyle(fontSize: 16),
            ),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? suffix,
    TextInputType? keyboardType,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: required
          ? (v) {
              if (v == null || v.isEmpty) return 'Vui lòng nhập $label';
              if (double.tryParse(v) == null) return 'Giá trị không hợp lệ';
              return null;
            }
          : null,
    );
  }

  Widget _buildActivityLevelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mức độ vận động', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _activityLevel,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: const [
            DropdownMenuItem(value: 'SEDENTARY', child: Text('Ít vận động')),
            DropdownMenuItem(
              value: 'LIGHTLY_ACTIVE',
              child: Text('Vận động nhẹ'),
            ),
            DropdownMenuItem(
              value: 'MODERATELY_ACTIVE',
              child: Text('Vận động vừa'),
            ),
            DropdownMenuItem(
              value: 'VERY_ACTIVE',
              child: Text('Vận động nhiều'),
            ),
            DropdownMenuItem(
              value: 'EXTRA_ACTIVE',
              child: Text('Vận động cực nhiều'),
            ),
          ],
          onChanged: (v) => setState(() => _activityLevel = v!),
        ),
      ],
    );
  }

  Widget _buildGoalSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mục tiêu', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _goal,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: const [
            DropdownMenuItem(value: 'LOSE_WEIGHT', child: Text('Giảm cân')),
            DropdownMenuItem(value: 'MAINTAIN', child: Text('Duy trì')),
            DropdownMenuItem(value: 'GAIN_WEIGHT', child: Text('Tăng cân')),
          ],
          onChanged: (v) => setState(() => _goal = v!),
        ),
      ],
    );
  }
}
