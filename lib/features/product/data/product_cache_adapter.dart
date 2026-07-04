import 'package:hive/hive.dart';

import 'product_cache.dart';

class ProductCacheAdapter extends TypeAdapter<ProductCache> {
  static const adapterTypeId = 2;

  @override
  int get typeId => adapterTypeId;

  @override
  ProductCache read(BinaryReader reader) {
    final barcode = reader.readString();
    final jsonDataLength = reader.readInt();
    final jsonData = <String, dynamic>{};

    for (var i = 0; i < jsonDataLength; i++) {
      final key = reader.readString();
      final value = reader.read();
      jsonData[key] = value;
    }

    final cachedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());

    return ProductCache(
      barcode: barcode,
      jsonData: jsonData,
      cachedAt: cachedAt,
      expiresAt: expiresAt,
    );
  }

  @override
  void write(BinaryWriter writer, ProductCache obj) {
    writer.writeString(obj.barcode);
    writer.writeInt(obj.jsonData.length);

    obj.jsonData.forEach((key, value) {
      writer.writeString(key);
      writer.write(value);
    });

    writer.writeInt(obj.cachedAt.millisecondsSinceEpoch);
    writer.writeInt(obj.expiresAt.millisecondsSinceEpoch);
  }
}
