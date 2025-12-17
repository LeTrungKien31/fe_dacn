import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Convert id về 32-bit an toàn
  int _safeId(int id) {
    const maxId = 0x7FFFFFFF; // 2^31 - 1
    return id.abs() % maxId;
  }

  // ================= INIT =================

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    // Android 13+ cần xin quyền POST_NOTIFICATIONS
    if (Platform.isAndroid) {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    }
  }

  // ================= TIME HELPER =================

  /// Lấy thời điểm thông báo tiếp theo (nếu giờ đã qua → ngày mai)
  tz.TZDateTime _nextInstance(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // ================= SCHEDULE =================

  /// Thông báo đúng giờ + lặp mỗi ngày
  Future<void> scheduleDaily({
    required int id,
    required TimeOfDay time,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'water_channel',
      'Nhắc uống nước',
      channelDescription: 'Nhắc nhở uống nước hằng ngày',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    final safeId = _safeId(id);

    // Xóa notification cũ trước khi tạo mới (tránh trùng)
    await _plugin.cancel(safeId);

    await _plugin.zonedSchedule(
      safeId,
      title,
      body,
      _nextInstance(time),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // lặp mỗi ngày
    );
  }

  // ================= CANCEL =================

  Future<void> cancel(int id) async {
    await _plugin.cancel(_safeId(id));
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
