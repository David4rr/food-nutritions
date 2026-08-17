import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../shared/widgets/animated_pressable.dart';
import '../../../shared/utils/navigator_extension.dart';
import '../../history/data/product_history.dart';
import '../../product/presentation/product_detail_page.dart';
import '../../product/presentation/product_hero_tag.dart';

class HomeHistoryItem extends StatelessWidget {
  const HomeHistoryItem({super.key, required this.item});

  final ProductHistory item;

  @override
  Widget build(BuildContext context) {
    final viewData = item.toViewData();
    return AnimatedPressable(
      onPressed: () {
        context.pushRoute(ProductDetailPage(product: viewData));
      },
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Hero(
                tag: productImageHeroTag(viewData),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: item.imageUrl.isNotEmpty
                      // ponytail: Use CachedNetworkImage to avoid re-downloading and show loading skeleton
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF5BA7FF),
                          child: const Icon(
                            Icons.fastfood,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${item.calories.toStringAsFixed(1)} kcal',
                        style: const TextStyle(
                          color: Color(0xFFE91E63),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Pro: ${item.protein.toStringAsFixed(1)}g · Lemak: ${item.fat.toStringAsFixed(1)}g',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
