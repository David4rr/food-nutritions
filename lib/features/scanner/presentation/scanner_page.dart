import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/routes/expanding_page_route.dart';
import '../../../shared/widgets/animated_pressable.dart';
import '../../../shared/widgets/animated_scan_frame.dart';
import '../../../shared/widgets/top_liquid_snackbar.dart';
import '../../history/presentation/history_provider.dart';
import '../../ocr/data/ocr_service.dart';
import '../../ocr/presentation/ocr_nutrition_review_sheet.dart';
import '../../ocr/presentation/ocr_scanning_overlay.dart';
import '../../product/data/product_cache_repository.dart';
import '../../product/presentation/product_detail_page.dart';
import 'scanner_provider.dart';

enum ScannerViewMode { barcode, ocr }

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  late final MobileScannerController _controller;
  late final ScannerProvider _scannerProvider;
  final ImagePicker _imagePicker = ImagePicker();
  final OcrService _ocrService = OcrService();
  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = [];
  String? _capturedScanningImagePath;
  bool _isProcessing = false;
  bool _isOcrProcessing = false;
  bool _isTorchOn = false;
  bool _isCameraInitializing = false;
  ScannerViewMode _mode = ScannerViewMode.barcode;

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
    _cameraController?.dispose();
    _scannerProvider.removeListener(_onScannerProviderChanged);
    _scannerProvider.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _setMode(ScannerViewMode newMode) async {
    if (_mode == newMode) return;
    HapticFeedback.selectionClick();
    setState(() {
      _mode = newMode;
      _isTorchOn = false;
    });

    if (newMode == ScannerViewMode.ocr) {
      await _controller.stop();
      await _initOcrCamera();
    } else {
      await _cameraController?.dispose();
      _cameraController = null;
      if (mounted) {
        setState(() {});
        await _controller.start();
      }
    }
  }

  Future<void> _initOcrCamera() async {
    if (_isCameraInitializing) return;
    setState(() => _isCameraInitializing = true);

    try {
      if (_availableCameras.isEmpty) {
        _availableCameras = await availableCameras();
      }
      if (_availableCameras.isNotEmpty) {
        final backCamera = _availableCameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _availableCameras.first,
        );

        final controller = CameraController(
          backCamera,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await controller.initialize();
        if (!mounted) {
          await controller.dispose();
          return;
        }

        setState(() {
          _cameraController = controller;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isCameraInitializing = false);
    }
  }

  Future<void> _toggleTorch() async {
    if (_mode == ScannerViewMode.ocr && _cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final newMode = _isTorchOn ? FlashMode.off : FlashMode.torch;
        await _cameraController!.setFlashMode(newMode);
        setState(() => _isTorchOn = !_isTorchOn);
        HapticFeedback.selectionClick();
      } catch (_) {}
    } else {
      try {
        await _controller.toggleTorch();
        setState(() => _isTorchOn = !_isTorchOn);
        HapticFeedback.selectionClick();
      } catch (_) {}
    }
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
            final slideAnimation = Tween<Offset>(
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
      _isProcessing = false;
      _controller.start();
      final err = _scannerProvider.error!;

      if (err.type == ScanErrorType.notFound) {
        _showBarcodeNotFoundSheet();
      } else {
        TopLiquidSnackBar.show(
          context,
          message: err.message,
          type: AppNotificationType.error,
          duration: const Duration(seconds: 5),
        );
      }
      _scannerProvider.reset();
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    // Only detect barcodes automatically when in Barcode mode
    if (_mode != ScannerViewMode.barcode) return;
    if (_isProcessing || _isOcrProcessing || _scannerProvider.status != ScanStatus.idle) return;

    final value = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (value == null || value.isEmpty) return;

    _isProcessing = true;
    await _controller.stop();
    await _scannerProvider.processBarcode(value);
  }

  Future<void> _showBarcodeNotFoundSheet() async {
    await _controller.stop();

    if (!mounted) return;

    final palette = Theme.of(context).extension<DashboardTilePalette>();
    final scanColor = palette?.scan ?? Theme.of(context).primaryColor;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scanColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.document_scanner_rounded, size: 36, color: scanColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Barcode Tidak Ditemukan',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Produk ini belum ada di database. Anda bisa memindai langsung Tabel Informasi Nilai Gizi menggunakan OCR kamera.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            AnimatedPressable(
              onPressed: () {
                Navigator.pop(sheetCtx);
                _setMode(ScannerViewMode.ocr);
              },
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: scanColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Buka Kamera OCR',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pop(sheetCtx);
                _controller.start();
              },
              child: Text(
                'Coba Scan Barcode Lain',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takeOcrPicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      await _initOcrCamera();
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        if (!mounted) return;
        TopLiquidSnackBar.show(
          context,
          message: 'Kamera sedang disiapkan. Silakan tekan tombol sekali lagi.',
          type: AppNotificationType.warning,
        );
        return;
      }
    }

    HapticFeedback.heavyImpact();

    try {
      // 1. Take picture in-app directly from active camera controller
      final image = await _cameraController!.takePicture();

      // 2. Persist to permanent application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final targetFileName = 'ocr_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final persistentImage = await File(image.path).copy('${appDir.path}/$targetFileName');

      // 3. Crop image to exact Portrait Scan Window bounding area
      if (mounted) {
        final screenSize = MediaQuery.of(context).size;
        final frameWidth = (screenSize.width * 0.78).clamp(270.0, 310.0);
        final frameHeight = (frameWidth * 1.36).clamp(360.0, 420.0);
        final scanWindow = Rect.fromCenter(
          center: Offset(screenSize.width / 2, screenSize.height / 2 - 25),
          width: frameWidth,
          height: frameHeight,
        );

        await _cropImageToScanWindow(
          imagePath: persistentImage.path,
          screenSize: screenSize,
          scanWindow: scanWindow,
        );
      }

      // 4. Trigger Photo Scanning Animation Overlay with Cropped Image
      setState(() {
        _capturedScanningImagePath = persistentImage.path;
        _isOcrProcessing = true;
      });

      // 5. Run offline OCR and ensure pleasant visual scanning duration
      final stopwatch = Stopwatch()..start();
      final ocrResult = await _ocrService.recognizeNutritionFromImage(persistentImage.path);
      final elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed < 1400) {
        await Future.delayed(Duration(milliseconds: 1400 - elapsed));
      }

      if (!mounted) return;

      setState(() {
        _isOcrProcessing = false;
        _capturedScanningImagePath = null;
      });

      if (!ocrResult.hasValidData) {
        TopLiquidSnackBar.show(
          context,
          message: 'Angka gizi belum terdeteksi otomatis. Silakan periksa atau lengkapi data.',
          type: AppNotificationType.warning,
        );
      }

      // 6. Slide up review sheet immediately directly on top of camera
      await OcrNutritionReviewSheet.show(context, ocrResult);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOcrProcessing = false;
          _capturedScanningImagePath = null;
        });
        TopLiquidSnackBar.show(
          context,
          message: 'Gagal mengambil foto OCR: $e',
          type: AppNotificationType.error,
        );
      }
    }
  }

  Future<void> _cropImageToScanWindow({
    required String imagePath,
    required Size screenSize,
    required Rect scanWindow,
  }) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return;

      final orientedImage = img.bakeOrientation(decodedImage);
      final imgW = orientedImage.width;
      final imgH = orientedImage.height;

      final screenRatio = screenSize.width / screenSize.height;
      final imageRatio = imgW / imgH;

      double renderedW;
      double renderedH;
      double offsetX = 0;
      double offsetY = 0;

      if (imageRatio > screenRatio) {
        renderedH = screenSize.height;
        renderedW = screenSize.height * imageRatio;
        offsetX = (renderedW - screenSize.width) / 2;
      } else {
        renderedW = screenSize.width;
        renderedH = screenSize.width / imageRatio;
        offsetY = (renderedH - screenSize.height) / 2;
      }

      final cropX = (((scanWindow.left + offsetX) / renderedW) * imgW).round().clamp(0, imgW);
      final cropY = (((scanWindow.top + offsetY) / renderedH) * imgH).round().clamp(0, imgH);
      final cropW = ((scanWindow.width / renderedW) * imgW).round().clamp(1, imgW - cropX);
      final cropH = ((scanWindow.height / renderedH) * imgH).round().clamp(1, imgH - cropY);

      final croppedImage = img.copyCrop(
        orientedImage,
        x: cropX,
        y: cropY,
        width: cropW,
        height: cropH,
      );

      final croppedBytes = img.encodeJpg(croppedImage, quality: 95);
      await file.writeAsBytes(croppedBytes);
    } catch (_) {}
  }

  Future<void> _pickFromGallery() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );

      if (image == null) return;

      // Persist photo to permanent application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final targetFileName = 'ocr_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final persistentImage = await File(image.path).copy('${appDir.path}/$targetFileName');

      // Trigger Photo Scanning Animation Overlay
      setState(() {
        _capturedScanningImagePath = persistentImage.path;
        _isOcrProcessing = true;
      });

      final stopwatch = Stopwatch()..start();
      final ocrResult = await _ocrService.recognizeNutritionFromImage(persistentImage.path);
      final elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed < 1400) {
        await Future.delayed(Duration(milliseconds: 1400 - elapsed));
      }

      if (!mounted) return;

      setState(() {
        _isOcrProcessing = false;
        _capturedScanningImagePath = null;
      });

      if (!ocrResult.hasValidData) {
        TopLiquidSnackBar.show(
          context,
          message: 'Angka gizi belum terdeteksi otomatis. Silakan periksa atau lengkapi data.',
          type: AppNotificationType.warning,
        );
      }

      // Show the review sheet sliding up over the camera area
      await OcrNutritionReviewSheet.show(context, ocrResult);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOcrProcessing = false;
          _capturedScanningImagePath = null;
        });
        TopLiquidSnackBar.show(
          context,
          message: 'Gagal memproses gambar galeri: $e',
          type: AppNotificationType.error,
        );
      }
    }
  }

  // Modal Bottom Sheet input barcode manual
  Future<void> _showManualInputDialog() async {
    await _controller.stop();
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    final palette = Theme.of(context).extension<DashboardTilePalette>();
    final scanColor = palette?.scan ?? Theme.of(context).primaryColor;

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
                    prefixIcon: Icon(
                      Icons.qr_code_scanner_rounded,
                      color: scanColor,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: scanColor,
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
                      backgroundColor: scanColor,
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

    if (barcode == null || barcode.isEmpty) {
      _isProcessing = false;
      _controller.start();
      return;
    }

    _isProcessing = true;
    await _scannerProvider.processBarcode(barcode);
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<DashboardTilePalette>();
    final scanColor = palette?.scan ?? Theme.of(context).primaryColor;
    final screenSize = MediaQuery.of(context).size;
    final isOcr = _mode == ScannerViewMode.ocr;

    final frameWidth = isOcr ? (screenSize.width * 0.78).clamp(270.0, 310.0) : 260.0;
    final frameHeight = isOcr ? (frameWidth * 1.36).clamp(360.0, 420.0) : 260.0;

    final scanWindow = Rect.fromCenter(
      center: Offset(screenSize.width / 2, screenSize.height / 2 - (isOcr ? 25 : 0)),
      width: frameWidth,
      height: frameHeight,
    );

    return ListenableBuilder(
      listenable: _scannerProvider,
      builder: (context, _) {
        final isLoading = _scannerProvider.isLoading || _isOcrProcessing;

        return Scaffold(
          backgroundColor: scanColor,
          resizeToAvoidBottomInset: false,
          extendBodyBehindAppBar: true,
          appBar: ExpandingPageHeader(
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                isOcr ? 'Pindai Tabel Gizi (OCR)' : 'Scan Barcode',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                ),
              ),
            ),
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Live Camera Preview (In-App CameraPreview in OCR mode, MobileScanner in Barcode mode)
              if (isOcr && _cameraController != null && _cameraController!.value.isInitialized)
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _cameraController!.value.previewSize!.height,
                      height: _cameraController!.value.previewSize!.width,
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                )
              else if (isOcr && _isCameraInitializing)
                Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(color: scanColor),
                )
              else
                MobileScanner(
                  controller: _controller,
                  scanWindow: scanWindow,
                  onDetect: isLoading ? null : _onDetect,
                ),

              // 2. Dark Overlay & Centered Morphing Scan Frame
              Container(
                color: Colors.black.withValues(alpha: 0.28),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isOcr) const SizedBox(height: 20),
                    AnimatedScanFrame(
                      width: frameWidth,
                      height: frameHeight,
                      isOcrMode: isOcr,
                      color: scanColor,
                    ),
                    const SizedBox(height: 18),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      child: Text(
                        isOcr
                            ? 'Arahkan kamera ke Tabel Informasi Nilai Gizi'
                            : 'Arahkan kamera ke barcode produk',
                        key: ValueKey(isOcr),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          shadows: const [Shadow(color: Colors.black87, blurRadius: 6)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Top Mode Toggle Switcher (Barcode vs OCR)
              if (!isLoading)
                Positioned(
                  top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ModePill(
                            icon: Icons.qr_code_scanner_rounded,
                            label: 'Barcode',
                            isSelected: _mode == ScannerViewMode.barcode,
                            accentColor: scanColor,
                            onTap: () => _setMode(ScannerViewMode.barcode),
                          ),
                          _ModePill(
                            icon: Icons.document_scanner_rounded,
                            label: 'Tabel Gizi (OCR)',
                            isSelected: _mode == ScannerViewMode.ocr,
                            accentColor: scanColor,
                            onTap: () => _setMode(ScannerViewMode.ocr),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 4. Dedicated Photo Scanning HUD or Barcode Loading Overlay
              if (_capturedScanningImagePath != null && _isOcrProcessing)
                OcrScanningOverlay(
                  imagePath: _capturedScanningImagePath!,
                  accentColor: scanColor,
                )
              else if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.68),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          color: scanColor,
                          strokeWidth: 3.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Memproses Barcode...',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mengambil data nutrisi dari database',
                        style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),

              // 5. Bottom Action Controls Bar
              if (!isLoading)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    child: isOcr
                        ? _OcrControls(
                            key: const ValueKey('ocr_controls'),
                            scanColor: scanColor,
                            isTorchOn: _isTorchOn,
                            onToggleTorch: _toggleTorch,
                            onCapture: _takeOcrPicture,
                            onPickGallery: _pickFromGallery,
                          )
                        : _BarcodeControls(
                            key: const ValueKey('barcode_controls'),
                            scanColor: scanColor,
                            onSwitchToOcr: () => _setMode(ScannerViewMode.ocr),
                            onManualInput: _showManualInputDialog,
                          ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarcodeControls extends StatelessWidget {
  const _BarcodeControls({
    super.key,
    required this.scanColor,
    required this.onSwitchToOcr,
    required this.onManualInput,
  });

  final Color scanColor;
  final VoidCallback onSwitchToOcr;
  final VoidCallback onManualInput;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1. OCR Mode Switch Button
        AnimatedPressable(
          onPressed: onSwitchToOcr,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt_rounded, size: 18, color: scanColor),
                const SizedBox(width: 8),
                Text(
                  'Foto Tabel Gizi',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // 2. Manual Barcode Input Button
        AnimatedPressable(
          onPressed: onManualInput,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.keyboard_alt_outlined, size: 18, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  'Input Manual',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OcrControls extends StatelessWidget {
  const _OcrControls({
    super.key,
    required this.scanColor,
    required this.isTorchOn,
    required this.onToggleTorch,
    required this.onCapture,
    required this.onPickGallery,
  });

  final Color scanColor;
  final bool isTorchOn;
  final VoidCallback onToggleTorch;
  final VoidCallback onCapture;
  final VoidCallback onPickGallery;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 1. Flash Light Toggle
        AnimatedPressable(
          onPressed: onToggleTorch,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isTorchOn ? scanColor : Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: isTorchOn ? Colors.white : Colors.white.withValues(alpha: 0.25),
                width: isTorchOn ? 2 : 1,
              ),
            ),
            child: Icon(
              isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),

        // 2. Main Shutter Button
        GestureDetector(
          onTap: () {
            HapticFeedback.heavyImpact();
            onCapture();
          },
          child: Container(
            width: 78,
            height: 78,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3.5),
              boxShadow: [
                BoxShadow(
                  color: scanColor.withValues(alpha: 0.5),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: scanColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),

        // 3. Pick from Gallery
        AnimatedPressable(
          onPressed: onPickGallery,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Icon(
              Icons.photo_library_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}
