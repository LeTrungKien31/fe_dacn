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
    // Parse daysOfWeek with null safety
    List<int> parsedDays = [1, 2, 3, 4, 5, 6, 7]; // default to all days
    if (map['days'] != null) {
      final daysList = map['days'] as List<dynamic>?;
      if (daysList != null && daysList.isNotEmpty) {
        parsedDays = daysList.map((e) => e as int).toList();
      }
    }

    return ReminderModel(
      id: map['id'] as String,
      time: TimeOfDay(
        hour: map['hour'] as int? ?? 8,
        minute: map['minute'] as int? ?? 0,
      ),
      daysOfWeek: parsedDays,
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

  // ====== DEFAULT REMINDERS - FIX: Sửa giờ hợp lý ======
  List<ReminderModel> _buildDefaultReminders() {
    return [
      ReminderModel(
        id: '1',
        time: const TimeOfDay(hour: 8, minute: 0), // 8:00 AM
        daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
        isEnabled: true,
      ),
      ReminderModel(
        id: '2',
        time: const TimeOfDay(hour: 12, minute: 0), // 12:00 PM
        daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
        isEnabled: true,
      ),
      ReminderModel(
        id: '3',
        time: const TimeOfDay(hour: 16, minute: 0), // 4:00 PM
        daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
        isEnabled: true,
      ),
      ReminderModel(
        id: '4',
        time: const TimeOfDay(hour: 20, minute: 0), // 8:00 PM
        daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
        isEnabled: false,
      ),
    ];
  }

  // ====== PERSISTENCE ======
  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);

    if (jsonStr == null) {
      _reminders = _buildDefaultReminders();
      await _saveReminders();
      // FIX: Schedule notifications for enabled default reminders
      await _scheduleAllReminders();
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

  // FIX: Schedule all enabled reminders
  Future<void> _scheduleAllReminders() async {
    for (final reminder in _reminders) {
      if (reminder.isEnabled) {
        await _scheduleReminder(reminder);
      }
    }
  }

  // FIX: Schedule single reminder
  Future<void> _scheduleReminder(ReminderModel reminder) async {
    final intId = int.tryParse(reminder.id) ?? 0;
    await NotificationService.instance.scheduleDaily(
      id: intId,
      time: reminder.time,
      title: 'Đến giờ uống nước 💧',
      body: 'Hãy uống nước để giữ sức khỏe nhé!',
    );
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

            final newReminder = ReminderModel(
              id: newId,
              time: time,
              daysOfWeek: days.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : days,
              isEnabled: true,
            );

            setState(() {
              _reminders.add(newReminder);
            });

            await _saveReminders();
            await _scheduleReminder(newReminder);

            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Đã thêm nhắc nhở')));
            }
          },
        ),
      ),
    );
  }

  // FIX: Add delete reminder function
  Future<void> _deleteReminder(ReminderModel reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa nhắc nhở'),
        content: Text('Xóa nhắc nhở lúc ${_formatTime(reminder.time)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _reminders.removeWhere((r) => r.id == reminder.id);
      });

      await _saveReminders();

      // Cancel notification
      final intId = int.tryParse(reminder.id) ?? 0;
      await NotificationService.instance.cancel(intId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa nhắc nhở')));
      }
    }
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
                if (_reminders.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Chưa có nhắc nhở nào\nNhấn + để thêm',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  )
                else
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
    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => _deleteReminder(reminder),
      child: Container(
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
                  await _scheduleReminder(reminder);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã bật nhắc nhở')),
                    );
                  }
                } else {
                  await NotificationService.instance.cancel(intId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã tắt nhắc nhở')),
                    );
                  }
                }
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
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
  int _selectedHour = 8; // FIX: Default to 8 AM
  int _selectedMinute = 0;
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
          // FIX: Add day selector when repeat is enabled
          if (_repeat) ...[const SizedBox(height: 16), _buildDaySelector()],
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

  // FIX: Add day selector UI
  Widget _buildDaySelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.waterBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn ngày lặp lại',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDayChip('T2', 1),
                _buildDayChip('T3', 2),
                _buildDayChip('T4', 3),
                _buildDayChip('T5', 4),
                _buildDayChip('T6', 5),
                _buildDayChip('T7', 6),
                _buildDayChip('CN', 7),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayChip(String label, int day) {
    final isSelected = _selectedDays.contains(day);
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            if (_selectedDays.length > 1) {
              _selectedDays.remove(day);
            }
          } else {
            _selectedDays.add(day);
          }
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
