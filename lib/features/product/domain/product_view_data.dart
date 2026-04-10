class ProductViewData {
  const ProductViewData({
    required this.barcode,
    required this.name,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.imageUrl,
    required this.scannedAt,
    this.brand,
    this.quantity,
    this.servingSize,
    this.categories,
    this.ingredients,
    this.nutriscore,
    this.ecoscore,
    this.ecoscoreIconUrl,
    this.novaGroup,
    this.website,
    this.carbohydrates,
    this.sugars,
    this.saturatedFat,
    this.fiber,
    this.salt,
    this.sodium,
    this.nutrientLevelsTags,
    this.ingredientsAnalysisTags,
  });

  final String barcode;
  final String name;
  final double calories;
  final double protein;
  final double fat;
  final String imageUrl;
  final DateTime scannedAt;
  final String? brand;
  final String? quantity;
  final String? servingSize;
  final String? categories;
  final String? ingredients;
  final String? nutriscore;
  final String? ecoscore;
  final String? ecoscoreIconUrl;
  final int? novaGroup;
  final String? website;
  final double? carbohydrates;
  final double? sugars;
  final double? saturatedFat;
  final double? fiber;
  final double? salt;
  final double? sodium;
  final List<String>? nutrientLevelsTags;
  final List<String>? ingredientsAnalysisTags;

  ProductViewData copyWith({
    String? barcode,
    String? name,
    double? calories,
    double? protein,
    double? fat,
    String? imageUrl,
    DateTime? scannedAt,
    String? brand,
    String? quantity,
    String? servingSize,
    String? categories,
    String? ingredients,
    String? nutriscore,
    String? ecoscore,
    String? ecoscoreIconUrl,
    int? novaGroup,
    String? website,
    double? carbohydrates,
    double? sugars,
    double? saturatedFat,
    double? fiber,
    double? salt,
    double? sodium,
    List<String>? nutrientLevelsTags,
    List<String>? ingredientsAnalysisTags,
  }) {
    return ProductViewData(
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      imageUrl: imageUrl ?? this.imageUrl,
      scannedAt: scannedAt ?? this.scannedAt,
      brand: brand ?? this.brand,
      quantity: quantity ?? this.quantity,
      servingSize: servingSize ?? this.servingSize,
      categories: categories ?? this.categories,
      ingredients: ingredients ?? this.ingredients,
      nutriscore: nutriscore ?? this.nutriscore,
      ecoscore: ecoscore ?? this.ecoscore,
      ecoscoreIconUrl: ecoscoreIconUrl ?? this.ecoscoreIconUrl,
      novaGroup: novaGroup ?? this.novaGroup,
      website: website ?? this.website,
      carbohydrates: carbohydrates ?? this.carbohydrates,
      sugars: sugars ?? this.sugars,
      saturatedFat: saturatedFat ?? this.saturatedFat,
      fiber: fiber ?? this.fiber,
      salt: salt ?? this.salt,
      sodium: sodium ?? this.sodium,
      nutrientLevelsTags: nutrientLevelsTags ?? this.nutrientLevelsTags,
      ingredientsAnalysisTags:
          ingredientsAnalysisTags ?? this.ingredientsAnalysisTags,
    );
  }
}
