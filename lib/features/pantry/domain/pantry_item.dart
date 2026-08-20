enum PantryLocation {
  fridge('Kulkas', 'Simpan Dingin'),
  shelf('Rak / Pantry', 'Suhu Ruang'),
  freezer('Freezer', 'Beku');

  const PantryLocation(this.label, this.description);
  final String label;
  final String description;

  static PantryLocation fromString(String? val) {
    for (final loc in PantryLocation.values) {
      if (loc.name == val || loc.label == val) return loc;
    }
    return PantryLocation.fridge;
  }
}

class PantryItem {
  const PantryItem({
    required this.id,
    required this.barcode,
    required this.name,
    required this.imageUrl,
    this.brand,
    required this.totalCapacity,
    required this.remainingAmount,
    required this.unit,
    required this.caloriesPer100,
    required this.proteinPer100,
    this.fatPer100 = 0,
    this.carbsPer100 = 0,
    this.sugarsPer100 = 0,
    this.saturatedFatPer100 = 0,
    this.sodiumPer100 = 0,
    this.location = PantryLocation.fridge,
    this.defaultServingSize = 100.0,
    required this.addedAt,
    this.expiryDate,
    this.openedAt,
  });

  final String id;
  final String barcode;
  final String name;
  final String imageUrl;
  final String? brand;
  final double totalCapacity;
  final double remainingAmount;
  final String unit;
  final double caloriesPer100;
  final double proteinPer100;
  final double fatPer100;
  final double carbsPer100;
  final double sugarsPer100;
  final double saturatedFatPer100;
  final double sodiumPer100;
  final PantryLocation location;
  final double defaultServingSize;
  final DateTime addedAt;
  final DateTime? expiryDate;
  final DateTime? openedAt;

  bool get isFinished => remainingAmount <= 0;
  double get remainingPercent => totalCapacity > 0 ? (remainingAmount / totalCapacity).clamp(0.0, 1.0) : 0.0;
  bool get isLowStock => remainingPercent <= 0.25 && !isFinished;

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysLeft = expiryDate!.difference(DateTime.now()).inDays;
    return daysLeft >= 0 && daysLeft <= 3;
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  PantryItem copyWith({
    String? id,
    String? barcode,
    String? name,
    String? imageUrl,
    String? brand,
    double? totalCapacity,
    double? remainingAmount,
    String? unit,
    double? caloriesPer100,
    double? proteinPer100,
    double? fatPer100,
    double? carbsPer100,
    double? sugarsPer100,
    double? saturatedFatPer100,
    double? sodiumPer100,
    PantryLocation? location,
    double? defaultServingSize,
    DateTime? addedAt,
    DateTime? expiryDate,
    DateTime? openedAt,
  }) {
    return PantryItem(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      brand: brand ?? this.brand,
      totalCapacity: totalCapacity ?? this.totalCapacity,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      unit: unit ?? this.unit,
      caloriesPer100: caloriesPer100 ?? this.caloriesPer100,
      proteinPer100: proteinPer100 ?? this.proteinPer100,
      fatPer100: fatPer100 ?? this.fatPer100,
      carbsPer100: carbsPer100 ?? this.carbsPer100,
      sugarsPer100: sugarsPer100 ?? this.sugarsPer100,
      saturatedFatPer100: saturatedFatPer100 ?? this.saturatedFatPer100,
      sodiumPer100: sodiumPer100 ?? this.sodiumPer100,
      location: location ?? this.location,
      defaultServingSize: defaultServingSize ?? this.defaultServingSize,
      addedAt: addedAt ?? this.addedAt,
      expiryDate: expiryDate ?? this.expiryDate,
      openedAt: openedAt ?? this.openedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'imageUrl': imageUrl,
      'brand': brand,
      'totalCapacity': totalCapacity,
      'remainingAmount': remainingAmount,
      'unit': unit,
      'caloriesPer100': caloriesPer100,
      'proteinPer100': proteinPer100,
      'fatPer100': fatPer100,
      'carbsPer100': carbsPer100,
      'sugarsPer100': sugarsPer100,
      'saturatedFatPer100': saturatedFatPer100,
      'sodiumPer100': sodiumPer100,
      'location': location.name,
      'defaultServingSize': defaultServingSize,
      'addedAt': addedAt.millisecondsSinceEpoch,
      'expiryDate': expiryDate?.millisecondsSinceEpoch,
      'openedAt': openedAt?.millisecondsSinceEpoch,
    };
  }

  static PantryItem fromMap(Map<dynamic, dynamic> map) {
    return PantryItem(
      id: map['id']?.toString() ?? '',
      barcode: map['barcode']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Produk Pantry',
      imageUrl: map['imageUrl']?.toString() ?? '',
      brand: map['brand']?.toString(),
      totalCapacity: (map['totalCapacity'] as num?)?.toDouble() ?? 1000.0,
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 1000.0,
      unit: map['unit']?.toString() ?? 'g',
      caloriesPer100: (map['caloriesPer100'] as num?)?.toDouble() ?? 0.0,
      proteinPer100: (map['proteinPer100'] as num?)?.toDouble() ?? 0.0,
      fatPer100: (map['fatPer100'] as num?)?.toDouble() ?? 0.0,
      carbsPer100: (map['carbsPer100'] as num?)?.toDouble() ?? 0.0,
      sugarsPer100: (map['sugarsPer100'] as num?)?.toDouble() ?? 0.0,
      saturatedFatPer100: (map['saturatedFatPer100'] as num?)?.toDouble() ?? 0.0,
      sodiumPer100: (map['sodiumPer100'] as num?)?.toDouble() ?? 0.0,
      location: PantryLocation.fromString(map['location']?.toString()),
      defaultServingSize: (map['defaultServingSize'] as num?)?.toDouble() ?? 100.0,
      addedAt: map['addedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['addedAt'] as num).toInt())
          : DateTime.now(),
      expiryDate: map['expiryDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['expiryDate'] as num).toInt())
          : null,
      openedAt: map['openedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['openedAt'] as num).toInt())
          : null,
    );
  }
}
