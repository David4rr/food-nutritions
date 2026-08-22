import '../domain/product_view_data.dart';

bool shouldEnrichProductDetail(ProductViewData item) {
  if (item.barcode.startsWith('ocr_')) return false;
  final missingMainMacros =
      item.calories == 0 && item.protein == 0 && item.fat == 0;
  final missingContext =
      _isMissing(item.ingredients) ||
      _isMissing(item.ecoscore) ||
      _isMissing(item.nutriscore) ||
      _isMissing(item.ecoscoreIconUrl) ||
      item.carbohydrates == null ||
      item.sugars == null ||
      item.salt == null ||
      (item.nutrientLevelsTags?.isEmpty ?? true) ||
      (item.ingredientsAnalysisTags?.isEmpty ?? true);
  return missingMainMacros || missingContext;
}

ProductViewData mergeProductDetailData({
  required ProductViewData base,
  required ProductViewData fresh,
}) {
  return ProductViewData(
    barcode: base.barcode,
    name: _pickText(fresh.name, base.name) ?? 'Unknown Product',
    calories: fresh.calories > 0 ? fresh.calories : base.calories,
    protein: fresh.protein > 0 ? fresh.protein : base.protein,
    fat: fresh.fat > 0 ? fresh.fat : base.fat,
    imageUrl: _pickText(fresh.imageUrl, base.imageUrl) ?? '',
    scannedAt: base.scannedAt,
    brand: _pickText(fresh.brand, base.brand),
    quantity: _pickText(fresh.quantity, base.quantity),
    servingSize: _pickText(fresh.servingSize, base.servingSize),
    categories: _pickText(fresh.categories, base.categories),
    ingredients: _pickText(fresh.ingredients, base.ingredients),
    nutriscore: _pickText(fresh.nutriscore, base.nutriscore),
    ecoscore: _pickText(fresh.ecoscore, base.ecoscore),
    ecoscoreIconUrl: _pickText(fresh.ecoscoreIconUrl, base.ecoscoreIconUrl),
    novaGroup: fresh.novaGroup ?? base.novaGroup,
    website: _pickText(fresh.website, base.website),
    carbohydrates: fresh.carbohydrates ?? base.carbohydrates,
    sugars: fresh.sugars ?? base.sugars,
    saturatedFat: fresh.saturatedFat ?? base.saturatedFat,
    fiber: fresh.fiber ?? base.fiber,
    salt: fresh.salt ?? base.salt,
    sodium: fresh.sodium ?? base.sodium,
    nutrientLevelsTags: _pickList(
      fresh.nutrientLevelsTags,
      base.nutrientLevelsTags,
    ),
    ingredientsAnalysisTags: _pickList(
      fresh.ingredientsAnalysisTags,
      base.ingredientsAnalysisTags,
    ),
  );
}

String? _pickText(String? first, String? second) {
  final a = _clean(first);
  if (a != null) return a;
  return _clean(second);
}

String? _clean(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

bool _isMissing(String? text) => _clean(text) == null;

List<String>? _pickList(List<String>? first, List<String>? second) {
  if (first != null && first.isNotEmpty) return first;
  if (second != null && second.isNotEmpty) return second;
  return null;
}
