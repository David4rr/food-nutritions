import 'package:flutter/foundation.dart';

import '../../product/domain/product_view_data.dart';
import '../data/daily_nutrition_analytics_repository.dart';
import '../data/history_repository.dart';
import '../data/product_history.dart';
import '../data/weekly_stats_repository.dart';

class HistoryProvider extends ChangeNotifier {
  HistoryProvider(
    this._repository,
    this._weeklyStatsRepository,
    this._dailyAnalyticsRepository,
  );

  final HistoryRepository _repository;
  final WeeklyStatsRepository _weeklyStatsRepository;
  final DailyNutritionAnalyticsRepository _dailyAnalyticsRepository;
  final List<ProductHistory> _items = [];
  Map<String, double> _weeklyCalories = const {};
  Map<String, DailyNutritionAggregate> _dailyAnalytics = const {};
  bool _isLoading = false;

  List<ProductHistory> get items => List.unmodifiable(_items);
  Map<String, double> get weeklyCalories => _weeklyCalories;
  Map<String, DailyNutritionAggregate> get dailyAnalytics => _dailyAnalytics;
  bool get isLoading => _isLoading;

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();
    _items
      ..clear()
      ..addAll(_repository.getAll());
    _weeklyCalories = _loadLast7DaysCalories();
    _dailyAnalytics = _loadLast7DaysAnalytics();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addScan(ProductViewData data) async {
    final item = ProductHistory.fromViewData(data);
    await _repository.add(item);
    if (_isToday(item.scanDate)) {
      final itemCalories = item.estimatedCaloriesPerProduct ?? item.calories;
      await _weeklyStatsRepository.addCaloriesForDate(
        item.scanDate,
        itemCalories,
      );
      await _dailyAnalyticsRepository.addEntry(
        date: item.scanDate,
        calories: itemCalories,
        protein: item.estimatedProteinPerProduct ?? item.protein,
      );
    }
    _items.insert(0, item);
    _weeklyCalories = _loadLast7DaysCalories();
    _dailyAnalytics = _loadLast7DaysAnalytics();
    notifyListeners();
  }

  Future<void> removeItem(ProductHistory item) async {
    await _repository.remove(item);
    if (_isToday(item.scanDate)) {
      final itemCalories = item.estimatedCaloriesPerProduct ?? item.calories;
      await _weeklyStatsRepository.subtractCaloriesForDate(
        item.scanDate,
        itemCalories,
      );
      await _dailyAnalyticsRepository.removeEntry(
        date: item.scanDate,
        calories: itemCalories,
        protein: item.estimatedProteinPerProduct ?? item.protein,
      );
    }
    _items.removeWhere(
      (e) =>
          e.barcode == item.barcode &&
          e.scanDate.toIso8601String() == item.scanDate.toIso8601String(),
    );
    _weeklyCalories = _loadLast7DaysCalories();
    _dailyAnalytics = _loadLast7DaysAnalytics();
    notifyListeners();
  }

  Future<void> clear() async {
    await _repository.clear();
    _items.clear();
    notifyListeners();
  }

  Map<String, double> _loadLast7DaysCalories() {
    return _weeklyStatsRepository.getCaloriesForDates(_last7Days());
  }

  Map<String, DailyNutritionAggregate> _loadLast7DaysAnalytics() {
    return _dailyAnalyticsRepository.getForDates(_last7Days());
  }

  List<DateTime> _last7Days() {
    final now = DateTime.now();
    return List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }
}
