import 'package:hive/hive.dart';
import '../domain/pantry_item.dart';

class PantryRepository {
  PantryRepository(this._box);

  static const boxName = 'pantry_items_box';
  final Box<dynamic> _box;

  List<PantryItem> getAll() {
    final items = <PantryItem>[];
    for (final key in _box.keys) {
      final value = _box.get(key);
      if (value is Map) {
        try {
          items.add(PantryItem.fromMap(value));
        } catch (_) {}
      }
    }
    // Sort active items first, then by added date descending
    items.sort((a, b) {
      if (a.isFinished != b.isFinished) {
        return a.isFinished ? 1 : -1;
      }
      return b.addedAt.compareTo(a.addedAt);
    });
    return items;
  }

  PantryItem? get(String id) {
    final value = _box.get(id);
    if (value is Map) {
      return PantryItem.fromMap(value);
    }
    return null;
  }

  Future<void> add(PantryItem item) async {
    await _box.put(item.id, item.toMap());
  }

  Future<void> update(PantryItem item) async {
    await _box.put(item.id, item.toMap());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
