import 'dart:async';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/top_liquid_snackbar.dart';
import '../data/product_history.dart';
import 'history_provider.dart';
import '../../dashboard/presentation/dashboard_sections.dart';
import '../../../shared/widgets/staggered_animated_tile.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  bool _isTrashHover = false;
  bool _isTrashFlash = false;
  late final AnimationController _trashShakeController;
  late final Animation<double> _trashShakeTurns;

  @override
  void initState() {
    super.initState();
    _trashShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _trashShakeTurns =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -0.025), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -0.025, end: 0.024), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0.024, end: -0.018), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -0.018, end: 0.012), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0.012, end: 0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _trashShakeController, curve: Curves.easeOut),
        );

    _trashShakeController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _trashShakeController.dispose();
    super.dispose();
  }

  Future<void> _deleteItem(HistoryProvider history, ProductHistory item) async {
    await history.removeItem(item);
    if (!mounted) return;
    TopLiquidSnackBar.show(
      context,
      message: '${item.name} dihapus dari riwayat.',
      type: AppNotificationType.info,
    );
  }

  Future<void> _confirmClearAll(HistoryProvider history) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Riwayat?'),
        content: const Text('Semua riwayat pemindaian nutrisi akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (remove != true) return;
    await history.clear();
    if (!mounted) return;
    TopLiquidSnackBar.show(
      context,
      message: 'Semua riwayat berhasil dihapus.',
      type: AppNotificationType.success,
    );
  }

  void _playTrashDropFx() {
    setState(() => _isTrashFlash = true);
    _trashShakeController.forward(from: 0);
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _isTrashFlash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final isPink =
        Theme.of(context).extension<AppVisualMeta>()?.isPink ?? false;

    final tileColor = isPink
        ? const Color(0xFFFFCC80)
        : const Color(0xFFFFCC80); // Soft orange theme

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.72),
                ),
              ),
            ),
            foregroundColor: Colors.black87,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text(
              'Riwayat Nutrisi',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              DragTarget<ProductHistory>(
                onWillAcceptWithDetails: (details) {
                  if (!_isTrashHover) {
                    setState(() => _isTrashHover = true);
                  }
                  return true;
                },
                onLeave: (_) {
                  if (_isTrashHover) {
                    setState(() => _isTrashHover = false);
                  }
                },
                onAcceptWithDetails: (details) {
                  setState(() => _isTrashHover = false);
                  _playTrashDropFx();
                  _deleteItem(history, details.data);
                },
                builder: (context, candidateData, rejectedData) {
                  final isActive = _isTrashHover || candidateData.isNotEmpty;
                  final isEnabled = history.items.isNotEmpty;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: IconButton(
                      tooltip: 'Tap: Hapus Semua | Drop: Hapus Item',
                      onPressed: isEnabled
                          ? () => _confirmClearAll(history)
                          : null,
                      icon: _TrashDropIcon(
                        isActive: isActive,
                        isEnabled: isEnabled,
                        flash: _isTrashFlash,
                        shakeTurns: _trashShakeTurns.value,
                        isPink: isPink,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: history.items.isEmpty
                  ? const Center(child: Text('Belum ada riwayat.'))
                  : StaggeredAnimatedTile(
                      index: 0,
                      child: RecentScansSection(
                        items: history.items,
                        maxItems: null,
                        groupByDay: true,
                        showDateBadge: false,
                        enableDragDelete: true,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrashDropIcon extends StatelessWidget {
  const _TrashDropIcon({
    required this.isActive,
    required this.isEnabled,
    required this.flash,
    required this.shakeTurns,
    required this.isPink,
  });

  final bool isActive;
  final bool isEnabled;
  final bool flash;
  final double shakeTurns;
  final bool isPink;

  @override
  Widget build(BuildContext context) {
    final accent = isEnabled
        ? (isPink ? const Color(0xFFC2185B) : Colors.red.shade600)
        : Colors.grey.shade500;
    final iconData = flash
        ? Icons.delete_forever_rounded
        : isActive
        ? Icons.delete_outline_rounded
        : Icons.delete_sweep_rounded;
    return AnimatedRotation(
      duration: const Duration(milliseconds: 80),
      turns: shakeTurns,
      child: AnimatedScale(
        scale: flash
            ? 1.26
            : isActive
            ? 1.16
            : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: flash
                ? accent.withValues(alpha: 0.34)
                : isActive
                ? accent.withValues(alpha: 0.22)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: Icon(
                iconData,
                key: ValueKey<String>('trash-${iconData.codePoint}'),
                color: accent,
                size: flash ? 24 : 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
