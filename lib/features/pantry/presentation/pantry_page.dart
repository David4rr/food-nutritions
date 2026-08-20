import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/utils/navigator_extension.dart';
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

  @override
  Widget build(BuildContext context) {
    final visualMeta = Theme.of(context).extension<AppVisualMeta>();
    final isPink = visualMeta?.isPink ?? false;
    final primaryColor = isPink ? const Color(0xFFE91E63) : const Color(0xFF2FB8A4);

    final pantry = context.watch<PantryProvider>();
    final filteredItems = pantry.filteredItems;
    final totalItems = pantry.items.length;
    final fridgeCount = pantry.fridgeItems.length;
    final shelfCount = pantry.shelfItems.length;
    final lowStockCount = pantry.lowStockItems.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.pushRoute(const ScannerPage());
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: Text(
          'Scan ke Pantry',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Frosted SliverAppBar
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Kulkas & Pantry',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w800),
            ),
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.72),
                ),
              ),
            ),
          ),

          // 2. Summary Bento Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      primaryColor.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.kitchen_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pantry Cepat 1-Tap',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$totalItems produk ($fridgeCount di kulkas, $shelfCount di rak)',
                            style: GoogleFonts.dmSans(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (lowStockCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade900.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$lowStockCount Menipis',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchController,
                onChanged: pantry.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Cari susu, roti, oats di pantry...',
                  hintStyle: GoogleFonts.dmSans(fontSize: 13, color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            pantry.setSearchQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
            ),
          ),

          // 4. Category Filter Chips
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Semua ($totalItems)',
                    isSelected: pantry.selectedLocationFilter == null && !pantry.filterLowStockOnly,
                    onTap: () => pantry.setLocationFilter(null),
                    primaryColor: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '🧊 Kulkas ($fridgeCount)',
                    isSelected: pantry.selectedLocationFilter == PantryLocation.fridge,
                    onTap: () => pantry.setLocationFilter(PantryLocation.fridge),
                    primaryColor: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '🥫 Rak ($shelfCount)',
                    isSelected: pantry.selectedLocationFilter == PantryLocation.shelf,
                    onTap: () => pantry.setLocationFilter(PantryLocation.shelf),
                    primaryColor: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '⚠️ Menipis ($lowStockCount)',
                    isSelected: pantry.filterLowStockOnly,
                    onTap: () => pantry.setLowStockFilter(!pantry.filterLowStockOnly),
                    primaryColor: primaryColor,
                  ),
                ],
              ),
            ),
          ),

          // 5. Item List or Empty State
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
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.kitchen_rounded, size: 54, color: primaryColor),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Kulkas & Pantry Kosong',
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Scan produk kemasan berulang (seperti 1L Susu, Roti Gandum, Oats) lalu simpan ke kulkas untuk pencatatan instan 1-tap!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => context.pushRoute(const ScannerPage()),
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                        label: Text(
                          'Scan Produk Baru',
                          style: GoogleFonts.dmSans(fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
