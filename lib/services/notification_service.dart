import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin? _notifications =
      kIsWeb ? null : FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) return;

    tz_data.initializeTimeZones();
    _detectTimezone();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications!.initialize(settings: settings);
    await _createChannels();
  }

  void _detectTimezone() {
    final offset = DateTime.now().timeZoneOffset;
    final totalMinutes = offset.inMinutes;

    if (totalMinutes == 180) {
      _trySetTimezone('Europe/Moscow', 'Etc/GMT-3');
    } else if (totalMinutes == 120) {
      _trySetTimezone('Europe/Kaliningrad', 'Etc/GMT-2');
    } else if (totalMinutes == 240) {
      _trySetTimezone('Europe/Samara', 'Etc/GMT-4');
    } else if (totalMinutes == 300) {
      _trySetTimezone('Asia/Yekaterinburg', 'Etc/GMT-5');
    } else if (totalMinutes == 360) {
      _trySetTimezone('Asia/Omsk', 'Etc/GMT-6');
    } else if (totalMinutes == 420) {
      _trySetTimezone('Asia/Krasnoyarsk', 'Etc/GMT-7');
    } else if (totalMinutes == 480) {
      _trySetTimezone('Asia/Irkutsk', 'Etc/GMT-8');
    } else if (totalMinutes == 540) {
      _trySetTimezone('Asia/Yakutsk', 'Etc/GMT-9');
    } else if (totalMinutes == 600) {
      _trySetTimezone('Asia/Vladivostok', 'Etc/GMT-10');
    } else if (totalMinutes == 660) {
      _trySetTimezone('Asia/Magadan', 'Etc/GMT-11');
    } else if (totalMinutes == 720) {
      _trySetTimezone('Asia/Kamchatka', 'Etc/GMT-12');
    } else if (totalMinutes == -300) {
      _trySetTimezone('America/New_York', 'Etc/GMT+5');
    } else if (totalMinutes == -480) {
      _trySetTimezone('America/Los_Angeles', 'Etc/GMT+8');
    } else if (totalMinutes == 0) {
      _trySetTimezone('UTC', 'Etc/GMT');
    } else {
      final sign = totalMinutes < 0 ? '+' : '-';
      final absHours = (totalMinutes.abs() / 60).floor();
      _trySetTimezone('Etc/GMT$sign$absHours', 'UTC');
    }
  }

  void _trySetTimezone(String primary, String fallback) {
    try {
      tz.setLocalLocation(tz.getLocation(primary));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation(fallback));
      } catch (_) {
        try {
          tz.setLocalLocation(tz.getLocation('UTC'));
        } catch (_) {}
      }
    }
  }

  Future<void> _createChannels() async {
    if (_notifications == null) return;

    final androidPlugin = _notifications!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    for (final channel in [
      const AndroidNotificationChannel(
          'water_reminder', 'Water Reminders',
          description: 'Reminders to drink water', importance: Importance.high),
      const AndroidNotificationChannel(
          'meal_reminder', 'Meal Reminders',
          description: 'Reminders for meals', importance: Importance.high),
      const AndroidNotificationChannel(
          'reminders', 'Reminders',
          description: 'App reminders', importance: Importance.high),
    ]) {
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  Future<void> requestPermissions() async {
    if (_notifications == null) return;

    final androidPlugin = _notifications!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    final iosPlugin = _notifications!
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> showImmediateNotification(String title, String body) async {
    if (_notifications == null) return;

    await _notifications!.show(
      id: 999,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
            'reminders', 'Reminders',
            channelDescription: 'App reminders',
            importance: Importance.high, priority: Priority.high),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> scheduleDailyAt(int id, String channel, String title,
      String body, bool enabled, int hour, int minute) async {
    if (_notifications == null) return;

    if (!enabled) {
      await _notifications!.cancel(id: id);
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    try {
      await _notifications!.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduled,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel,
            channel == 'water_reminder' ? 'Water Reminders' : 'Meal Reminders',
            channelDescription: channel == 'water_reminder'
                ? 'Reminders to drink water'
                : 'Reminders for meals',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexact,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
    }
  }

  Future<void> cancelAll() async {
    if (_notifications == null) return;
    await _notifications!.cancelAll();
  }

  Future<void> cancel(int id) async {
    if (_notifications == null) return;
    await _notifications!.cancel(id: id);
  }
}
