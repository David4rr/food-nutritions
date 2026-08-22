import '../../product/domain/product_view_data.dart';

class OcrNutritionResult {
  const OcrNutritionResult({
    this.productName = '',
    this.brand,
    this.servingSize = 100.0,
    this.servingUnit = 'g',
    this.servingsPerContainer = 1.0,
    this.calories = 0.0,
    this.protein = 0.0,
    this.fat = 0.0,
    this.saturatedFat = 0.0,
    this.carbohydrates = 0.0,
    this.sugars = 0.0,
    this.sodium = 0.0,
    this.ingredients,
    this.rawText = '',
    this.imagePath,
  });

  final String productName;
  final String? brand;
  final double servingSize;
  final String servingUnit;
  final double servingsPerContainer;
  final double calories;
  final double protein;
  final double fat;
  final double saturatedFat;
  final double carbohydrates;
  final double sugars;
  final double sodium; // in mg
  final String? ingredients;
  final String rawText;
  final String? imagePath;

  bool get hasValidData => calories > 0 || protein > 0 || fat > 0 || carbohydrates > 0;

  OcrNutritionResult copyWith({
    String? productName,
    String? brand,
    double? servingSize,
    String? servingUnit,
    double? servingsPerContainer,
    double? calories,
    double? protein,
    double? fat,
    double? saturatedFat,
    double? carbohydrates,
    double? sugars,
    double? sodium,
    String? ingredients,
    String? rawText,
    String? imagePath,
  }) {
    return OcrNutritionResult(
      productName: productName ?? this.productName,
      brand: brand ?? this.brand,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      servingsPerContainer: servingsPerContainer ?? this.servingsPerContainer,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      saturatedFat: saturatedFat ?? this.saturatedFat,
      carbohydrates: carbohydrates ?? this.carbohydrates,
      sugars: sugars ?? this.sugars,
      sodium: sodium ?? this.sodium,
      ingredients: ingredients ?? this.ingredients,
      rawText: rawText ?? this.rawText,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  ProductViewData toProductViewData({String? fallbackName}) {
    final name = (productName.isNotEmpty ? productName : fallbackName) ?? 'Produk OCR (Tabel Gizi)';
    final syntheticBarcode = 'ocr_${DateTime.now().millisecondsSinceEpoch}';

    // Normalize per 100g/ml if serving size is given
    final multiplier = servingSize > 0 ? (100.0 / servingSize) : 1.0;
    final totalQty = servingSize * servingsPerContainer;
    final qtyStr = totalQty > 0
        ? '${(totalQty % 1 == 0) ? totalQty.toStringAsFixed(0) : totalQty.toStringAsFixed(1)} $servingUnit'
        : '${servingSize > 0 ? (servingSize % 1 == 0 ? servingSize.toStringAsFixed(0) : servingSize.toStringAsFixed(1)) : '100'} $servingUnit';
    final srvStr = '${servingSize > 0 ? (servingSize % 1 == 0 ? servingSize.toStringAsFixed(0) : servingSize.toStringAsFixed(1)) : '100'} $servingUnit';

    return ProductViewData(
      barcode: syntheticBarcode,
      name: name,
      brand: brand,
      quantity: qtyStr,
      servingSize: srvStr,
      calories: (calories * multiplier).roundToDouble(),
      protein: double.parse((protein * multiplier).toStringAsFixed(1)),
      fat: double.parse((fat * multiplier).toStringAsFixed(1)),
      carbohydrates: double.parse((carbohydrates * multiplier).toStringAsFixed(1)),
      sugars: double.parse((sugars * multiplier).toStringAsFixed(1)),
      saturatedFat: double.parse((saturatedFat * multiplier).toStringAsFixed(1)),
      sodium: double.parse((sodium * multiplier).toStringAsFixed(1)),
      ingredients: ingredients?.trim().isNotEmpty == true ? ingredients!.trim() : null,
      imageUrl: imagePath != null ? 'file://$imagePath' : '',
      scannedAt: DateTime.now(),
    );
  }
}
