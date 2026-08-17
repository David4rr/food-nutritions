import 'package:hive/hive.dart';

import '../../product/domain/product_view_data.dart';

@HiveType(typeId: 0)
class ProductHistory {
  const ProductHistory({
    required this.barcode,
    required this.name,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.imageUrl,
    required this.scanDate,
    this.estimatedCaloriesPerProduct,
    this.estimatedProteinPerProduct,
  });

  @HiveField(0)
  final String barcode;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final double calories;
  @HiveField(3)
  final DateTime scanDate;
  @HiveField(4)
  final double protein;
  @HiveField(5)
  final double fat;
  @HiveField(6)
  final String imageUrl;
  @HiveField(7)
  final double? estimatedCaloriesPerProduct;
  @HiveField(8)
  final double? estimatedProteinPerProduct;

  ProductViewData toViewData() {
    return ProductViewData(
      barcode: barcode,
      name: name,
      calories: calories,
      protein: protein,
      fat: fat,
      imageUrl: imageUrl,
      scannedAt: scanDate,
    );
  }

  static ProductHistory fromViewData(ProductViewData data) {
    final grams = _parseEstimatedGrams(data.quantity ?? data.servingSize);
    return ProductHistory(
      barcode: data.barcode,
      name: data.name,
      calories: data.calories,
      protein: data.protein,
      fat: data.fat,
      imageUrl: data.imageUrl,
      scanDate: DateTime.fromMillisecondsSinceEpoch(
        data.scannedAt.millisecondsSinceEpoch,
      ),
      estimatedCaloriesPerProduct: _perProduct(data.calories, grams),
      estimatedProteinPerProduct: _perProduct(data.protein, grams),
    );
  }
}

double? _perProduct(double per100g, double? grams) {
  if (grams == null) return null;
  return per100g * (grams / 100);
}

double? _parseEstimatedGrams(String? quantity) {
  if (quantity == null || quantity.trim().isEmpty) return null;
  final text = quantity.toLowerCase().replaceAll(',', '.');
  final match = RegExp(
    r'([0-9]+(?:\.[0-9]+)?)\s*(kg|g|gr|gram|l|ml)',
  ).firstMatch(text);
  if (match == null) return null;

  final value = double.tryParse(match.group(1)!);
  final unit = match.group(2);
  if (value == null || unit == null) return null;

  switch (unit) {
    case 'kg':
      return value * 1000;
    case 'l':
      return value * 1000;
    case 'g':
    case 'gr':
    case 'gram':
    case 'ml':
      return value;
    default:
      return null;
  }
}
