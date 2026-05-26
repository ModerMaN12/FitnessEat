import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/food_provider.dart';
import '../providers/meal_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/template_provider.dart';
import '../providers/sync_provider.dart';
import '../utils/data_export.dart';
import 'notification_settings_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  final Function(ThemeMode) setTheme;
  final ThemeMode themeMode;

  const SettingsScreen(
      {super.key, required this.setTheme, required this.themeMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        children: [
          _buildAccountSection(context),
          const Divider(),
          _buildSyncSection(context),
          const Divider(),
          _buildThemeSection(context),
          const Divider(),
          _buildDataSection(context),
          const Divider(),
          _buildNotificationsSection(context),
          const Divider(),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Аккаунт',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ListTile(
          leading: CircleAvatar(
            child: Icon(Icons.person, color: Colors.white),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          title: Text(auth.user?.email ?? 'Неизвестный'),
          subtitle: const Text('Авторизован'),
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Выйти', style: TextStyle(color: Colors.red)),
          onTap: () => _handleLogout(context),
        ),
      ],
    );
  }

  void _handleLogout(BuildContext context) async {
    await context.read<AuthProvider>().signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildSyncSection(BuildContext context) {
    final sync = context.watch<SyncProvider>();
    final lastSync = sync.lastSyncAt;
    final locale = const Locale('ru', 'RU');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Синхронизация',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ListTile(
          leading: Icon(
            sync.isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: sync.isOnline ? Colors.green : Colors.red,
          ),
          title: Text(sync.isOnline ? 'Подключено к серверу' : 'Нет подключения'),
          subtitle: lastSync != null
              ? Text(
                  'Последняя синхронизация: ${DateFormat('dd.MM.yyyy HH:mm', locale.languageCode).format(lastSync)}')
              : const Text('Синхронизация не выполнялась'),
        ),
        if (sync.isSyncing)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              sync.currentStage,
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: sync.isSyncing || !sync.isOnline
                  ? null
                  : () => sync.sync(),
              icon: sync.isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(sync.isSyncing
                  ? 'Синхронизация...'
                  : 'Синхронизировать'),
            ),
          ),
        ),
        if (!sync.isSyncing && sync.pushedCount + sync.pulledCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Отправлено: ${sync.pushedCount}, получено: ${sync.pulledCount}',
              style: const TextStyle(fontSize: 13, color: Colors.green),
            ),
          ),
        if (sync.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              sync.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    final themeMode = this.themeMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Тема оформления',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Системная'),
          value: ThemeMode.system,
          groupValue: themeMode,
          onChanged: (value) => setTheme(value!),
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Светлая'),
          value: ThemeMode.light,
          groupValue: themeMode,
          onChanged: (value) => setTheme(value!),
        ),
        RadioListTile<ThemeMode>(
          title: const Text('Темная'),
          value: ThemeMode.dark,
          groupValue: themeMode,
          onChanged: (value) => setTheme(value!),
        ),
      ],
    );
  }

  Widget _buildDataSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Управление данными',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ListTile(
          leading: const Icon(Icons.file_download),
          title: const Text('Экспорт в JSON'),
          subtitle: const Text('Полный бэкап данных'),
          onTap: () => _handleExportJson(context),
        ),
        ListTile(
          leading: const Icon(Icons.file_download),
          title: const Text('Экспорт в CSV'),
          subtitle: const Text('Для открытия в Excel'),
          onTap: () => _handleExportCsv(context),
        ),
        ListTile(
          leading: const Icon(Icons.file_upload),
          title: const Text('Импорт данных'),
          subtitle: const Text('Восстановление из бэкапа'),
          onTap: () => _handleImportJson(context),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('Очистить все данные',
              style: TextStyle(color: Colors.red)),
          onTap: () => _showClearDataDialog(context),
        ),
      ],
    );
  }

  void _handleExportJson(BuildContext context) async {
    try {
      final jsonString = await DataExport.exportToJson();
      if (kIsWeb) {
        DataExport.showDataDialog(
            context, jsonString, 'Экспорт JSON (скопируйте)');
      } else {
        final path = await DataExport.saveJsonFile(jsonString);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Сохранено: $path'),
              action: SnackBarAction(
                label: 'Поделиться',
                onPressed: () => DataExport.shareFile(path),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  void _handleExportCsv(BuildContext context) async {
    try {
      final csvString = await DataExport.exportToCsv();
      if (kIsWeb) {
        DataExport.showDataDialog(
            context, csvString, 'Экспорт CSV (скопируйте)');
      } else {
        final path = await DataExport.saveCsvFile(csvString);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Сохранено: $path'),
              action: SnackBarAction(
                label: 'Поделиться',
                onPressed: () => DataExport.shareFile(path),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  void _handleImportJson(BuildContext context) async {
    try {
      final data = await DataExport.importFromJson();
      if (data != null) {
        await DataExport.applyImportedData(data);

        final foodProvider = Provider.of<FoodProvider>(context, listen: false);
        final mealProvider = Provider.of<MealProvider>(context, listen: false);
        final goalsProvider =
            Provider.of<GoalsProvider>(context, listen: false);
        final templateProvider =
            Provider.of<TemplateProvider>(context, listen: false);

        foodProvider.reload();
        mealProvider.reload();
        goalsProvider.reload();
        templateProvider.reload();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Данные успешно импортированы и обновлены')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Импорт отменен или файл не содержит данных')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка импорта: $e')),
        );
      }
    }
  }

  Widget _buildNotificationsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Уведомления',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Настройки уведомлений'),
          subtitle: const Text('Вода и приемы пищи'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationSettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('О приложении',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const ListTile(
          leading: Icon(Icons.info),
          title: Text('Eat Fitness'),
          subtitle: Text('Версия 1.0.0'),
        ),
      ],
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить данные?'),
        content: const Text(
            'Это действие удалит все продукты и приемы пищи. Это нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final foodProvider =
                  Provider.of<FoodProvider>(context, listen: false);
              final mealProvider =
                  Provider.of<MealProvider>(context, listen: false);

              foodProvider.deleteFood('');
              for (var meal in mealProvider.meals) {
                mealProvider.deleteMeal(meal.id);
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Данные очищены')),
              );
            },
            child:
                const Text('Очистить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
