import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/meal_provider.dart';
import '../providers/food_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/template_provider.dart';
import '../utils/data_export.dart';
import 'package:share_plus/share_plus.dart';

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
      final jsonString = await DataExport.exportToJson();
      if (kIsWeb) {
        DataExport.showDataDialog(context, jsonString, 'Экспорт JSON (скопируйте)');
      } else {
        final path = await DataExport.saveJsonFile(jsonString);
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _handleExportCsv(BuildContext context) async {
    try {
      final csvString = await DataExport.exportToCsv();
      if (kIsWeb) {
        DataExport.showDataDialog(context, csvString, 'Экспорт CSV (скопируйте)');
      } else {
        final path = await DataExport.saveCsvFile(csvString);
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _handleImportJson(BuildContext context) async {
    try {
      print('=== Starting import process ===');
      final data = await DataExport.importFromJson();
      if (data != null) {
        print('Data parsed successfully, applying...');
        await DataExport.applyImportedData(data);

        // Перезагружаем провайдеры чтобы обновить UI
        print('Reloading providers...');
        final foodProvider = Provider.of<FoodProvider>(context, listen: false);
        final mealProvider = Provider.of<MealProvider>(context, listen: false);
        final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);
        final templateProvider = Provider.of<TemplateProvider>(context, listen: false);

        foodProvider.reload();
        mealProvider.reload();
        goalsProvider.reload();
        templateProvider.reload();

        print('=== Import process complete ===');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Данные успешно импортированы и обновлены')),
        );
      } else {
        print('Import cancelled or no data');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Импорт отменен или файл не содержит данных')),
        );
      }
    } catch (e) {
      print('Import error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка импорта: $e')),
      );
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
