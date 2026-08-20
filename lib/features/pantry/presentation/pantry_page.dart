import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/animated_pressable.dart';
import '../../scanner/presentation/scanner_page.dart';
import '../domain/pantry_item.dart';
import 'pantry_item_card.dart';
import 'pantry_provider.dart';

class PantryPage extends StatefulWidget {
  const PantryPage({super.key});

  @override
  State<PantryPage> createState() => _PantryPageState();
}

class _PantryPageState extends State<PantryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openScanner() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const ScannerPage(),
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.fastEaseInToSlowEaseOut,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.18),
              end: Offset.zero,
            ).animate(curve),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1.0).animate(curve),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visualMeta = theme.extension<AppVisualMeta>();
    final palette = theme.extension<DashboardTilePalette>();
    final isPink = visualMeta?.isPink ?? false;
    final primaryColor = palette?.scan ?? (isPink ? const Color(0xFFE91E63) : AppColors.accent);

    final pantry = context.watch<PantryProvider>();
    final filteredItems = pantry.filteredItems;
    final totalItems = pantry.items.length;
    final fridgeCount = pantry.fridgeItems.length;
    final shelfCount = pantry.shelfItems.length;
    final lowStockCount = pantry.lowStockItems.length;

    final cardBorder = isPink
        ? primaryColor.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.06);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: AnimatedPressable(
        onPressed: _openScanner,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Scan ke Pantry',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Frosted SliverAppBar (Consistent with App System)
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black87,
            elevation: 0,
            scrolledUnderElevation: 0,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeInOutCubic,
                  color: theme.scaffoldBackgroundColor.withValues(alpha: 0.72),
                ),
              ),
            ),
            title: const Text(
              'Kulkas & Pantry',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 2. Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: pantry.setSearchQuery,
                  style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Cari susu, roti, oats di pantry...',
                    hintStyle: GoogleFonts.dmSans(fontSize: 13.5, color: AppColors.textSecondary),
                    prefixIcon: Icon(Icons.search_rounded, size: 20, color: primaryColor),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              pantry.setSearchQuery('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
          ),

          // 3. Category Filter Chips
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _PantryFilterChip(
                    label: 'Semua ($totalItems)',
                    isSelected: pantry.selectedLocationFilter == null && !pantry.filterLowStockOnly,
                    onTap: () => pantry.setLocationFilter(null),
                    primaryColor: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  _PantryFilterChip(
                    label: 'Kulkas ($fridgeCount)',
                    isSelected: pantry.selectedLocationFilter == PantryLocation.fridge,
                    onTap: () => pantry.setLocationFilter(PantryLocation.fridge),
                    primaryColor: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  _PantryFilterChip(
                    label: 'Rak ($shelfCount)',
                    isSelected: pantry.selectedLocationFilter == PantryLocation.shelf,
                    onTap: () => pantry.setLocationFilter(PantryLocation.shelf),
                    primaryColor: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  _PantryFilterChip(
                    label: 'Menipis ($lowStockCount)',
                    isSelected: pantry.filterLowStockOnly,
                    onTap: () => pantry.setLowStockFilter(!pantry.filterLowStockOnly),
                    primaryColor: primaryColor,
                  ),
                ],
              ),
            ),
          ),

          // 4. Item List or Empty State
          if (filteredItems.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.kitchen_rounded, size: 52, color: primaryColor),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Kulkas & Pantry Kosong',
                        style: GoogleFonts.dmSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Scan makanan atau minuman kemasan multi-porsi (seperti 1L Susu, Roti, atau Oats) untuk pencatatan instan 1-tap kapan saja.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filteredItems[index];
                    return PantryItemCard(
                      key: ValueKey(item.id),
                      item: item,
                    );
                  },
                  childCount: filteredItems.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PantryFilterChip extends StatelessWidget {
  const _PantryFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPink = theme.extension<AppVisualMeta>()?.isPink ?? false;
    final cardBorder = isPink
        ? primaryColor.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.08);

    return AnimatedPressable(
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? primaryColor : cardBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
