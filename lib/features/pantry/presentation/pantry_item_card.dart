import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/animated_pressable.dart';
import '../../../shared/widgets/top_liquid_snackbar.dart';
import '../../history/data/meal_entry.dart';
import '../../history/presentation/history_provider.dart';
import '../domain/pantry_item.dart';
import 'pantry_provider.dart';

class PantryItemCard extends StatefulWidget {
  const PantryItemCard({
    super.key,
    required this.item,
  });

  final PantryItem item;

  @override
  State<PantryItemCard> createState() => _PantryItemCardState();
}

class _PantryItemCardState extends State<PantryItemCard> {
  bool _isLogging = false;

  Future<void> _quickConsume() async {
    if (widget.item.isFinished) {
      _showRefillSheet();
      return;
    }

    final amount = widget.item.defaultServingSize > widget.item.remainingAmount
        ? widget.item.remainingAmount
        : widget.item.defaultServingSize;

    final currentCategory = MealTimeCategory.fromCurrentTime();

    setState(() => _isLogging = true);
    HapticFeedback.lightImpact();

    try {
      final pantryProvider = context.read<PantryProvider>();
      final historyProvider = context.read<HistoryProvider>();

      await pantryProvider.consumePortion(
        item: widget.item,
        amount: amount,
        category: currentCategory,
        historyProvider: historyProvider,
      );

      if (mounted) {
        TopLiquidSnackBar.show(
          context,
          message: '+${amount.toStringAsFixed(0)} ${widget.item.unit} ${widget.item.name} dicatat ke ${currentCategory.label}',
          type: AppNotificationType.success,
        );
      }
    } finally {
      if (mounted) setState(() => _isLogging = false);
    }
  }

  void _showCustomConsumeSheet() {
    final controller = TextEditingController(
      text: widget.item.defaultServingSize.toStringAsFixed(0),
    );
    var selectedCategory = MealTimeCategory.fromCurrentTime();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isPink = Theme.of(ctx).extension<AppVisualMeta>()?.isPink ?? false;
          final palette = Theme.of(ctx).extension<DashboardTilePalette>();
          final primaryColor = palette?.scan ?? (isPink ? const Color(0xFFE91E63) : AppColors.accent);

          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catat Porsi Kustom',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Jumlah Konsumsi (${widget.item.unit})',
                    suffixText: widget.item.unit,
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Waktu Makan',
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: MealTimeCategory.values.map((cat) {
                      final isSel = selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(cat.label),
                          selected: isSel,
                          selectedColor: primaryColor.withValues(alpha: 0.15),
                          labelStyle: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? primaryColor : AppColors.textPrimary,
                          ),
                          side: BorderSide(
                            color: isSel ? primaryColor : Colors.grey.withValues(alpha: 0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onSelected: (_) => setModalState(() => selectedCategory = cat),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedPressable(
                  onPressed: () async {
                    final amount = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
                    if (amount <= 0) return;
                    Navigator.pop(sheetCtx);

                    final pantryProvider = context.read<PantryProvider>();
                    final historyProvider = context.read<HistoryProvider>();
                    await pantryProvider.consumePortion(
                      item: widget.item,
                      amount: amount,
                      category: selectedCategory,
                      historyProvider: historyProvider,
                    );
                    if (mounted) {
                      TopLiquidSnackBar.show(
                        context,
                        message: '+${amount.toStringAsFixed(0)} ${widget.item.unit} ${widget.item.name} dicatat ke ${selectedCategory.label}',
                        type: AppNotificationType.success,
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Simpan ke Jurnal',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showRefillSheet() {
    final controller = TextEditingController(
      text: widget.item.totalCapacity.toStringAsFixed(0),
    );

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        final isPink = Theme.of(sheetCtx).extension<AppVisualMeta>()?.isPink ?? false;
        final palette = Theme.of(sheetCtx).extension<DashboardTilePalette>();
        final primaryColor = palette?.scan ?? (isPink ? const Color(0xFFE91E63) : AppColors.accent);

        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Isi Ulang (Refill)',
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Reset sisa isi ${widget.item.name} ke kapasitas penuh.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Kapasitas Baru (${widget.item.unit})',
                  suffixText: widget.item.unit,
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AnimatedPressable(
                onPressed: () async {
                  final newCap = double.tryParse(controller.text.replaceAll(',', '.')) ?? widget.item.totalCapacity;
                  Navigator.pop(sheetCtx);
                  await context.read<PantryProvider>().refillItem(widget.item.id, newCapacity: newCap);
                  if (mounted) {
                    TopLiquidSnackBar.show(
                      context,
                      message: '${widget.item.name} berhasil diisi ulang!',
                      type: AppNotificationType.success,
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Isi Ulang Penuh',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visualMeta = theme.extension<AppVisualMeta>();
    final palette = theme.extension<DashboardTilePalette>();
    final isPink = visualMeta?.isPink ?? false;
    final primaryColor = palette?.scan ?? (isPink ? const Color(0xFFE91E63) : AppColors.accent);

    final item = widget.item;
    final pct = item.remainingPercent;

    Color progressColor = primaryColor;
    if (item.isFinished) {
      progressColor = Colors.grey.shade400;
    } else if (item.isLowStock) {
      progressColor = const Color(0xFFE53935);
    } else if (pct < 0.4) {
      progressColor = const Color(0xFFF59E0B);
    }

    final cardBorder = isPink
        ? primaryColor.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.06);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Thumbnail Image with Location Badge
                Stack(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: item.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: item.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (_, _, _) => Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.grey.shade400,
                                size: 26,
                              ),
                            )
                          : Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.grey.shade400,
                              size: 26,
                            ),
                    ),
                    Positioned(
                      left: 3,
                      top: 3,
                      child: Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          item.location == PantryLocation.fridge
                              ? Icons.ac_unit_rounded
                              : (item.location == PantryLocation.shelf
                                  ? Icons.inventory_2_outlined
                                  : Icons.severe_cold_rounded),
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // 2. Name, Brand & Expiry Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (item.brand != null && item.brand!.isNotEmpty) ...[
                            Flexible(
                              child: Text(
                                item.brand!.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (item.isExpiringSoon)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'Exp Segera',
                                style: GoogleFonts.dmSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFB45309),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: item.isFinished
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item.caloriesPer100.toStringAsFixed(0)} kkal • ${item.proteinPer100.toStringAsFixed(1)}g protein / 100${item.unit}',
                        style: GoogleFonts.dmSans(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. More Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: cardBorder),
                  ),
                  padding: EdgeInsets.zero,
                  onSelected: (val) {
                    if (val == 'custom') {
                      _showCustomConsumeSheet();
                    } else if (val == 'refill') {
                      _showRefillSheet();
                    } else if (val == 'delete') {
                      context.read<PantryProvider>().deleteItem(item.id);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'custom',
                      child: Row(
                        children: [
                          Icon(Icons.tune_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Porsi Kustom'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'refill',
                      child: Row(
                        children: [
                          Icon(Icons.replay_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Isi Ulang (Refill)'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 4. Sisa Kapasitas Progress Bar
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.isFinished
                          ? 'Habis'
                          : 'Sisa ${item.remainingAmount.toStringAsFixed(0)} / ${item.totalCapacity.toStringAsFixed(0)} ${item.unit}',
                      style: GoogleFonts.dmSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: item.isLowStock
                            ? const Color(0xFFDC2626)
                            : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.dmSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 5.5,
                    value: pct,
                    backgroundColor: Colors.grey.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(progressColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 5. Action Row: Expiry label & Quick Consume Button
            Row(
              children: [
                if (item.expiryDate != null)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 13.5,
                          color: item.isExpiringSoon
                              ? const Color(0xFFB45309)
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Exp: ${DateFormat('d MMM yyyy').format(item.expiryDate!)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: item.isExpiringSoon
                                  ? const Color(0xFFB45309)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Spacer(),
                AnimatedPressable(
                  onPressed: _isLogging ? null : _quickConsume,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: item.isFinished
                          ? Colors.grey.withValues(alpha: 0.12)
                          : primaryColor,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    alignment: Alignment.center,
                    child: _isLogging
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.isFinished ? Icons.replay_rounded : Icons.add_rounded,
                                size: 16,
                                color: item.isFinished ? AppColors.textSecondary : Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.isFinished
                                    ? 'Isi Ulang'
                                    : '+ ${item.defaultServingSize.toStringAsFixed(0)} ${item.unit}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: item.isFinished ? AppColors.textSecondary : Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
