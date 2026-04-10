import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

import '../../features/history/data/daily_nutrition_analytics_repository.dart';
import '../../features/history/data/history_repository.dart';
import '../../features/history/data/product_history.dart';
import '../../features/history/data/product_history_adapter.dart';
import '../../features/history/data/weekly_stats_repository.dart';

class AppDependencies {
  const AppDependencies({
    required this.historyRepository,
    required this.weeklyStatsRepository,
    required this.dailyNutritionAnalyticsRepository,
  });

  final HistoryRepository historyRepository;
  final WeeklyStatsRepository weeklyStatsRepository;
  final DailyNutritionAnalyticsRepository dailyNutritionAnalyticsRepository;
}

class AppBootstrap {
  Future<AppDependencies> initialize() async {
    return _initializeInternal().timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw TimeoutException(
        'Inisialisasi terlalu lama. Periksa data lokal (Hive) atau storage perangkat.',
      ),
    );
  }

  Future<AppDependencies> _initializeInternal() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(ProductHistoryAdapter.adapterTypeId)) {
      Hive.registerAdapter(ProductHistoryAdapter());
    }

    final box = await _openBoxWithRecovery<ProductHistory>(
      HistoryRepository.boxName,
    );
    final weeklyStatsBox = await _openBoxWithRecovery<double>(
      WeeklyStatsRepository.boxName,
    );
    final analyticsBox = await _openBoxWithRecovery<dynamic>(
      DailyNutritionAnalyticsRepository.boxName,
    );

    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'food_nutritions',
      version: '1.0.0',
    );

    return AppDependencies(
      historyRepository: HistoryRepository(box),
      weeklyStatsRepository: WeeklyStatsRepository(weeklyStatsBox),
      dailyNutritionAnalyticsRepository: DailyNutritionAnalyticsRepository(
        analyticsBox,
      ),
    );
  }

  Future<Box<T>> _openBoxWithRecovery<T>(String boxName) async {
    try {
      return await Hive.openBox<T>(boxName);
    } on HiveError {
      await Hive.deleteBoxFromDisk(boxName);
      return Hive.openBox<T>(boxName);
    }
  }
}
