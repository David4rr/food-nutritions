import 'dart:convert';

import 'package:http/http.dart' as http;

class ProductAnalysisFallback {
  const ProductAnalysisFallback({
    this.nutrientLevelsTags,
    this.ingredientsAnalysisTags,
  });

  final List<String>? nutrientLevelsTags;
  final List<String>? ingredientsAnalysisTags;
}

class ProductAnalysisFallbackClient {
  Future<ProductAnalysisFallback> fetch(String barcode) async {
    try {
      final uri = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$barcode?fields=nutrient_levels_tags,ingredients_analysis_tags',
      );
      final response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const ProductAnalysisFallback();
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final product = body['product'] as Map<String, dynamic>?;
      return ProductAnalysisFallback(
        nutrientLevelsTags: _stringList(product?['nutrient_levels_tags']),
        ingredientsAnalysisTags: _stringList(
          product?['ingredients_analysis_tags'],
        ),
      );
    } catch (_) {
      return const ProductAnalysisFallback();
    }
  }

  List<String>? _stringList(dynamic raw) {
    final list = (raw as List<dynamic>?)?.whereType<String>().toList(
      growable: false,
    );
    if (list == null || list.isEmpty) return null;
    return list;
  }
}
