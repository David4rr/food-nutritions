import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/history/data/daily_nutrition_analytics_repository.dart';
import '../features/history/data/history_repository.dart';
import '../features/history/data/weekly_stats_repository.dart';
import '../features/history/presentation/history_provider.dart';
import 'theme/app_style_controller.dart';

class FoodNutritionsApp extends StatefulWidget {
  const FoodNutritionsApp({
    super.key,
    required this.historyRepository,
    required this.weeklyStatsRepository,
    required this.dailyNutritionAnalyticsRepository,
  });

  final HistoryRepository historyRepository;
  final WeeklyStatsRepository weeklyStatsRepository;
  final DailyNutritionAnalyticsRepository dailyNutritionAnalyticsRepository;

  @override
  State<FoodNutritionsApp> createState() => _FoodNutritionsAppState();
}

class _FoodNutritionsAppState extends State<FoodNutritionsApp> {
  late final AppStyleController _appStyleController;

  @override
  void initState() {
    super.initState();
    _appStyleController = AppStyleController();
    _appStyleController.load();
  }

  @override
  void dispose() {
    _appStyleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HistoryProvider(
            widget.historyRepository,
            widget.weeklyStatsRepository,
            widget.dailyNutritionAnalyticsRepository,
          )..loadHistory(),
        ),
        ChangeNotifierProvider<AppStyleController>.value(
          value: _appStyleController,
        ),
      ],
      child: Consumer<AppStyleController>(
        builder: (context, appStyle, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Food Nutritions',
            theme: appStyle.themeData,
            home: const DashboardPage(),
          );
        },
      ),
    );
  }
}
