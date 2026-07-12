import 'package:flutter/material.dart';
import '../domain/analytics_engine.dart';
import 'share_templates.dart';
import 'analytics_share_service.dart';

class ShareSheet extends StatefulWidget {
  const ShareSheet({super.key, required this.data});
  final AnalyticsData data;

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  final AnalyticsShareService _shareService = AnalyticsShareService();
  final PageController _pageController = PageController(viewportFraction: 0.85);

  bool _isProcessing = false;
  bool _isTransparent = false;
  int _currentIndex = 0;

  Widget _buildSelectedCard() {
    switch (_currentIndex) {
      case 0:
        return SummaryShareCard(
          data: widget.data,
          isTransparent: _isTransparent,
        );
      case 1:
        return TrendShareCard(data: widget.data, isTransparent: _isTransparent);
      case 2:
        return MacroShareCard(data: widget.data, isTransparent: _isTransparent);
      case 3:
        return RadarShareCard(data: widget.data, isTransparent: _isTransparent);
      default:
        return SummaryShareCard(
          data: widget.data,
          isTransparent: _isTransparent,
        );
    }
  }

  Future<void> _handleShare() async {
    setState(() => _isProcessing = true);
    final bytes = await _shareService.capture();
    setState(() => _isProcessing = false);
    if (bytes != null && mounted) {
      if (_isTransparent) {
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
      if (_isTransparent) {
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
        color: _isTransparent
            ? const Color(0xFF1C1C1E)
            : Colors
                  .white, // Dark background when transparent mode is active to show white text
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
                  color: _isTransparent ? Colors.white : Colors.black87,
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
                        isTransparent: _isTransparent,
                        showWatermark: true,
                      );
                      break;
                    case 1:
                      card = TrendShareCard(
                        data: widget.data,
                        isTransparent: _isTransparent,
                        showWatermark: true,
                      );
                      break;
                    case 2:
                      card = MacroShareCard(
                        data: widget.data,
                        isTransparent: _isTransparent,
                        showWatermark: true,
                      );
                      break;
                    case 3:
                      card = RadarShareCard(
                        data: widget.data,
                        isTransparent: _isTransparent,
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
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isTransparent
                              ? Colors.transparent
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                          border: _isTransparent
                              ? null
                              : Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              if (_isTransparent)
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _CheckerboardPainter(),
                                  ),
                                ),
                              FittedBox(
                                fit: BoxFit.contain,
                                child: UnconstrainedBox(
                                  child: isSelected
                                      ? _shareService.wrap(card)
                                      : card,
                                ),
                              ),
                            ],
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
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Dengan Latar')),
                  ButtonSegment(value: true, label: Text('Transparan')),
                ],
                selected: {_isTransparent},
                onSelectionChanged: (set) {
                  setState(() => _isTransparent = set.first);
                },
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

class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = const Color(0xFFE0E0E0);
    final paint2 = Paint()..color = Colors.white;
    const double squareSize = 20.0;
    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        final isEven =
            ((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
