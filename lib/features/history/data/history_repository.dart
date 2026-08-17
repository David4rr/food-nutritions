import 'package:hive/hive.dart';

import 'product_history.dart';

class HistoryRepository {
  HistoryRepository(this._box);

  static const boxName = 'product_history_box';
  final Box<ProductHistory> _box;

  List<ProductHistory> getAll() {
    final list = _box.values.toList(growable: false);
    list.sort((a, b) => b.scanDate.compareTo(a.scanDate));
    return list;
  }

  Future<void> add(ProductHistory history) async {
    await _box.put(_itemKey(history), history);
  }

  Future<void> remove(ProductHistory history) async {
    final key = _itemKey(history);
    if (_box.containsKey(key)) {
      await _box.delete(key);
      return;
    }

    // Fallback lookup: cari key yang cocok dengan barcode atau ISO string lama
    final targetEpoch = history.scanDate.millisecondsSinceEpoch;
    final keysToDelete = <dynamic>[];
    for (final k in _box.keys) {
      if (k is String && k.startsWith('${history.barcode}_')) {
        final val = _box.get(k);
        if (val != null &&
            (val.scanDate.millisecondsSinceEpoch - targetEpoch).abs() < 1000) {
          keysToDelete.add(k);
        }
      }
    }
    for (final k in keysToDelete) {
      await _box.delete(k);
    }
  }

  Future<void> clear() async {
    await _box.clear();
  }

  String _itemKey(ProductHistory history) {
    return '${history.barcode}_${history.scanDate.millisecondsSinceEpoch}';
  }
}
