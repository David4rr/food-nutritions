import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/animated_scan_frame.dart';
import '../../../shared/widgets/top_liquid_snackbar.dart';
import '../../history/presentation/history_provider.dart';
import '../../product/data/product_cache_repository.dart';
import '../../product/presentation/product_detail_page.dart';
import 'scanner_provider.dart';
import '../../../shared/routes/expanding_page_route.dart'; // ponytail: Expanding header

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  late final MobileScannerController _controller;
  // [NEW] Provider dibuat di level widget agar lifecycle sejalan dengan kamera
  late final ScannerProvider _scannerProvider;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
    _scannerProvider = ScannerProvider(
      cacheRepository: context.read<ProductCacheRepository>(),
      historyProvider: context.read<HistoryProvider>(),
    );
    _scannerProvider.addListener(_onScannerProviderChanged);
  }

  @override
  void dispose() {
    _scannerProvider.removeListener(_onScannerProviderChanged);
    _scannerProvider.dispose();
    _controller.dispose(); // [FIX] Kamera selalu di-dispose saat widget hilang
    super.dispose();
  }

  void _onScannerProviderChanged() {
    if (!mounted) return;

    final status = _scannerProvider.status;

    if (status == ScanStatus.success) {
      HapticFeedback.mediumImpact();
      final product = _scannerProvider.result!;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, _, _) => ProductDetailPage(product: product),
          transitionsBuilder: (_, animation, _, child) {
            final slideAnimation =
                Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutExpo),
                );

            return SlideTransition(position: slideAnimation, child: child);
          },
        ),
      );
    } else if (status == ScanStatus.error) {
      final err = _scannerProvider.error!;
      TopLiquidSnackBar.show(
        context,
        message: err.message,
        type: AppNotificationType.error,
        duration: const Duration(
          seconds: 5,
        ), // [FIX] Durasi lebih lama agar sempat terbaca
      );
      _scannerProvider.reset();
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    // Guard: abaikan jika sedang proses
    if (_scannerProvider.isLoading) return;
    final value = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (value == null || value.isEmpty) return;

    // Delegasikan ke provider
    await _scannerProvider.processBarcode(value);
  }

  // [NEW] Modal Bottom Sheet input barcode manual (sangat smooth & native feel)
  Future<void> _showManualInputDialog() async {
    // [FIX] Matikan kamera sepenuhnya sebelum memunculkan dialog/keyboard
    await _controller.stop();
    await Future.delayed(
      const Duration(milliseconds: 50),
    ); // Jeda minimal untuk stabilitas engine

    String inputText = '';
    final barcode = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pill Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Input Barcode Manual',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  onChanged: (val) => inputText = val,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: '8990000123456',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      letterSpacing: 1.0,
                    ),
                    prefixIcon: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.accentStrong,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.accentStrong,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentStrong,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(inputText.trim()),
                    child: const Text(
                      'Cari Produk',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    // [FIX] Segera nyalakan ulang kamera setelah dialog tertutup
    _controller.start();

    if (barcode == null || barcode.isEmpty) return;

    await _scannerProvider.processBarcode(barcode);
  }

  @override
  Widget build(BuildContext context) {
    // [NEW] ListenableBuilder → rebuild hanya bagian UI yang bergantung state
    return ListenableBuilder(
      listenable: _scannerProvider,
      builder: (context, _) {
        final isLoading = _scannerProvider.isLoading;

        return Scaffold(
          backgroundColor: const Color(0xFF2FB8A4), // palette.scan
          resizeToAvoidBottomInset: false,
          extendBodyBehindAppBar: true, // [NEW] Immersive AppBar
          appBar: ExpandingPageHeader(
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text(
                'Scan Barcode',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                ),
              ),
            ),
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: isLoading ? null : _onDetect,
              ),
              // [FIX] Dark overlay dengan scan frame di tengah
              Container(
                color: Colors.black.withValues(alpha: 0.24),
                alignment: Alignment.center,
                child: const AnimatedScanFrame(),
              ),

              // [NEW] Loading Overlay penuh saat API sedang diproses
              if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.60),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 64,
                        height: 64,
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                          strokeWidth: 4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Memproses barcode...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mengambil data nutrisi produk',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

              // Hint bar bawah yang lebih clean dan estetik
              if (!isLoading)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 48,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Arahkan kamera ke barcode produk',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          shadows: [
                            Shadow(color: Colors.black87, blurRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.35),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          elevation: 0,
                        ),
                        onPressed: _showManualInputDialog,
                        icon: const Icon(Icons.keyboard_alt_outlined, size: 20),
                        label: const Text('Input Manual'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
