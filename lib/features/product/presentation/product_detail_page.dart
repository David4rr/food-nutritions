import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
import '../data/open_food_facts_service.dart';
import '../data/product_cache_repository.dart';
import '../domain/product_view_data.dart';
import 'portion_selector_sheet.dart';
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
  bool _isFabExpanded = true;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _item = widget.product;
    _enrichIfMissing();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  void _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification ||
        notification is ScrollUpdateNotification) {
      _idleTimer?.cancel();
      if (_isFabExpanded) {
        setState(() => _isFabExpanded = false);
      }
      _startIdleTimer();
    } else if (notification is ScrollEndNotification) {
      _startIdleTimer();
    }
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && !_isFabExpanded) {
        setState(() => _isFabExpanded = true);
      }
    });
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

    // Luminous Fresh Theme Palette (matching AppColors and theme)
    final fabBgGradient = isPink
        ? const LinearGradient(
            colors: [Color(0xFFF06292), Color(0xFFE91E63)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF2FB8A4), Color(0xFF1C9987)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final fabGlowColor = isPink
        ? const Color(0xFFE91E63).withValues(alpha: 0.38)
        : const Color(0xFF2FB8A4).withValues(alpha: 0.40);

    return Scaffold(
      backgroundColor: isPink
          ? const Color(0xFFFFF1F7)
          : const Color(0xFFF6F8FC),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: AnimatedPressable(
        onPressed: () => PortionSelectorSheet.show(context, _item),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.fastEaseInToSlowEaseOut,
          height: 52,
          padding: EdgeInsets.symmetric(
            horizontal: _isFabExpanded ? 18 : 14,
          ),
          decoration: BoxDecoration(
            gradient: fabBgGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.38),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: fabGlowColor,
                blurRadius: _isFabExpanded ? 18 : 12,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 24,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.fastEaseInToSlowEaseOut,
                child: _isFabExpanded
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 8),
                          Text(
                            'Catat Konsumsi',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          _onScrollNotification(notification);
          return false;
        },
        child: CustomScrollView(
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
                  const SizedBox(height: 76),
                ],
              ),
            ),
          ),
        ],
      ),
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
