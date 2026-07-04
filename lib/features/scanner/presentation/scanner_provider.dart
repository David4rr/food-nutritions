import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../shared/utils/retry_helper.dart';
import '../../history/presentation/history_provider.dart';
import '../../product/data/open_food_facts_service.dart';
import '../../product/data/product_cache_repository.dart';
import '../../product/domain/product_view_data.dart';

// --- State Enum ---------------------------------------------------------

enum ScanStatus { idle, loading, success, error }

// Error types untuk penanganan yang lebih spesifik di UI
enum ScanErrorType { notFound, timeout, network, unknown }

class ScanError {
  const ScanError(this.type, this.message);
  final ScanErrorType type;
  final String message;
}

// --- Provider -----------------------------------------------------------

class ScannerProvider extends ChangeNotifier {
  ScannerProvider({
    required ProductCacheRepository cacheRepository,
    required HistoryProvider historyProvider,
  })  : _cacheRepository = cacheRepository,
        _historyProvider = historyProvider;

  final ProductCacheRepository _cacheRepository;
  final HistoryProvider _historyProvider;

  ScanStatus _status = ScanStatus.idle;
  ScanError? _error;
  ProductViewData? _result;

  ScanStatus get status => _status;
  ScanError? get error => _error;
  ProductViewData? get result => _result;
  bool get isLoading => _status == ScanStatus.loading;

  // Dipanggil sekali per barcode, guard dari double-scan ada di ScannerPage
  Future<void> processBarcode(String barcode) async {
    if (_status == ScanStatus.loading) return;

    _status = ScanStatus.loading;
    _error = null;
    _result = null;
    notifyListeners();

    try {
      final service = OpenFoodFactsService(cacheRepository: _cacheRepository);
      final data = await service.fetchByBarcode(barcode);
      
      // Pastikan tanggal scan selalu saat ini, meskipun data berasal dari cache (JSON lama)
      final scanData = data.copyWith(scannedAt: DateTime.now());

      // Simpan ke history
      await _historyProvider.addScan(scanData);

      _result = scanData;
      _status = ScanStatus.success;
    } on TimeoutException {
      _error = const ScanError(
        ScanErrorType.timeout,
        'Server tidak merespons. Periksa koneksi internet dan coba lagi.',
      );
      _status = ScanStatus.error;
    } on SocketException {
      _error = const ScanError(
        ScanErrorType.network,
        'Tidak ada koneksi internet. Pastikan WiFi atau data aktif.',
      );
      _status = ScanStatus.error;
    } on RetryException catch (e) {
      // RetryException dari retry_helper: bisa network atau timeout
      final msg = e.lastError.toString().toLowerCase();
      if (msg.contains('timeout') || msg.contains('timed out')) {
        _error = const ScanError(
          ScanErrorType.timeout,
          'Koneksi terlalu lambat. Coba lagi beberapa saat.',
        );
      } else if (msg.contains('socket') || msg.contains('network') || msg.contains('connection')) {
        _error = const ScanError(
          ScanErrorType.network,
          'Koneksi bermasalah setelah beberapa percobaan.',
        );
      } else {
        _error = const ScanError(
          ScanErrorType.notFound,
          'Produk tidak ditemukan di database OpenFoodFacts.',
        );
      }
      _status = ScanStatus.error;
    } catch (e) {
      // Tangkap Exception umum dari fetchByBarcode (misal: 'Produk tidak ditemukan...')
      final msg = e.toString().toLowerCase();
      if (msg.contains('tidak ditemukan') || msg.contains('not found')) {
        _error = const ScanError(
          ScanErrorType.notFound,
          'Produk tidak ditemukan. Coba input barcode secara manual.',
        );
      } else {
        _error = ScanError(ScanErrorType.unknown, e.toString());
      }
      _status = ScanStatus.error;
    }

    notifyListeners();
  }

  // Reset ke idle agar scanner bisa dipakai kembali setelah error
  void reset() {
    _status = ScanStatus.idle;
    _error = null;
    _result = null;
    notifyListeners();
  }
}
