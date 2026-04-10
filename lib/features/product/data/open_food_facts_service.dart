import 'package:openfoodfacts/openfoodfacts.dart';

import 'knowledge_panel_fallback_client.dart';
import 'product_analysis_fallback_client.dart';
import '../domain/product_view_data.dart';

class OpenFoodFactsService {
  OpenFoodFactsService({
    KnowledgePanelFallbackClient? fallbackClient,
    ProductAnalysisFallbackClient? analysisFallbackClient,
  }) : _fallbackClient = fallbackClient ?? KnowledgePanelFallbackClient(),
       _analysisFallbackClient =
           analysisFallbackClient ?? ProductAnalysisFallbackClient();

  final KnowledgePanelFallbackClient _fallbackClient;
  final ProductAnalysisFallbackClient _analysisFallbackClient;

  Future<ProductViewData> fetchByBarcode(String barcode) async {
    final config = ProductQueryConfiguration(
      barcode,
      language: OpenFoodFactsLanguage.INDONESIAN,
      fields: [
        ProductField.NAME,
        ProductField.BRANDS,
        ProductField.QUANTITY,
        ProductField.SERVING_SIZE,
        ProductField.CATEGORIES,
        ProductField.INGREDIENTS_TEXT,
        ProductField.NUTRISCORE,
        ProductField.ECOSCORE_GRADE,
        ProductField.NOVA_GROUP,
        ProductField.WEBSITE,
        ProductField.IMAGE_FRONT_URL,
        ProductField.NUTRIMENTS,
      ],
      version: ProductQueryVersion.v3,
    );

    final result = await OpenFoodAPIClient.getProductV3(config);
    if (result.status != ProductResultV3.statusSuccess ||
        result.product == null) {
      throw Exception('Produk tidak ditemukan untuk barcode: $barcode');
    }

    final product = result.product!;
    final nutriments = product.nutriments;
    final fallback = await _fallbackClient.fetch(barcode);
    final analysis = await _analysisFallbackClient.fetch(barcode);

    final calories = _readCaloriesPer100(nutriments) ?? fallback.calories ?? 0;
    final protein =
        _readNutrientPer100(nutriments, Nutrient.proteins) ??
        fallback.protein ??
        0;
    final fat =
        _readNutrientPer100(nutriments, Nutrient.fat) ?? fallback.fat ?? 0;
    final cleanName = product.productName?.trim() ?? '';

    return ProductViewData(
      barcode: barcode,
      name: cleanName.isNotEmpty ? cleanName : 'Unknown Product',
      calories: calories,
      protein: protein,
      fat: fat,
      imageUrl: product.imageFrontUrl ?? '',
      scannedAt: DateTime.now(),
      brand: _cleanText(product.brands),
      quantity: _cleanText(product.quantity),
      servingSize: _cleanText(product.servingSize),
      categories: _cleanText(product.categories),
      ingredients: _cleanText(product.ingredientsText) ?? fallback.ingredients,
      nutriscore: _normalizeScore(product.nutriscore),
      ecoscore: _normalizeScore(product.ecoscoreGrade) ?? fallback.ecoscore,
      ecoscoreIconUrl: fallback.ecoscoreIconUrl,
      novaGroup: product.novaGroup,
      website: _cleanText(product.website),
      carbohydrates:
          _readNutrientPer100(nutriments, Nutrient.carbohydrates) ??
          fallback.carbohydrates,
      sugars:
          _readNutrientPer100(nutriments, Nutrient.sugars) ?? fallback.sugars,
      saturatedFat:
          _readNutrientPer100(nutriments, Nutrient.saturatedFat) ??
          fallback.saturatedFat,
      fiber: _readNutrientPer100(nutriments, Nutrient.fiber) ?? fallback.fiber,
      salt: _readNutrientPer100(nutriments, Nutrient.salt) ?? fallback.salt,
      sodium:
          _readNutrientPer100(nutriments, Nutrient.sodium) ??
          ((_readNutrientPer100(nutriments, Nutrient.salt) ?? fallback.salt) !=
                  null
              ? (_readNutrientPer100(nutriments, Nutrient.salt) ??
                        fallback.salt)! /
                    2.5
              : null),
      nutrientLevelsTags: analysis.nutrientLevelsTags,
      ingredientsAnalysisTags: analysis.ingredientsAnalysisTags,
    );
  }

  double? _readCaloriesPer100(Nutriments? nutriments) {
    final kcal = _readNutrientPer100(nutriments, Nutrient.energyKCal);
    if (kcal != null) return kcal;
    final kj = _readNutrientPer100(nutriments, Nutrient.energyKJ);
    if (kj == null) return null;
    return kj / 4.184;
  }

  double? _readNutrientPer100(Nutriments? nutriments, Nutrient nutrient) {
    return nutriments?.getValue(nutrient, PerSize.oneHundredGrams);
  }

  String? _cleanText(String? value) {
    final clean = value?.trim();
    if (clean == null || clean.isEmpty) return null;
    return clean;
  }

  String? _normalizeScore(String? value) {
    final clean = _cleanText(value);
    if (clean == null) return null;
    return clean.toUpperCase();
  }
}
