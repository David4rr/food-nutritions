import 'package:hive/hive.dart';
import 'meal_entry.dart';

class MealEntryRepository {
  MealEntryRepository(this._box);

  static const boxName = 'meal_entries_box';
  final Box<dynamic> _box;

  Future<void> add(MealEntry entry) async {
    await _box.put(entry.id, entry.toMap());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  List<MealEntry> getForDate(DateTime date) {
    final list = <MealEntry>[];
    for (final raw in _box.values) {
      if (raw is Map) {
        final entry = MealEntry.fromMap(raw);
        if (_isSameDay(entry.loggedAt, date)) {
          list.add(entry);
        }
      }
    }
    list.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    return list;
  }

  List<MealEntry> getAll() {
    final list = <MealEntry>[];
    for (final raw in _box.values) {
      if (raw is Map) {
        list.add(MealEntry.fromMap(raw));
      }
    }
    list.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    return list;
  }

  Future<void> clear() async {
    await _box.clear();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
