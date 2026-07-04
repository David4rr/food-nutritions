import 'package:hive/hive.dart';

import 'product_cache.dart';

class ProductCacheRepository {
  ProductCacheRepository(this._box);

  static const boxName = 'product_cache_box';
  final Box<ProductCache> _box;

  ProductCache? get(String barcode) {
    final cache = _box.get(barcode);
    if (cache == null) return null;

    if (cache.isExpired) {
      _box.delete(barcode);
      return null;
    }

    return cache;
  }

  Future<void> put(ProductCache cache) async {
    await _box.put(cache.barcode, cache);
  }

  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> clearExpired() async {
    final expiredKeys = <String>[];

    for (final entry in _box.toMap().entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      await _box.delete(key);
    }
  }
}
