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
    await _box.delete(_itemKey(history));
  }

  Future<void> clear() async {
    await _box.clear();
  }

  String _itemKey(ProductHistory history) {
    return '${history.barcode}_${history.scanDate.toIso8601String()}';
  }
}
