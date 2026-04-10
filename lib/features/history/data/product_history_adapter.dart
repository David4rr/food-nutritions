import 'package:hive/hive.dart';

import 'product_history.dart';

class ProductHistoryAdapter extends TypeAdapter<ProductHistory> {
  static const int adapterTypeId = 0;

  @override
  final int typeId = ProductHistoryAdapter.adapterTypeId;

  @override
  ProductHistory read(BinaryReader reader) {
    final barcode = reader.readString();
    final name = reader.readString();
    final calories = reader.readDouble();
    final scanDate = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final protein = reader.readDouble();
    final fat = reader.readDouble();
    final imageUrl = reader.readString();

    double? estimatedCaloriesPerProduct;
    double? estimatedProteinPerProduct;
    try {
      final c = reader.readDouble();
      final p = reader.readDouble();
      estimatedCaloriesPerProduct = c >= 0 ? c : null;
      estimatedProteinPerProduct = p >= 0 ? p : null;
    } catch (_) {}

    return ProductHistory(
      barcode: barcode,
      name: name,
      calories: calories,
      scanDate: scanDate,
      protein: protein,
      fat: fat,
      imageUrl: imageUrl,
      estimatedCaloriesPerProduct: estimatedCaloriesPerProduct,
      estimatedProteinPerProduct: estimatedProteinPerProduct,
    );
  }

  @override
  void write(BinaryWriter writer, ProductHistory obj) {
    writer
      ..writeString(obj.barcode)
      ..writeString(obj.name)
      ..writeDouble(obj.calories)
      ..writeInt(obj.scanDate.millisecondsSinceEpoch)
      ..writeDouble(obj.protein)
      ..writeDouble(obj.fat)
      ..writeString(obj.imageUrl)
      ..writeDouble(obj.estimatedCaloriesPerProduct ?? -1)
      ..writeDouble(obj.estimatedProteinPerProduct ?? -1);
  }
}
