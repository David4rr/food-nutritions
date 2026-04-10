import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/animated_scan_frame.dart';
import '../../../shared/widgets/top_liquid_snackbar.dart';
import '../../history/presentation/history_provider.dart';
import '../../product/data/open_food_facts_service.dart';
import '../../product/presentation/product_detail_page.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  final OpenFoodFactsService _service = OpenFoodFactsService();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final value = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (value == null || value.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      final result = await _service.fetchByBarcode(value);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      await context.read<HistoryProvider>().addScan(result);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ProductDetailPage(product: result)),
      );
    } catch (_) {
      if (!mounted) return;
      TopLiquidSnackBar.show(
        context,
        message: 'Produk tidak ditemukan atau koneksi bermasalah.',
        type: AppNotificationType.error,
      );
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Container(
            color: Colors.black.withValues(alpha: 0.24),
            alignment: Alignment.center,
            child: const AnimatedScanFrame(),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 28,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                _isProcessing
                    ? 'Memproses barcode...'
                    : 'Posisikan barcode di dalam frame untuk scan otomatis',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
