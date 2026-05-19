import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _waterReminderEnabled = false;
  int _waterIntervalHours = 2;
  TimeOfDay _waterStartTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _waterEndTime = const TimeOfDay(hour: 22, minute: 0);

  bool _breakfastReminderEnabled = false;
  TimeOfDay _breakfastTime = const TimeOfDay(hour: 8, minute: 0);

  bool _lunchReminderEnabled = false;
  TimeOfDay _lunchTime = const TimeOfDay(hour: 13, minute: 0);

  bool _dinnerReminderEnabled = false;
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 19, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestPermissions());
  }

  Future<void> _requestPermissions() async {
    final notificationService =
        Provider.of<NotificationService>(context, listen: false);
    await notificationService.requestPermissions();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waterReminderEnabled = prefs.getBool('water_reminder_enabled') ?? false;
      _waterIntervalHours = prefs.getInt('water_interval_hours') ?? 2;
      _waterStartTime = TimeOfDay(
        hour: prefs.getInt('water_start_hour') ?? 8,
        minute: prefs.getInt('water_start_minute') ?? 0,
      );
      _waterEndTime = TimeOfDay(
        hour: prefs.getInt('water_end_hour') ?? 22,
        minute: prefs.getInt('water_end_minute') ?? 0,
      );

      _breakfastReminderEnabled =
          prefs.getBool('breakfast_reminder_enabled') ?? false;
      _breakfastTime = TimeOfDay(
        hour: prefs.getInt('breakfast_hour') ?? 8,
        minute: prefs.getInt('breakfast_minute') ?? 0,
      );

      _lunchReminderEnabled =
          prefs.getBool('lunch_reminder_enabled') ?? false;
      _lunchTime = TimeOfDay(
        hour: prefs.getInt('lunch_hour') ?? 13,
        minute: prefs.getInt('lunch_minute') ?? 0,
      );

      _dinnerReminderEnabled =
          prefs.getBool('dinner_reminder_enabled') ?? false;
      _dinnerTime = TimeOfDay(
        hour: prefs.getInt('dinner_hour') ?? 19,
        minute: prefs.getInt('dinner_minute') ?? 0,
      );
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationService =
        Provider.of<NotificationService>(context, listen: false);

    await prefs.setBool('water_reminder_enabled', _waterReminderEnabled);
    await prefs.setInt('water_interval_hours', _waterIntervalHours);
    await prefs.setInt('water_start_hour', _waterStartTime.hour);
    await prefs.setInt('water_start_minute', _waterStartTime.minute);
    await prefs.setInt('water_end_hour', _waterEndTime.hour);
    await prefs.setInt('water_end_minute', _waterEndTime.minute);

    await prefs.setBool('breakfast_reminder_enabled', _breakfastReminderEnabled);
    await prefs.setInt('breakfast_hour', _breakfastTime.hour);
    await prefs.setInt('breakfast_minute', _breakfastTime.minute);

    await prefs.setBool('lunch_reminder_enabled', _lunchReminderEnabled);
    await prefs.setInt('lunch_hour', _lunchTime.hour);
    await prefs.setInt('lunch_minute', _lunchTime.minute);

    await prefs.setBool('dinner_reminder_enabled', _dinnerReminderEnabled);
    await prefs.setInt('dinner_hour', _dinnerTime.hour);
    await prefs.setInt('dinner_minute', _dinnerTime.minute);

    try {
      await _scheduleNotifications(notificationService);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при сохранении расписания: $e')),
        );
      }
    }

    await notificationService.showImmediateNotification(
      'Уведомления настроены',
      'Расписание сохранено',
    );
  }

  Future<void> _scheduleNotifications(NotificationService notificationService) async {

    if (_waterReminderEnabled) {
      await _scheduleWaterReminders(notificationService);
    } else {
      // Cancel water reminders (ids 100-110)
      for (int i = 100; i <= 110; i++) {
        await notificationService.cancel(i);
      }
    }

    if (_breakfastReminderEnabled) {
      await notificationService.scheduleDailyAt(
        200, 'meal_reminder', 'Завтрак', 'Пора позавтракать!', true, _breakfastTime.hour, _breakfastTime.minute);
    } else {
      await notificationService.cancel(200);
    }

    if (_lunchReminderEnabled) {
      await notificationService.scheduleDailyAt(
        201, 'meal_reminder', 'Обед', 'Пора пообедать!', true, _lunchTime.hour, _lunchTime.minute);
    } else {
      await notificationService.cancel(201);
    }

    if (_dinnerReminderEnabled) {
      await notificationService.scheduleDailyAt(
        202, 'meal_reminder', 'Ужин', 'Пора поужинать!', true, _dinnerTime.hour, _dinnerTime.minute);
    } else {
      await notificationService.cancel(202);
    }
  }

  Future<void> _scheduleWaterReminders(
      NotificationService notificationService) async {
    // Cancel existing water reminders
    for (int i = 100; i <= 110; i++) {
      await notificationService.cancel(i);
    }

    int notificationId = 100;
    int currentHour = _waterStartTime.hour;
    int currentMinute = _waterStartTime.minute;

    while (notificationId <= 110) {
      if (currentHour > _waterEndTime.hour ||
          (currentHour == _waterEndTime.hour &&
              currentMinute > _waterEndTime.minute)) {
        break;
      }

      await notificationService.scheduleDailyAt(
        notificationId++, 'water_reminder', 'Напоминание о воде', 'Пора выпить воды!', true, currentHour, currentMinute);

      // Add interval
      currentMinute += (_waterIntervalHours * 60) % 60;
      currentHour += (_waterIntervalHours * 60) ~/ 60;
      if (currentMinute >= 60) {
        currentHour += 1;
        currentMinute -= 60;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки уведомлений'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              try {
                await _saveSettings();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Настройки сохранены')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          const SizedBox(height: 8),
          const Text('Напоминания о воде',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text('Включить напоминания о воде'),
            value: _waterReminderEnabled,
            onChanged: (val) => setState(() => _waterReminderEnabled = val),
          ),
          if (_waterReminderEnabled) ...[
            const SizedBox(height: 8),
            const Text('Интервал (часы):'),
            Slider(
              value: _waterIntervalHours.toDouble(),
              min: 1,
              max: 4,
              divisions: 3,
              label: '$_waterIntervalHours ч',
              onChanged: (val) =>
                  setState(() => _waterIntervalHours = val.toInt()),
            ),
            ListTile(
              title: const Text('Время начала'),
              trailing: Text(_waterStartTime.format(context)),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _waterStartTime,
                );
                if (picked != null) {
                  setState(() => _waterStartTime = picked);
                }
              },
            ),
            ListTile(
              title: const Text('Время окончания'),
              trailing: Text(_waterEndTime.format(context)),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _waterEndTime,
                );
                if (picked != null) {
                  setState(() => _waterEndTime = picked);
                }
              },
            ),
          ],
          const Divider(height: 32),
          const Text('Напоминания о приёмах пищи',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildMealTile(
            icon: Icons.wb_sunny,
            iconColor: Colors.orange,
            mealName: 'Завтрак',
            enabled: _breakfastReminderEnabled,
            time: _breakfastTime,
            onToggle: (val) => setState(() => _breakfastReminderEnabled = val),
            onTimeChanged: (t) => setState(() => _breakfastTime = t),
          ),
          const SizedBox(height: 8),
          _buildMealTile(
            icon: Icons.wb_cloudy,
            iconColor: Colors.amber,
            mealName: 'Обед',
            enabled: _lunchReminderEnabled,
            time: _lunchTime,
            onToggle: (val) => setState(() => _lunchReminderEnabled = val),
            onTimeChanged: (t) => setState(() => _lunchTime = t),
          ),
          const SizedBox(height: 8),
          _buildMealTile(
            icon: Icons.nights_stay,
            iconColor: Colors.indigo,
            mealName: 'Ужин',
            enabled: _dinnerReminderEnabled,
            time: _dinnerTime,
            onToggle: (val) => setState(() => _dinnerReminderEnabled = val),
            onTimeChanged: (t) => setState(() => _dinnerTime = t),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTile({
    required IconData icon,
    required Color iconColor,
    required String mealName,
    required bool enabled,
    required TimeOfDay time,
    required ValueChanged<bool> onToggle,
    required ValueChanged<TimeOfDay> onTimeChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mealName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                  Text(
                    enabled ? time.format(context) : 'Выключено',
                    style: TextStyle(
                      color: enabled ? Colors.grey[700] : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.access_time, size: 20),
              label: Text(time.format(context)),
              onPressed: enabled
                  ? () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: time,
                      );
                      if (picked != null) onTimeChanged(picked);
                    }
                  : null,
            ),
            Switch(
              value: enabled,
              onChanged: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}
