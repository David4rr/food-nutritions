import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/nutrition_tile.dart';
import '../data/open_food_facts_service.dart';
import '../data/product_cache_repository.dart';
import '../domain/product_view_data.dart';
import 'product_analysis_sections.dart';
import 'product_detail_enrichment.dart';
import 'product_detail_header_card.dart';
import 'product_quantity_helper.dart';
import 'product_detail_sections.dart';
import 'product_smart_reason_card.dart';
import '../../../shared/widgets/staggered_animated_tile.dart';
import '../../../shared/widgets/animated_pressable.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.product});

  final ProductViewData product;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late ProductViewData _item;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _item = widget.product;
    _enrichIfMissing();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final isPink =
        Theme.of(context).extension<AppVisualMeta>()?.isPink ?? false;
    final primary = Theme.of(context).primaryColor;
    final servingLabel = item.servingSize?.trim();
    final quantityLabel = item.quantity?.trim();
    final packageLabel = (servingLabel != null && servingLabel.isNotEmpty)
        ? servingLabel
        : quantityLabel;
    final packageAmountGrams = parseEstimatedGrams(packageLabel);

    return Scaffold(
      backgroundColor: isPink
          ? const Color(0xFFFFF1F7)
          : const Color(0xFFF6F8FC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: Colors.black87,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text(
              'Detail Produk',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  StaggeredAnimatedTile(
                    index: 0,
                    child: AnimatedPressable(
                      child: ProductDetailHeaderCard(
                        item: item,
                        primary: primary,
                        isRefreshing: _isRefreshing,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  StaggeredAnimatedTile(
                    index: 1,
                    child: ProductSmartReasonCard(item: item),
                  ),
                  const SizedBox(height: 10),
                  StaggeredAnimatedTile(
                    index: 2,
                    child: ProductScoreSection(item: item),
                  ),
                  const SizedBox(height: 10),
                  StaggeredAnimatedTile(
                    index: 3,
                    child: ProductAnalysisSections(item: item),
                  ),
                  const SizedBox(height: 10),
                  StaggeredAnimatedTile(
                    index: 4,
                    child: ProductNutritionGrid(
                      item: item,
                      packageAmountGrams: packageAmountGrams,
                      packageAmountLabel: packageLabel,
                      isPink: isPink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (item.ingredients != null) ...[
                    const SizedBox(height: 10),
                    StaggeredAnimatedTile(
                      index: 5,
                      child: ProductIngredientsCard(text: item.ingredients!),
                    ),
                  ],
                  if (item.website != null) ...[
                    const SizedBox(height: 10),
                    StaggeredAnimatedTile(
                      index: 6,
                      child: ProductSourceCard(url: item.website!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enrichIfMissing() async {
    if (!shouldEnrichProductDetail(_item)) return;
    setState(() => _isRefreshing = true);
    try {
      final cacheRepo = context.read<ProductCacheRepository>();
      final service = OpenFoodFactsService(cacheRepository: cacheRepo);
      final fresh = await service.fetchByBarcode(_item.barcode);
      if (!mounted) return;
      setState(() {
        _item = mergeProductDetailData(base: _item, fresh: fresh);
      });
    } catch (_) {
      // Keep saved local values when refresh fails.
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }
}
