import 'dart:convert';

import 'package:http/http.dart' as http;

class KnowledgeFallback {
  const KnowledgeFallback({
    this.calories,
    this.protein,
    this.fat,
    this.carbohydrates,
    this.sugars,
    this.saturatedFat,
    this.fiber,
    this.salt,
    this.ingredients,
    this.ecoscore,
    this.ecoscoreIconUrl,
  });

  final double? calories;
  final double? protein;
  final double? fat;
  final double? carbohydrates;
  final double? sugars;
  final double? saturatedFat;
  final double? fiber;
  final double? salt;
  final String? ingredients;
  final String? ecoscore;
  final String? ecoscoreIconUrl;
}

class KnowledgePanelFallbackClient {
  Future<KnowledgeFallback> fetch(String barcode) async {
    try {
      final uri = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$barcode?fields=knowledge_panels,nutriments,ingredients_text,ecoscore_grade',
      );
      final response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const KnowledgeFallback();
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final product = body['product'] as Map<String, dynamic>?;
      final panels = product?['knowledge_panels'] as Map<String, dynamic>?;
      final nutrition = _extractNutrition(product, panels);
      final ecoPanel = panels?['environmental_score'] as Map<String, dynamic>?;
      final title = ecoPanel?['title_element'] as Map<String, dynamic>?;
      final ecoscore = _cleanText(
        product?['ecoscore_grade'] as String?,
      )?.toUpperCase();
      final iconUrl =
          _cleanText(title?['icon_url'] as String?) ??
          _ecoscoreIconUrl(ecoscore);
      final ingredients = _cleanText(product?['ingredients_text'] as String?);

      return KnowledgeFallback(
        calories: nutrition['calories'],
        fat: nutrition['fat'],
        saturatedFat: nutrition['saturated_fat'],
        carbohydrates: nutrition['carbohydrates'],
        sugars: nutrition['sugars'],
        fiber: nutrition['fiber'],
        protein: nutrition['proteins'],
        salt: nutrition['salt'],
        ingredients: ingredients,
        ecoscore: ecoscore,
        ecoscoreIconUrl: iconUrl,
      );
    } catch (_) {
      return const KnowledgeFallback();
    }
  }

  Map<String, double> _extractNutrition(
    Map<String, dynamic>? product,
    Map<String, dynamic>? panels,
  ) {
    final fromNutriments = _extractFromNutriments(product);
    if (fromNutriments.isNotEmpty) return fromNutriments;
    if (panels == null) return const <String, double>{};
    return _extractNutritionFromTable(panels);
  }

  Map<String, double> _extractFromNutriments(Map<String, dynamic>? product) {
    final nutriments = product?['nutriments'] as Map<String, dynamic>?;
    if (nutriments == null) return const <String, double>{};

    final values = <String, double>{};
    _put(values, 'calories', nutriments['energy-kcal_100g']);
    _put(values, 'fat', nutriments['fat_100g']);
    _put(values, 'saturated_fat', nutriments['saturated-fat_100g']);
    _put(values, 'carbohydrates', nutriments['carbohydrates_100g']);
    _put(values, 'sugars', nutriments['sugars_100g']);
    _put(values, 'fiber', nutriments['fiber_100g']);
    _put(values, 'proteins', nutriments['proteins_100g']);
    _put(values, 'salt', nutriments['salt_100g']);
    return values;
  }

  void _put(Map<String, double> map, String key, dynamic value) {
    final parsed = _toDouble(value);
    if (parsed != null) map[key] = parsed;
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }

  Map<String, double> _extractNutritionFromTable(Map<String, dynamic> panels) {
    final panel = panels['nutrition_facts_table'] as Map<String, dynamic>?;
    final elements = panel?['elements'] as List<dynamic>?;
    final table = elements
        ?.whereType<Map<String, dynamic>>()
        .map((e) => e['table_element'])
        .whereType<Map<String, dynamic>>()
        .cast<Map<String, dynamic>?>()
        .firstWhere((e) => e != null, orElse: () => null);
    final rows = table?['rows'] as List<dynamic>?;

    final output = <String, double>{};
    if (rows == null) return output;

    for (final rawRow in rows) {
      final row = rawRow as Map<String, dynamic>?;
      final values = row?['values'] as List<dynamic>?;
      if (values == null || values.length < 2) continue;

      final label = (values[0] as Map<String, dynamic>)['text'] as String?;
      final amount = (values[1] as Map<String, dynamic>)['text'] as String?;
      final key = _mapNutritionLabel(label);
      final value = _parseAmount(amount, key == 'calories');
      if (key != null && value != null) output[key] = value;
    }
    return output;
  }

  String? _mapNutritionLabel(String? label) {
    final l = label?.toLowerCase().trim();
    switch (l) {
      case 'energy':
        return 'calories';
      case 'fat':
        return 'fat';
      case 'saturated fat':
        return 'saturated_fat';
      case 'carbohydrates':
        return 'carbohydrates';
      case 'sugars':
        return 'sugars';
      case 'fiber':
        return 'fiber';
      case 'proteins':
        return 'proteins';
      case 'salt':
        return 'salt';
      default:
        return null;
    }
  }

  double? _parseAmount(String? text, bool extractKcal) {
    if (text == null) return null;
    if (extractKcal) {
      final kcal = RegExp(
        r'([0-9]+(?:[.,][0-9]+)?)\s*kcal',
      ).firstMatch(text.toLowerCase());
      if (kcal != null) {
        return double.tryParse(kcal.group(1)!.replaceAll(',', '.'));
      }
    }

    final number = RegExp(r'([0-9]+(?:[.,][0-9]+)?)').firstMatch(text);
    if (number == null) return null;
    return double.tryParse(number.group(1)!.replaceAll(',', '.'));
  }

  String? _cleanText(String? value) {
    final clean = value?.trim();
    if (clean == null || clean.isEmpty) return null;
    return clean;
  }

  String? _ecoscoreIconUrl(String? grade) {
    final g = grade?.toLowerCase();
    if (g == null || g.isEmpty) return null;
    return 'https://static.openfoodfacts.org/images/attributes/dist/ecoscore-$g.svg';
  }
}
