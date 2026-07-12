
class ProductCache {
  ProductCache({
    required this.barcode,
    required this.jsonData,
    required this.cachedAt,
    required this.expiresAt,
  });

  final String barcode;
  final Map<String, dynamic> jsonData;
  final DateTime cachedAt;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  static const defaultCacheDuration = Duration(days: 7);
}
