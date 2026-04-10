import 'package:hive/hive.dart';

class WeeklyStatsRepository {
  WeeklyStatsRepository(this._box);

  static const boxName = 'weekly_stats_box';
  final Box<double> _box;

  Future<void> addCaloriesForDate(DateTime date, double calories) async {
    await _adjustCaloriesForDate(date, calories);
  }

  Future<void> subtractCaloriesForDate(DateTime date, double calories) async {
    await _adjustCaloriesForDate(date, -calories);
  }

  Future<void> _adjustCaloriesForDate(DateTime date, double delta) async {
    final key = _dateKey(date);
    final current = _box.get(key) ?? 0;
    final updated = current + delta;
    if (updated <= 0.0001) {
      await _box.delete(key);
      return;
    }
    await _box.put(key, updated);
  }

  Map<String, double> getCaloriesForDates(Iterable<DateTime> dates) {
    final result = <String, double>{};
    for (final date in dates) {
      final key = _dateKey(date);
      result[key] = _box.get(key) ?? 0;
    }
    return result;
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
