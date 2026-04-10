import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/nutrition_tile.dart';
import '../data/open_food_facts_service.dart';
import '../domain/product_view_data.dart';
import 'product_analysis_sections.dart';
import 'product_detail_enrichment.dart';
import 'product_detail_header_card.dart';
import 'product_quantity_helper.dart';
import 'product_detail_sections.dart';
import 'product_smart_reason_card.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.product});

  final ProductViewData product;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final _service = OpenFoodFactsService();
  int _visibleMetrics = 0;
  late ProductViewData _item;
  bool _isRefreshing = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _item = widget.product;
    _timer = Timer.periodic(const Duration(milliseconds: 130), (timer) {
      if (!mounted) return;
      setState(() => _visibleMetrics++);
      if (_visibleMetrics >= 9) timer.cancel();
    });
    _enrichIfMissing();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
      appBar: AppBar(title: const Text('Detail Produk')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          ProductDetailHeaderCard(
            item: item,
            primary: primary,
            isRefreshing: _isRefreshing,
          ),
          const SizedBox(height: 16),
          _animatedMetric(index: 0, child: ProductSmartReasonCard(item: item)),
          const SizedBox(height: 10),
          _animatedMetric(index: 1, child: ProductScoreSection(item: item)),
          const SizedBox(height: 10),
          _animatedMetric(index: 2, child: ProductAnalysisSections(item: item)),
          const SizedBox(height: 10),
          _animatedMetric(
            index: 3,
            child: NutritionTile(
              label: 'Kalori',
              value: item.calories,
              unit: 'kcal/100g',
              color: isPink ? const Color(0xFFD81B60) : AppColors.warning,
              packageAmountGrams: packageAmountGrams,
              packageAmountLabel: packageLabel,
            ),
          ),
          const SizedBox(height: 10),
          _animatedMetric(
            index: 4,
            child: NutritionTile(
              label: 'Protein',
              value: item.protein,
              unit: 'g/100g',
              color: isPink ? const Color(0xFFEC407A) : AppColors.accentStrong,
              packageAmountGrams: packageAmountGrams,
              packageAmountLabel: packageLabel,
            ),
          ),
          const SizedBox(height: 10),
          _animatedMetric(
            index: 5,
            child: NutritionTile(
              label: 'Lemak',
              value: item.fat,
              unit: 'g/100g',
              color: isPink ? const Color(0xFFF48FB1) : const Color(0xFF5BA7FF),
              packageAmountGrams: packageAmountGrams,
              packageAmountLabel: packageLabel,
            ),
          ),
          const SizedBox(height: 10),
          _animatedMetric(
            index: 6,
            child: ProductNutritionGrid(
              item: item,
              packageAmountGrams: packageAmountGrams,
              packageAmountLabel: packageLabel,
            ),
          ),
          const SizedBox(height: 10),
          if (item.ingredients != null) ...[
            const SizedBox(height: 10),
            _animatedMetric(
              index: 7,
              child: ProductIngredientsCard(text: item.ingredients!),
            ),
          ],
          if (item.website != null) ...[
            const SizedBox(height: 10),
            _animatedMetric(
              index: 8,
              child: ProductSourceCard(url: item.website!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _animatedMetric({required int index, required Widget child}) {
    final isVisible = _visibleMetrics > index;
    return AnimatedOpacity(
      opacity: isVisible ? 1 : 0,
      duration: const Duration(milliseconds: 260),
      child: AnimatedSlide(
        offset: isVisible ? Offset.zero : const Offset(0.05, 0.2),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }

  Future<void> _enrichIfMissing() async {
    if (!shouldEnrichProductDetail(_item)) return;
    setState(() => _isRefreshing = true);
    try {
      final fresh = await _service.fetchByBarcode(_item.barcode);
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
