import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/meal_provider.dart';
import '../providers/food_provider.dart';
import '../utils/data_export.dart';

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

  Widget _buildThemeSection(BuildContext context) {
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
      final result = await DataExport.exportToJson();
      if (kIsWeb) {
        _showJsonDialog(context, result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Сохранено: $result')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _handleExportCsv(BuildContext context) async {
    try {
      final result = await DataExport.exportToCsv();
      if (kIsWeb) {
        _showJsonDialog(context, result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Сохранено: $result')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _handleImportJson(BuildContext context) async {
    try {
      await DataExport.importFromJson(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _showJsonDialog(BuildContext context, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Данные (скопируйте)'),
        content: SingleChildScrollView(
          child: SelectableText(content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
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
        SwitchListTile(
          title: const Text('Напоминание о воде'),
          subtitle: const Text('Каждые 2 часа'),
          value: false,
          onChanged: (value) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Уведомления в разработке')),
            );
          },
        ),
        SwitchListTile(
          title: const Text('Напоминания о приемах пищи'),
          subtitle: const Text('Завтрак, обед, ужин'),
          value: false,
          onChanged: (value) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Уведомления в разработке')),
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
            child: const Text('Очистить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
