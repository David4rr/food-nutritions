import 'package:flutter/foundation.dart';

import '../../product/domain/product_view_data.dart';
import '../data/daily_nutrition_analytics_repository.dart';
import '../data/history_repository.dart';
import '../data/meal_entry.dart';
import '../data/meal_entry_repository.dart';
import '../data/product_history.dart';
import '../data/weekly_stats_repository.dart';

class HistoryProvider extends ChangeNotifier {
  HistoryProvider(
    this._repository,
    this._weeklyStatsRepository,
    this._dailyAnalyticsRepository,
    this._mealEntryRepository,
  );

  final HistoryRepository _repository;
  final WeeklyStatsRepository _weeklyStatsRepository;
  final DailyNutritionAnalyticsRepository _dailyAnalyticsRepository;
  final MealEntryRepository _mealEntryRepository;

  final List<ProductHistory> _items = [];
  final List<MealEntry> _todayMeals = [];
  Map<String, double> _weeklyCalories = const {};
  Map<String, DailyNutritionAggregate> _dailyAnalytics = const {};
  bool _isLoading = false;

  List<ProductHistory> get items => List.unmodifiable(_items);
  List<MealEntry> get todayMeals => List.unmodifiable(_todayMeals);
  Map<String, double> get weeklyCalories => _weeklyCalories;
  Map<String, DailyNutritionAggregate> get dailyAnalytics => _dailyAnalytics;
  bool get isLoading => _isLoading;

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();
    _items
      ..clear()
      ..addAll(_repository.getAll());
    _todayMeals
      ..clear()
      ..addAll(_mealEntryRepository.getForDate(DateTime.now()));
    _weeklyCalories = _loadLast7DaysCalories();
    _dailyAnalytics = _loadLast7DaysAnalytics();
    _isLoading = false;
    notifyListeners();
  }

  List<MealEntry> getMealsForDate(DateTime date) {
    return _mealEntryRepository.getForDate(date);
  }

  Future<void> addScan(ProductViewData data) async {
    if (_items.isNotEmpty &&
        _items.first.barcode == data.barcode &&
        DateTime.now().difference(_items.first.scanDate).inSeconds < 2) {
      return;
    }
    final item = ProductHistory.fromViewData(data);
    await _repository.add(item);
    _items.insert(0, item);
    notifyListeners();
  }

  Future<void> logMeal(MealEntry entry) async {
    await _mealEntryRepository.add(entry);
    await _weeklyStatsRepository.addCaloriesForDate(entry.loggedAt, entry.calories);
    await _dailyAnalyticsRepository.addEntry(
      date: entry.loggedAt,
      calories: entry.calories,
      protein: entry.protein,
      fat: entry.fat,
      carbs: entry.carbs,
      sugars: entry.sugars,
    );
    _todayMeals
      ..clear()
      ..addAll(_mealEntryRepository.getForDate(DateTime.now()));
    _weeklyCalories = _loadLast7DaysCalories();
    _dailyAnalytics = _loadLast7DaysAnalytics();
    notifyListeners();
  }

  Future<void> removeMeal(MealEntry entry) async {
    await _mealEntryRepository.delete(entry.id);
    await _weeklyStatsRepository.subtractCaloriesForDate(entry.loggedAt, entry.calories);
    await _dailyAnalyticsRepository.removeEntry(
      date: entry.loggedAt,
      calories: entry.calories,
      protein: entry.protein,
      fat: entry.fat,
      carbs: entry.carbs,
      sugars: entry.sugars,
    );
    _todayMeals
      ..clear()
      ..addAll(_mealEntryRepository.getForDate(DateTime.now()));
    _weeklyCalories = _loadLast7DaysCalories();
    _dailyAnalytics = _loadLast7DaysAnalytics();
    notifyListeners();
  }

  Future<void> logNutritionIntake({
    required DateTime date,
    required double calories,
    required double protein,
    double fat = 0,
    double carbs = 0,
    double sugars = 0,
  }) async {
    await _weeklyStatsRepository.addCaloriesForDate(date, calories);
    await _dailyAnalyticsRepository.addEntry(
      date: date,
      calories: calories,
      protein: protein,
      fat: fat,
      carbs: carbs,
      sugars: sugars,
    );
    _weeklyCalories = _loadLast7DaysCalories();
    _dailyAnalytics = _loadLast7DaysAnalytics();
    notifyListeners();
  }

  Future<void> removeNutritionIntake({
    required DateTime date,
    required double calories,
    required double protein,
    double fat = 0,
    double carbs = 0,
    double sugars = 0,
  }) async {
    await _weeklyStatsRepository.subtractCaloriesForDate(date, calories);
    await _dailyAnalyticsRepository.removeEntry(
      date: date,
      calories: calories,
      protein: protein,
      fat: fat,
      carbs: carbs,
      sugars: sugars,
    );
    _weeklyCalories = _loadLast7DaysCalories();
    _dailyAnalytics = _loadLast7DaysAnalytics();
    notifyListeners();
  }

  Future<void> removeItem(ProductHistory item) async {
    await _repository.remove(item);
    _items.removeWhere(
      (e) =>
          e.barcode == item.barcode &&
          e.scanDate.millisecondsSinceEpoch ==
              item.scanDate.millisecondsSinceEpoch,
    );
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

  Map<String, DailyNutritionAggregate> getAllAnalytics() {
    return _dailyAnalyticsRepository.getAll();
  }

  List<DateTime> _last7Days() {
    final now = DateTime.now();
    return List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
  }
}
