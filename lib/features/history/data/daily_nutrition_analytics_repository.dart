import 'package:hive/hive.dart';

class DailyNutritionAggregate {
  const DailyNutritionAggregate({
    required this.dateKey,
    required this.calories,
    required this.protein,
    required this.scans,
  });

  final String dateKey;
  final double calories;
  final double protein;
  final int scans;

  Map<String, dynamic> toMap() {
    return {'calories': calories, 'protein': protein, 'scans': scans};
  }

  static DailyNutritionAggregate fromMap(
    String dateKey,
    Map<dynamic, dynamic>? map,
  ) {
    if (map == null) {
      return DailyNutritionAggregate(
        dateKey: dateKey,
        calories: 0,
        protein: 0,
        scans: 0,
      );
    }

    return DailyNutritionAggregate(
      dateKey: dateKey,
      calories: (map['calories'] as num?)?.toDouble() ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0,
      scans: (map['scans'] as num?)?.toInt() ?? 0,
    );
  }
}

class DailyNutritionAnalyticsRepository {
  DailyNutritionAnalyticsRepository(this._box);

  static const boxName = 'daily_nutrition_analytics_box';
  final Box<dynamic> _box;

  Future<void> addEntry({
    required DateTime date,
    required double calories,
    required double protein,
  }) async {
    await _adjustEntry(
      date: date,
      caloriesDelta: calories,
      proteinDelta: protein,
      scansDelta: 1,
    );
  }

  Future<void> removeEntry({
    required DateTime date,
    required double calories,
    required double protein,
  }) async {
    await _adjustEntry(
      date: date,
      caloriesDelta: -calories,
      proteinDelta: -protein,
      scansDelta: -1,
    );
  }

  Map<String, DailyNutritionAggregate> getForDates(Iterable<DateTime> dates) {
    final result = <String, DailyNutritionAggregate>{};
    for (final date in dates) {
      final key = _dateKey(date);
      result[key] = _readEntry(key);
    }
    return result;
  }

  Map<String, DailyNutritionAggregate> getAll() {
    final result = <String, DailyNutritionAggregate>{};
    for (final key in _box.keys) {
      if (key is String) {
        result[key] = _readEntry(key);
      }
    }
    return result;
  }

  Future<void> _adjustEntry({
    required DateTime date,
    required double caloriesDelta,
    required double proteinDelta,
    required int scansDelta,
  }) async {
    final key = _dateKey(date);
    final current = _readEntry(key);

    final nextCalories = (current.calories + caloriesDelta).clamp(
      0.0,
      double.infinity,
    );
    final nextProtein = (current.protein + proteinDelta).clamp(
      0.0,
      double.infinity,
    );
    final nextScans = (current.scans + scansDelta).clamp(0, 1000000);

    if (nextCalories <= 0.0001 && nextProtein <= 0.0001 && nextScans == 0) {
      await _box.delete(key);
      return;
    }

    final updated = DailyNutritionAggregate(
      dateKey: key,
      calories: nextCalories,
      protein: nextProtein,
      scans: nextScans,
    );

    await _box.put(key, updated.toMap());
  }

  DailyNutritionAggregate _readEntry(String key) {
    final raw = _box.get(key);
    if (raw is Map) {
      return DailyNutritionAggregate.fromMap(key, raw);
    }
    return DailyNutritionAggregate.fromMap(key, null);
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
