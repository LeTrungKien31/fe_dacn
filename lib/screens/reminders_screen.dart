// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import '../services/notification_service.dart';

class ReminderModel {
  final String id;
  final TimeOfDay time;
  final List<int> daysOfWeek; // 1=Mon, 7=Sun
  bool isEnabled;

  ReminderModel({
    required this.id,
    required this.time,
    required this.daysOfWeek,
    this.isEnabled = true,
  });

  // ==== Serialize / Deserialize để lưu SharedPreferences ====

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'days': daysOfWeek,
      'enabled': isEnabled,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'] as String,
      time: TimeOfDay(hour: map['hour'] as int, minute: map['minute'] as int),
      daysOfWeek: (map['days'] as List<dynamic>).map((e) => e as int).toList(),
      isEnabled: map['enabled'] as bool? ?? true,
    );
  }
}

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});
  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  static const _storageKey = 'water_reminders';

  List<ReminderModel> _reminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  // ====== Persistence ======

  List<ReminderModel> _buildDefaultReminders() {
    return [
      ReminderModel(
        id: '1',
        time: const TimeOfDay(hour: 7, minute: 20),
        daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
        isEnabled: true,
      ),
      ReminderModel(
        id: '2',
        time: const TimeOfDay(hour: 10, minute: 50),
        daysOfWeek: [2, 4, 6],
        isEnabled: true,
      ),
      ReminderModel(
        id: '3',
        time: const TimeOfDay(hour: 4, minute: 0),
        daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
        isEnabled: true,
      ),
      ReminderModel(
        id: '4',
        time: const TimeOfDay(hour: 22, minute: 0),
        daysOfWeek: [2, 4, 5, 6],
        isEnabled: false,
      ),
    ];
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);

    if (jsonStr == null) {
      // Chưa có dữ liệu -> dùng default
      _reminders = _buildDefaultReminders();
      await _saveReminders();
    } else {
      final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
      _reminders = list
          .map((e) => ReminderModel.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _reminders.map((e) => e.toMap()).toList();
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  // ====== UI helpers ======

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDays(List<int> days) {
    if (days.length == 7) return 'Mỗi ngày';
    final dayNames = ['', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return days.map((d) => dayNames[d]).join(' ');
  }

  void _showAddReminderDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetReminderScreen(
          onSave: (time, days) async {
            final newId = DateTime.now().millisecondsSinceEpoch.toString();

            setState(() {
              _reminders.add(
                ReminderModel(
                  id: newId,
                  time: time,
                  daysOfWeek: days.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : days,
                ),
              );
            });

            await _saveReminders();

            // Đặt thông báo demo
            await NotificationService.instance.scheduleDaily(
              id: int.tryParse(newId) ?? 0,
              time: time,
              title: 'Đến giờ uống nước 💧',
              body: 'Hãy uống nước để giữ sức khỏe nhé!',
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('THÔNG BÁO'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 20),
                // Water glass icon
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.waterBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('💧', style: TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _reminders.length,
                    itemBuilder: (ctx, index) =>
                        _buildReminderCard(_reminders[index]),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildReminderCard(ReminderModel reminder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTime(reminder.time),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDays(reminder.daysOfWeek),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: reminder.isEnabled,
            onChanged: (value) async {
              setState(() {
                reminder.isEnabled = value;
              });
              await _saveReminders();

              final intId = int.tryParse(reminder.id) ?? 0;

              if (value) {
                await NotificationService.instance.scheduleDaily(
                  id: intId,
                  time: reminder.time,
                  title: 'Đến giờ uống nước 💧',
                  body: 'Hãy uống nước để giữ sức khỏe nhé!',
                );
              } else {
                await NotificationService.instance.cancel(intId);
              }
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class SetReminderScreen extends StatefulWidget {
  final Function(TimeOfDay time, List<int> days) onSave;

  const SetReminderScreen({super.key, required this.onSave});

  @override
  State<SetReminderScreen> createState() => _SetReminderScreenState();
}

class _SetReminderScreenState extends State<SetReminderScreen> {
  int _selectedHour = 4;
  int _selectedMinute = 50;
  final Set<int> _selectedDays = {1, 2, 3, 4, 5, 6, 7};
  bool _repeat = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('THIẾT LẬP THÔNG BÁO'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          const Text(
            'Chọn thời gian',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Text(
            '${_selectedHour.toString().padLeft(2, '0')} : ${_selectedMinute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('giờ', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(width: 60),
              Text('phút', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 30),
          _buildTimePicker('Chọn giờ:', _selectedHour, (val) {
            setState(() => _selectedHour = val);
          }, 24),
          const SizedBox(height: 16),
          _buildTimePicker('Chọn phút:', _selectedMinute, (val) {
            setState(() => _selectedMinute = val);
          }, 60),
          const SizedBox(height: 16),
          _buildRepeatOption(),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    child: const Text('HỦY BỎ'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final time = TimeOfDay(
                        hour: _selectedHour,
                        minute: _selectedMinute,
                      );
                      final days = _repeat ? _selectedDays.toList() : <int>[];

                      widget.onSave(time, days);

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã thiết lập nhắc nhở')),
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('THIẾT LẬP'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTimePicker(
    String label,
    int value,
    Function(int) onChanged,
    int max,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.waterBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Text('🕐', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            DropdownButton<int>(
              value: value,
              underline: const SizedBox(),
              items: List.generate(
                max,
                (i) => DropdownMenuItem(
                  value: i,
                  child: Text(i.toString().padLeft(2, '0')),
                ),
              ),
              onChanged: (val) => onChanged(val ?? 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatOption() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.waterBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Text('🔄', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            const Text('Lặp lại', style: TextStyle(fontSize: 16)),
            const Spacer(),
            Switch(
              value: _repeat,
              onChanged: (val) => setState(() => _repeat = val),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
