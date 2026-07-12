import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';

class AnalyticsShareService {
  final repaintKey = GlobalKey();

  Widget wrap(Widget template) {
    return RepaintBoundary(key: repaintKey, child: template);
  }

  Future<Uint8List?> capture({double pixelRatio = 6.0}) async {
    try {
      // Perlu delay sedikit untuk memastikan frame ter-render sempurna
      await Future.delayed(const Duration(milliseconds: 50));

      final boundary =
          repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Capture Error: $e');
      return null;
    }
  }

  Future<void> share(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/analisis_nutrisi.png');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Hasil Analisis Nutrisiku dari Food Nutrition App');
  }

  Future<bool> saveToGallery(Uint8List bytes) async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final request = await Gal.requestAccess();
        if (!request) return false;
      }
      await Gal.putImageBytes(bytes, name: 'analisis_nutrisi.png');
      return true;
    } catch (e) {
      debugPrint('Save Gallery Error: $e');
      return false;
    }
  }
}
