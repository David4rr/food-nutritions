import 'package:flutter/material.dart';
import '../domain/analytics_engine.dart';
import 'share_templates.dart';
import 'analytics_share_service.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class ShareSheet extends StatefulWidget {
  const ShareSheet({super.key, required this.data});
  final AnalyticsData data;

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  final AnalyticsShareService _shareService = AnalyticsShareService();
  final PageController _pageController = PageController(viewportFraction: 0.85);
  final ImagePicker _picker = ImagePicker();

  bool _isProcessing = false;
  bool _isBgTransparent = false;
  Color _cardColor = Colors.white;
  Uint8List? _bgImageBytes;
  int _currentIndex = 0;

  Future<void> _handleShare() async {
    setState(() => _isProcessing = true);
    final bytes = await _shareService.capture();
    setState(() => _isProcessing = false);
    if (bytes != null && mounted) {
      if (_isBgTransparent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gambar transparan sering diubah menjadi latar hitam oleh WhatsApp. Gunakan Telegram atau tempel sebagai stiker Instagram!',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
      Navigator.pop(context);
      await _shareService.share(bytes);
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isProcessing = true);
    final bytes = await _shareService.capture();
    setState(() => _isProcessing = false);
    if (bytes != null && mounted) {
      final success = await _shareService.saveToGallery(bytes);
      if (_isBgTransparent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gambar transparan mungkin terlihat berlatar hitam di Galeri. Gunakan sebagai stiker di Instagram/TikTok untuk hasil terbaik!',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Berhasil disimpan ke Galeri' : 'Gagal menyimpan gambar',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 24, bottom: 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Pilih Kartu untuk Dibagikan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Carousel
            SizedBox(
              height: 340,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemCount: 4,
                itemBuilder: (context, index) {
                  // Inside the PageView, we ONLY wrap the currently active page with the RepaintBoundary.
                  // This guarantees we only capture the selected card and not the bleeding edges of other pages.
                  final isSelected = _currentIndex == index;

                  Widget card;
                  switch (index) {
                    case 0:
                      card = SummaryShareCard(
                        data: widget.data,
                        isTransparent: _isBgTransparent,
                        cardColor: _cardColor,
                        bgImageBytes: _bgImageBytes,
                        showWatermark: true,
                      );
                      break;
                    case 1:
                      card = TrendShareCard(
                        data: widget.data,
                        isTransparent: _isBgTransparent,
                        cardColor: _cardColor,
                        bgImageBytes: _bgImageBytes,
                        showWatermark: true,
                      );
                      break;
                    case 2:
                      card = MacroShareCard(
                        data: widget.data,
                        isTransparent: _isBgTransparent,
                        cardColor: _cardColor,
                        bgImageBytes: _bgImageBytes,
                        showWatermark: true,
                      );
                      break;
                    case 3:
                      card = RadarShareCard(
                        data: widget.data,
                        isTransparent: _isBgTransparent,
                        cardColor: _cardColor,
                        bgImageBytes: _bgImageBytes,
                        showWatermark: true,
                      );
                      break;
                    default:
                      card = const SizedBox.shrink();
                  }

                  return AnimatedScale(
                    scale: isSelected ? 1.0 : 0.9,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isBgTransparent
                                ? Colors.transparent
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                            border: _isBgTransparent
                                ? null
                                : Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: 1080,
                                  height: 1080,
                                  child: Center(
                                    child: isSelected
                                        ? _shareService.wrap(card)
                                        : card,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Toggle Transparent
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Warna Kartu', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<Color>(
                          segments: const [
                            ButtonSegment(value: Colors.white, label: Text('Putih')),
                            ButtonSegment(value: Colors.black, label: Text('Hitam')),
                            ButtonSegment(value: Colors.transparent, label: Text('Bening')),
                          ],
                          selected: {_cardColor},
                          onSelectionChanged: (set) => setState(() {
                             _cardColor = set.first;
                             if (_cardColor != Colors.transparent) {
                               // Optional: If they pick a solid color, do they want to keep the image?
                               // Usually yes, we tint it. But if they specifically pick a color maybe keep it.
                             }
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.image),
                        onPressed: () async {
                           final xfile = await _picker.pickImage(source: ImageSource.gallery);
                           if (xfile != null) {
                             final bytes = await xfile.readAsBytes();
                             setState(() {
                               _bgImageBytes = bytes;
                             });
                           }
                        }
                      ),
                      if (_bgImageBytes != null)
                        IconButton.filledTonal(
                          icon: const Icon(Icons.delete),
                          onPressed: () => setState(() => _bgImageBytes = null),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Latar Belakang', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Bawaan')),
                      ButtonSegment(value: true, label: Text('Transparan')),
                    ],
                    selected: {_isBgTransparent},
                    onSelectionChanged: (set) => setState(() {
                      _isBgTransparent = set.first;
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _handleShare,
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Bagikan ke Sosial Media'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2FB8A4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _handleSave,
                      icon: const Icon(Icons.save_alt_rounded),
                      label: const Text('Simpan ke Galeri'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
