import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../domain/product_view_data.dart';
import 'product_hero_tag.dart';

class ProductDetailHeaderCard extends StatelessWidget {
  const ProductDetailHeaderCard({
    super.key,
    required this.item,
    required this.primary,
    required this.isRefreshing,
  });

  final ProductViewData item;
  final Color primary;
  final bool isRefreshing;

  void _showImagePreview(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: InteractiveViewer(
              child: Center(
                child: Hero(
                  tag: productImageHeroTag(item),
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPink =
        Theme.of(context).extension<AppVisualMeta>()?.isPink ?? false;
    final scanTime = DateFormat('d MMM yyyy, HH:mm').format(item.scannedAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primary.withAlpha(28)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 18),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showImagePreview(context, item.imageUrl),
            child: Hero(
              tag: productImageHeroTag(item),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: item.imageUrl.isNotEmpty
                    ? SizedBox(
                        width: double.infinity,
                        child: Image.network(
                          item.imageUrl,
                          height: 170,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        height: 170,
                        width: double.infinity,
                        color: AppColors.background,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.fastfood,
                          size: 48,
                          color: isPink
                              ? const Color(0xFFD81B60)
                              : Colors.black54,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (item.brand != null) _chip('Merek ${item.brand}'),
              if (item.quantity != null) _chip('Kuantitas ${item.quantity}'),
              if (item.servingSize != null)
                _chip('Takaran saji ${item.servingSize}'),
              _chip('Barcode ${item.barcode}'),
            ],
          ),
          if (item.servingSize != null) ...[
            const SizedBox(height: 8),
            Text(
              'Takaran saji: ${item.servingSize}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isPink
                    ? const Color(0xFFAD1457)
                    : Colors.blueGrey.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Dipindai: $scanTime',
            style: TextStyle(
              color: isPink
                  ? const Color(0xFFAD1457)
                  : Colors.blueGrey.shade700,
            ),
          ),
          if (item.categories != null) ...[
            const SizedBox(height: 6),
            Text(
              'Kategori: ${item.categories}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (isRefreshing) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(minHeight: 4, color: primary),
          ],
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: primary.withAlpha(14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: primary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
