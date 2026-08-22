import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../domain/ocr_nutrition_result.dart';
import 'nutrition_ocr_parser.dart';

class OcrService {
  OcrService({NutritionOcrParser? parser}) : _parser = parser ?? const NutritionOcrParser();

  final NutritionOcrParser _parser;
  static const MethodChannel _nativeChannel = MethodChannel('com.food_nutritions.ocr/recognize');

  Future<OcrNutritionResult> recognizeNutritionFromImage(String imagePath) async {
    String rawText = '';

    // 1. Try Google ML Kit Text Recognition plugin
    try {
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await textRecognizer.processImage(inputImage);
      rawText = recognizedText.text;
      await textRecognizer.close();
      if (kDebugMode) {
        debugPrint('MLKit recognized ${rawText.length} characters of text');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MLKit plugin recognition failed: $e');
      }
    }

    // 2. If ML Kit returned empty, fallback to native platform channel
    if (rawText.trim().isEmpty) {
      try {
        final nativeText = await _nativeChannel.invokeMethod<String>(
          'recognizeText',
          {'imagePath': imagePath},
        );
        if (nativeText != null && nativeText.trim().isNotEmpty) {
          rawText = nativeText;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Native channel OCR failed: $e');
        }
      }
    }

    if (kDebugMode) {
      debugPrint('=== OCR RAW TEXT OUTPUT ===\n$rawText\n===========================');
    }

    return _parser.parse(rawText, imagePath: imagePath);
  }
}
