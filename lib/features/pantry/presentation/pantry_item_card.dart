import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
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
      _showRefillDialog();
      return;
    }

    final amount = widget.item.defaultServingSize > widget.item.remainingAmount
        ? widget.item.remainingAmount
        : widget.item.defaultServingSize;

    final currentCategory = MealTimeCategory.fromCurrentTime();

    setState(() => _isLogging = true);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2FB8A4),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '+${amount.toStringAsFixed(0)} ${widget.item.unit} dicatat ke ${currentCategory.label}!',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLogging = false);
    }
  }

  void _showCustomConsumeDialog() {
    final controller = TextEditingController(
      text: widget.item.defaultServingSize.toStringAsFixed(0),
    );
    var selectedCategory = MealTimeCategory.fromCurrentTime();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Catat Porsi Kustom',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Jumlah Konsumsi (${widget.item.unit})',
                    suffixText: widget.item.unit,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Waktu Makan:',
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: MealTimeCategory.values.map((cat) {
                    final isSel = selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat.label, style: const TextStyle(fontSize: 11)),
                      selected: isSel,
                      onSelected: (_) => setDialogState(() => selectedCategory = cat),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;
                  if (amount <= 0) return;
                  Navigator.pop(dialogCtx);

                  final pantryProvider = context.read<PantryProvider>();
                  final historyProvider = context.read<HistoryProvider>();
                  await pantryProvider.consumePortion(
                    item: widget.item,
                    amount: amount,
                    category: selectedCategory,
                    historyProvider: historyProvider,
                  );
                },
                child: const Text('Catat'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRefillDialog() {
    final controller = TextEditingController(
      text: widget.item.totalCapacity.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Isi Ulang (Refill)',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset sisa isi ${widget.item.name} ke kapasitas penuh.',
              style: GoogleFonts.dmSans(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Kapasitas Baru (${widget.item.unit})',
                suffixText: widget.item.unit,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newCap = double.tryParse(controller.text.replaceAll(',', '.')) ?? widget.item.totalCapacity;
              Navigator.pop(dialogCtx);
              await context.read<PantryProvider>().refillItem(widget.item.id, newCapacity: newCap);
            },
            child: const Text('Isi Ulang'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visualMeta = Theme.of(context).extension<AppVisualMeta>();
    final isPink = visualMeta?.isPink ?? false;
    final primaryColor = isPink ? const Color(0xFFE91E63) : const Color(0xFF2FB8A4);

    final item = widget.item;
    final pct = item.remainingPercent;

    Color progressColor = primaryColor;
    if (item.isFinished) {
      progressColor = Colors.grey.shade400;
    } else if (item.isLowStock) {
      progressColor = Colors.red.shade400;
    } else if (pct < 0.5) {
      progressColor = Colors.amber.shade600;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: item.isFinished
              ? Colors.grey.shade200
              : (item.isLowStock ? Colors.red.shade100 : Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Thumbnail Image with Location Icon Badge
                Stack(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
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
                      left: 2,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          item.location == PantryLocation.fridge
                              ? Icons.ac_unit_rounded
                              : (item.location == PantryLocation.shelf
                                  ? Icons.shelves
                                  : Icons.severe_cold_rounded),
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // 2. Name, Brand & Expiry Warning
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (item.brand != null && item.brand!.isNotEmpty) ...[
                            Text(
                              item.brand!.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (item.isExpiringSoon)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Segera Exp',
                                style: GoogleFonts.dmSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.amber.shade900,
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
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: item.isFinished ? Colors.grey.shade500 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${item.caloriesPer100.toStringAsFixed(0)} kkal • ${item.proteinPer100.toStringAsFixed(1)}g prot per 100${item.unit}',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. More Menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey.shade600),
                  padding: EdgeInsets.zero,
                  onSelected: (val) {
                    if (val == 'custom') {
                      _showCustomConsumeDialog();
                    } else if (val == 'refill') {
                      _showRefillDialog();
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
                          Text('Catat Porsi Kustom'),
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
            const SizedBox(height: 10),

            // 4. Fill Bar / Capacity Indicator
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
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: item.isLowStock ? Colors.red.shade700 : Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: progressColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: pct,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(progressColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 5. Action Row (Quick 1-Tap Log Button)
            Row(
              children: [
                if (item.expiryDate != null)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.event_outlined, size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Exp: ${DateFormat('d MMM').format(item.expiryDate!)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: item.isExpiringSoon ? Colors.amber.shade900 : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Spacer(),
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: _isLogging ? null : _quickConsume,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.isFinished ? Colors.grey.shade300 : primaryColor,
                      foregroundColor: item.isFinished ? Colors.grey.shade700 : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLogging
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.isFinished ? Icons.replay_rounded : Icons.add_rounded,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.isFinished
                                    ? 'Isi Ulang'
                                    : 'Tuang ${item.defaultServingSize.toStringAsFixed(0)} ${item.unit}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
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
