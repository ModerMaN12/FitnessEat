import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'models/food_item.dart';
import 'models/meal.dart';
import 'models/goals.dart';
import 'models/meal_template.dart';
import 'models/water_entry.dart';
import 'providers/auth_provider.dart';
import 'providers/food_provider.dart';
import 'providers/meal_provider.dart';
import 'providers/goals_provider.dart';
import 'providers/template_provider.dart';
import 'providers/water_provider.dart';
import 'providers/sync_provider.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'utils/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  if (kIsWeb) {
    Hive.init('');
  } else {
    await Hive.initFlutter();
  }
  await initializeDateFormatting('ru_RU', null);
  Hive.registerAdapter(FoodItemAdapter());
  Hive.registerAdapter(IngredientAdapter());
  Hive.registerAdapter(MealItemAdapter());
  Hive.registerAdapter(MealAdapter());
  Hive.registerAdapter(GoalsAdapter());
  Hive.registerAdapter(MealTemplateAdapter());
  Hive.registerAdapter(TemplateItemAdapter());
  Hive.registerAdapter(WaterEntryAdapter());

  final supabase = Supabase.instance.client;
  final authService = AuthService(supabase);
  final connectivity = Connectivity();
  final syncService = SyncService(supabase, connectivity);
  final foodProvider = FoodProvider();
  final mealProvider = MealProvider();
  final goalsProvider = GoalsProvider();
  final templateProvider = TemplateProvider();
  final waterProvider = WaterProvider();
  final notificationService = NotificationService();

  await foodProvider.init();
  await mealProvider.init();
  await goalsProvider.init();
  await templateProvider.init();
  await waterProvider.init();
  await notificationService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: authService),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService),
        ),
        ChangeNotifierProvider.value(value: foodProvider),
        ChangeNotifierProvider.value(value: mealProvider),
        ChangeNotifierProvider.value(value: goalsProvider),
        ChangeNotifierProvider.value(value: templateProvider),
        ChangeNotifierProvider.value(value: waterProvider),
        Provider.value(value: syncService),
        ChangeNotifierProvider(create: (_) => SyncProvider(syncService)),
        Provider.value(value: notificationService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme') ?? 'system';
    setState(() {
      _themeMode = theme == 'dark'
          ? ThemeMode.dark
          : theme == 'light'
              ? ThemeMode.light
              : ThemeMode.system;
    });
  }

  void setTheme(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', mode.name);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eat Fitness',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          switch (auth.status) {
            case AuthStatus.authenticated:
              return HomeScreen(setTheme: setTheme, themeMode: _themeMode);
            case AuthStatus.uninitialized:
            case AuthStatus.loading:
              return const _SplashScreen();
            case AuthStatus.unauthenticated:
              return const LoginScreen();
          }
        },
      ),
      locale: const Locale('ru', 'RU'),
      supportedLocales: const [Locale('ru', 'RU'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
