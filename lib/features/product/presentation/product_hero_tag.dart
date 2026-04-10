import '../domain/product_view_data.dart';

String productImageHeroTag(ProductViewData data) {
  return 'product_image_${data.barcode}_${data.scannedAt.toIso8601String()}';
}
