import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/animated_pressable.dart';
import '../../../shared/widgets/pop_card.dart';
import '../../../shared/widgets/staggered_animated_tile.dart';
import '../../../shared/routes/expanding_route.dart';
import '../../history/data/product_history.dart';
import '../../product/presentation/product_detail_page.dart';
import '../../product/presentation/product_hero_tag.dart';

class RecentScansSection extends StatelessWidget {
  const RecentScansSection({
    super.key,
    required this.items,
    this.maxItems = 4,
    this.groupByDay = false,
    this.showDateBadge = true,
    this.enableDragDelete = false,
    this.onDelete,
  });

  final List<ProductHistory> items;
  final int? maxItems;
  final bool groupByDay;
  final bool showDateBadge;
  final bool enableDragDelete;
  final Future<void> Function(ProductHistory item)? onDelete;

  @override
  Widget build(BuildContext context) {
    final isPink =
        Theme.of(context).extension<AppVisualMeta>()?.isPink ?? false;
    if (items.isEmpty) {
      return PopCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Icon(Icons.history, size: 34, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              const Text('Belum ada scan terbaru.'),
            ],
          ),
        ),
      );
    }

    final visibleItems = (maxItems == null ? items : items.take(maxItems!))
        .toList(growable: false);
    if (!groupByDay) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...visibleItems.asMap().entries.map(
            (entry) => StaggeredAnimatedTile(
              index: entry.key,
              child: _HistoryTile(
                item: entry.value,
                onDelete: onDelete,
                showDateBadge: showDateBadge,
                enableDragDelete: enableDragDelete,
                isPink: isPink,
              ),
            ),
          ),
        ],
      );
    }

    final grouped = <String, List<ProductHistory>>{};
    for (final item in visibleItems) {
      final key = _dateKey(item.scanDate);
      grouped.putIfAbsent(key, () => <ProductHistory>[]).add(item);
    }

    final children = <Widget>[];
    int staggerIndex = 0;
    for (final entry in grouped.entries) {
      children.add(
        StaggeredAnimatedTile(
          index: staggerIndex++,
          child: _DayHeader(
            text: _dayLabel(entry.value.first.scanDate),
            isPink: isPink,
          ),
        ),
      );
      children.addAll(
        entry.value.map(
          (item) => StaggeredAnimatedTile(
            index: staggerIndex++,
            child: _HistoryTile(
              item: item,
              onDelete: onDelete,
              showDateBadge: showDateBadge,
              enableDragDelete: enableDragDelete,
              isPink: isPink,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = DateTime(date.year, date.month, date.day);
    final diff = today.difference(current).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(date);
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.text, required this.isPink});

  final String text;
  final bool isPink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: isPink ? const Color(0xFFF8BBD0) : Colors.grey.shade300,
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isPink ? const Color(0xFFAD1457) : Colors.grey.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: isPink ? const Color(0xFFF8BBD0) : Colors.grey.shade300,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatefulWidget {
  const _HistoryTile({
    required this.item,
    this.onDelete,
    required this.showDateBadge,
    required this.enableDragDelete,
    required this.isPink,
  });
  final ProductHistory item;
  final Future<void> Function(ProductHistory item)? onDelete;
  final bool showDateBadge;
  final bool enableDragDelete;
  final bool isPink;

  @override
  State<_HistoryTile> createState() => _HistoryTileState();
}

class _HistoryTileState extends State<_HistoryTile> {
  final _tileKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final viewData = widget.item.toViewData();
    final bgColor = widget.isPink
        ? const Color(0xFFD81B60)
        : const Color(0xFF009688);
    final tile = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: AnimatedPressable(
          onPressed: () {
            context.expandTo(
              tileKey: _tileKey,
              page: ProductDetailPage(product: viewData),
              tileColor: bgColor,
              tileRadius: BorderRadius.circular(16),
            );
          },
          child: Stack(
            children: [
              Positioned(
                right: -14,
                bottom: -16,
                child: Icon(
                  Icons.qr_code_2_rounded,
                  size: 88,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Hero(
                      tag: productImageHeroTag(viewData),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: widget.item.imageUrl.isNotEmpty
                            ? (widget.item.imageUrl.startsWith('file://')
                                ? Image.file(
                                    File(widget.item.imageUrl.replaceFirst('file://', '')),
                                    width: 62,
                                    height: 62,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 62,
                                      height: 62,
                                      color: Colors.white.withValues(alpha: 0.1),
                                      child: const Icon(
                                        Icons.document_scanner_rounded,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: widget.item.imageUrl,
                                    width: 62,
                                    height: 62,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 62,
                                      height: 62,
                                      color: Colors.white.withValues(alpha: 0.1),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      width: 62,
                                      height: 62,
                                      color: Colors.white.withValues(alpha: 0.1),
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ))
                            : Container(
                                width: 62,
                                height: 62,
                                color: Colors.white.withValues(alpha: 0.2),
                                child: const Icon(
                                  Icons.fastfood,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                size: 14,
                                color: Colors.orange.shade300,
                              ),
                              Text(
                                '${widget.item.calories.toStringAsFixed(1)} kcal/100g',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (widget.showDateBadge)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              DateFormat(
                                'dd/MM HH:mm',
                              ).format(widget.item.scanDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (widget.onDelete != null) ...[
                          const SizedBox(height: 8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: () => widget.onDelete!(widget.item),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!widget.enableDragDelete) {
      return KeyedSubtree(key: _tileKey, child: tile);
    }

    return KeyedSubtree(
      key: _tileKey,
      child: LongPressDraggable<ProductHistory>(
        data: widget.item,
        dragAnchorStrategy: (draggable, context, position) {
          final renderBox = context.findRenderObject() as RenderBox?;
          final height = renderBox?.size.height ?? 90.0;
          return Offset(220 / 2, height / 2);
        },
        onDragStarted: () => HapticFeedback.heavyImpact(),
        feedback: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Opacity(opacity: 0.9, child: tile),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.35, child: tile),
        child: tile,
      ),
    );
  }
}
