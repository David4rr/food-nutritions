import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../history/presentation/history_provider.dart';
import '../../scanner/presentation/scanner_page.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/staggered_animated_tile.dart';
import '../../../shared/utils/navigator_extension.dart';
import 'home_empty_state.dart';
import 'home_history_item.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F9), // Flat background
      appBar: AppBar(
        title: const Text(
          'Food Nutritions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (history.items.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
              ),
              tooltip: 'Clear History',
              onPressed: history.clear,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2FB8A4), // Metro Teal
        foregroundColor: Colors.white,
        elevation: 2,
        onPressed: () {
          context.pushRoute(const ScannerPage());
        },
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text(
          'Scan Baru',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: history.isLoading
            ? LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 700 ? 2 : 1;
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 100,
                    ),
                    itemCount: 6, // Tampilkan 6 skeleton sebagai placeholder
                    itemBuilder: (_, _) =>
                        const SkeletonTile(width: double.infinity, height: 100),
                  );
                },
              )
            : history.items.isEmpty
            ? const HomeEmptyState()
            : LayoutBuilder(
                builder: (context, constraints) {
                  // Grid for large screens, list for mobile
                  final crossAxisCount = constraints.maxWidth > 700 ? 2 : 1;

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 100, // Fixed height per item
                    ),
                    itemCount: history.items.length,
                    itemBuilder: (_, index) {
                      final item = history.items[index];
                      return StaggeredAnimatedTile(
                        index: index,
                        child: HomeHistoryItem(item: item),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
