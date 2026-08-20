import 'package:flutter/foundation.dart';

import '../../history/data/meal_entry.dart';
import '../../history/presentation/history_provider.dart';
import '../../product/domain/product_view_data.dart';
import '../data/pantry_repository.dart';
import '../domain/pantry_item.dart';

class PantryProvider extends ChangeNotifier {
  PantryProvider(this._repository) {
    loadPantry();
  }

  final PantryRepository _repository;
  List<PantryItem> _items = [];
  bool _isLoading = false;
  String _searchQuery = '';
  PantryLocation? _selectedLocationFilter;
  bool _filterLowStockOnly = false;

  List<PantryItem> get items => _items;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  PantryLocation? get selectedLocationFilter => _selectedLocationFilter;
  bool get filterLowStockOnly => _filterLowStockOnly;

  List<PantryItem> get filteredItems {
    return _items.where((item) {
      if (_filterLowStockOnly && !item.isLowStock) return false;
      if (_selectedLocationFilter != null && item.location != _selectedLocationFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatches = item.name.toLowerCase().contains(q);
        final brandMatches = item.brand?.toLowerCase().contains(q) ?? false;
        if (!nameMatches && !brandMatches) return false;
      }
      return true;
    }).toList();
  }

  List<PantryItem> get fridgeItems => _items.where((i) => i.location == PantryLocation.fridge && !i.isFinished).toList();
  List<PantryItem> get shelfItems => _items.where((i) => i.location == PantryLocation.shelf && !i.isFinished).toList();
  List<PantryItem> get lowStockItems => _items.where((i) => i.isLowStock).toList();
  List<PantryItem> get expiringSoonItems => _items.where((i) => i.isExpiringSoon && !i.isFinished).toList();

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setLocationFilter(PantryLocation? location) {
    _selectedLocationFilter = location;
    _filterLowStockOnly = false;
    notifyListeners();
  }

  void setLowStockFilter(bool lowStockOnly) {
    _filterLowStockOnly = lowStockOnly;
    if (lowStockOnly) _selectedLocationFilter = null;
    notifyListeners();
  }

  void loadPantry() {
    _isLoading = true;
    notifyListeners();

    _items = _repository.getAll();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProductToPantry({
    required ProductViewData product,
    required double totalCapacity,
    required String unit,
    PantryLocation location = PantryLocation.fridge,
    double defaultServingSize = 100.0,
    DateTime? expiryDate,
  }) async {
    final id = 'pantry_${product.barcode}_${DateTime.now().millisecondsSinceEpoch}';
    final newItem = PantryItem(
      id: id,
      barcode: product.barcode,
      name: product.name,
      imageUrl: product.imageUrl,
      brand: product.brand,
      totalCapacity: totalCapacity,
      remainingAmount: totalCapacity,
      unit: unit,
      caloriesPer100: product.calories,
      proteinPer100: product.protein,
      fatPer100: product.fat,
      carbsPer100: product.carbohydrates ?? 0.0,
      sugarsPer100: product.sugars ?? 0.0,
      saturatedFatPer100: product.saturatedFat ?? 0.0,
      sodiumPer100: product.sodium ?? 0.0,
      location: location,
      defaultServingSize: defaultServingSize,
      addedAt: DateTime.now(),
      expiryDate: expiryDate,
      openedAt: DateTime.now(),
    );

    await _repository.add(newItem);
    _items = _repository.getAll();
    notifyListeners();
  }

  /// Consumes [amount] of [item] and records a [MealEntry] into [historyProvider].
  Future<void> consumePortion({
    required PantryItem item,
    required double amount,
    required MealTimeCategory category,
    required HistoryProvider historyProvider,
  }) async {
    final ratio = amount / 100.0;
    final calories = item.caloriesPer100 * ratio;
    final protein = item.proteinPer100 * ratio;
    final carbs = item.carbsPer100 * ratio;
    final fat = item.fatPer100 * ratio;
    final sugars = item.sugarsPer100 * ratio;
    final saturatedFat = item.saturatedFatPer100 * ratio;
    final sodium = item.sodiumPer100 * ratio;

    final entry = MealEntry(
      id: 'meal_${item.barcode}_${DateTime.now().millisecondsSinceEpoch}',
      barcode: item.barcode,
      name: item.name,
      imageUrl: item.imageUrl,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      sugars: sugars,
      saturatedFat: saturatedFat,
      sodium: sodium,
      portionAmount: amount,
      portionUnit: item.unit,
      category: category,
      loggedAt: DateTime.now(),
    );

    // 1. Log meal to HistoryProvider
    await historyProvider.logMeal(entry);

    // 2. Deduct remaining capacity in Pantry
    final updatedAmount = (item.remainingAmount - amount).clamp(0.0, item.totalCapacity);
    final updatedItem = item.copyWith(remainingAmount: updatedAmount);

    await _repository.update(updatedItem);
    _items = _repository.getAll();
    notifyListeners();
  }

  Future<void> refillItem(String id, {double? newCapacity}) async {
    final existing = _repository.get(id);
    if (existing == null) return;

    final cap = newCapacity ?? existing.totalCapacity;
    final updated = existing.copyWith(
      totalCapacity: cap,
      remainingAmount: cap,
      openedAt: DateTime.now(),
    );

    await _repository.update(updated);
    _items = _repository.getAll();
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    await _repository.delete(id);
    _items = _repository.getAll();
    notifyListeners();
  }
}
