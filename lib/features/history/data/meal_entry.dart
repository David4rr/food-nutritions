enum MealTimeCategory {
  breakfast('Sarapan', '06:00 - 10:59'),
  lunch('Makan Siang', '11:00 - 14:59'),
  dinner('Makan Malam', '18:00 - 23:59'),
  snack('Camilan & Minuman', 'Kapan saja');

  const MealTimeCategory(this.label, this.timeRange);
  final String label;
  final String timeRange;

  static MealTimeCategory fromString(String? val) {
    for (final c in MealTimeCategory.values) {
      if (c.name == val || c.label == val) return c;
    }
    return MealTimeCategory.snack;
  }
}

class MealEntry {
  const MealEntry({
    required this.id,
    required this.barcode,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.portionAmount,
    required this.portionUnit,
    required this.calories,
    required this.protein,
    this.fat = 0,
    this.carbs = 0,
    this.sugars = 0,
    this.saturatedFat = 0,
    this.sodium = 0,
    required this.loggedAt,
  });

  final String id;
  final String barcode;
  final String name;
  final String imageUrl;
  final MealTimeCategory category;
  final double portionAmount;
  final String portionUnit;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double sugars;
  final double saturatedFat;
  final double sodium; // in mg
  final DateTime loggedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'imageUrl': imageUrl,
      'category': category.name,
      'portionAmount': portionAmount,
      'portionUnit': portionUnit,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'sugars': sugars,
      'saturatedFat': saturatedFat,
      'sodium': sodium,
      'loggedAt': loggedAt.millisecondsSinceEpoch,
    };
  }

  static MealEntry fromMap(Map<dynamic, dynamic> map) {
    return MealEntry(
      id: map['id']?.toString() ?? '',
      barcode: map['barcode']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Produk Makanan',
      imageUrl: map['imageUrl']?.toString() ?? '',
      category: MealTimeCategory.fromString(map['category']?.toString()),
      portionAmount: (map['portionAmount'] as num?)?.toDouble() ?? 100,
      portionUnit: map['portionUnit']?.toString() ?? 'g',
      calories: (map['calories'] as num?)?.toDouble() ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
      sugars: (map['sugars'] as num?)?.toDouble() ?? 0,
      saturatedFat: (map['saturatedFat'] as num?)?.toDouble() ?? 0,
      sodium: (map['sodium'] as num?)?.toDouble() ?? 0,
      loggedAt: map['loggedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['loggedAt'] as num).toInt())
          : DateTime.now(),
    );
  }
}
