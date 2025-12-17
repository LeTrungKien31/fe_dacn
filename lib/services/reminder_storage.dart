import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class ReminderModel {
  final String id;
  final TimeOfDay time;
  final List<int> daysOfWeek;
  bool isEnabled;

  ReminderModel({
    required this.id,
    required this.time,
    required this.daysOfWeek,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'daysOfWeek': daysOfWeek,
      'isEnabled': isEnabled,
    };
  }

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] as String,
      time: TimeOfDay(
        hour: json['hour'] as int,
        minute: json['minute'] as int,
      ),
      daysOfWeek: List<int>.from(json['daysOfWeek'] as List),
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }
}

class ReminderStorage {
  static const String _key = 'water_reminders';

  Future<List<ReminderModel>> loadReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      
      if (jsonString == null || jsonString.isEmpty) {
        return _getDefaultReminders();
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => ReminderModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading reminders: $e');
      return _getDefaultReminders();
    }
  }

  Future<void> saveReminders(List<ReminderModel> reminders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = reminders.map((r) => r.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await prefs.setString(_key, jsonString);
    } catch (e) {
      debugPrint('Error saving reminders: $e');
    }
  }

  Future<void> addReminder(ReminderModel reminder) async {
    final reminders = await loadReminders();
    reminders.add(reminder);
    await saveReminders(reminders);
  }

  Future<void> updateReminder(String id, ReminderModel updatedReminder) async {
    final reminders = await loadReminders();
    final index = reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      reminders[index] = updatedReminder;
      await saveReminders(reminders);
    }
  }

  Future<void> deleteReminder(String id) async {
    final reminders = await loadReminders();
    reminders.removeWhere((r) => r.id == id);
    await saveReminders(reminders);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  List<ReminderModel> _getDefaultReminders() {
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
        time: const TimeOfDay(hour: 16, minute: 0),
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
}