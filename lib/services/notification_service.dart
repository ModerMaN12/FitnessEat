import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    _detectTimezone();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings: settings);
    await _createChannels();
  }

  void _detectTimezone() {
    // Map UTC offset to IANA timezone name (with DST handling)
    final offset = DateTime.now().timeZoneOffset;
    final totalMinutes = offset.inMinutes;

    if (totalMinutes == 180) { // UTC+3
      _trySetTimezone('Europe/Moscow', 'Etc/GMT-3');
    } else if (totalMinutes == 120) { // UTC+2
      _trySetTimezone('Europe/Kaliningrad', 'Etc/GMT-2');
    } else if (totalMinutes == 240) { // UTC+4
      _trySetTimezone('Europe/Samara', 'Etc/GMT-4');
    } else if (totalMinutes == 300) { // UTC+5
      _trySetTimezone('Asia/Yekaterinburg', 'Etc/GMT-5');
    } else if (totalMinutes == 360) { // UTC+6
      _trySetTimezone('Asia/Omsk', 'Etc/GMT-6');
    } else if (totalMinutes == 420) { // UTC+7
      _trySetTimezone('Asia/Krasnoyarsk', 'Etc/GMT-7');
    } else if (totalMinutes == 480) { // UTC+8
      _trySetTimezone('Asia/Irkutsk', 'Etc/GMT-8');
    } else if (totalMinutes == 540) { // UTC+9
      _trySetTimezone('Asia/Yakutsk', 'Etc/GMT-9');
    } else if (totalMinutes == 600) { // UTC+10
      _trySetTimezone('Asia/Vladivostok', 'Etc/GMT-10');
    } else if (totalMinutes == 660) { // UTC+11
      _trySetTimezone('Asia/Magadan', 'Etc/GMT-11');
    } else if (totalMinutes == 720) { // UTC+12
      _trySetTimezone('Asia/Kamchatka', 'Etc/GMT-12');
    } else if (totalMinutes == -300) { // UTC-5 (US Eastern)
      _trySetTimezone('America/New_York', 'Etc/GMT+5');
    } else if (totalMinutes == -480) { // UTC-8 (US Pacific)
      _trySetTimezone('America/Los_Angeles', 'Etc/GMT+8');
    } else if (totalMinutes == 0) { // UTC
      _trySetTimezone('UTC', 'Etc/GMT');
    } else {
      // Generic fallback: Etc/GMT+/-X (note: sign is inverted in Etc notation)
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
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
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
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> showImmediateNotification(String title, String body) async {
    await _notifications.show(
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
    if (!enabled) {
      await _notifications.cancel(id: id);
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // Use inexact (no SCHEDULE_EXACT_ALARM permission needed).
    // On the Java side this uses: alarmManager.set(RTC_WAKEUP, epochMilli, pendingIntent)
    // which is the simplest possible alarm — no permission checks.
    try {
      await _notifications.zonedSchedule(
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
      // ignore scheduling errors silently — alarms are best-effort
    }
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _notifications.cancel(id: id);
  }
}
