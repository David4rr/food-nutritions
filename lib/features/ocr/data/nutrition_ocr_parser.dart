import '../domain/ocr_nutrition_result.dart';

class NutritionOcrParser {
  const NutritionOcrParser();

  OcrNutritionResult parse(String rawText, {String? imagePath}) {
    if (rawText.trim().isEmpty) {
      return OcrNutritionResult(
        rawText: rawText,
        imagePath: imagePath,
      );
    }

    final normalizedText = _normalizeOcrText(rawText);
    final rawLines = normalizedText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    double servingSize = 0.0;
    String servingUnit = 'g';
    double servingsPerContainer = 1.0;
    double calories = 0.0;
    double protein = 0.0;
    double fat = 0.0;
    double saturatedFat = 0.0;
    double carbs = 0.0;
    double sugars = 0.0;
    double sodium = 0.0;

    // 1. Extract Komposisi / Ingredients
    final ingredients = _extractIngredients(normalizedText);

    // 2. Extract Candidate Product & Brand names
    final nameAndBrand = _extractCandidateNames(rawLines);
    final productName = nameAndBrand.$1;
    final brand = nameAndBrand.$2;

    // 3. Extract Serving Size & Servings Per Container
    final servingData = _extractServingData(rawLines);
    servingSize = servingData.size;
    servingUnit = servingData.unit;
    servingsPerContainer = servingData.servings;

    // 4. Extract Nutrients with Strict Row Segmentation
    calories = _extractEnergy(rawLines);
    fat = _extractMacro(
      lines: rawLines,
      primaryKeywords: ['lemak total', 'total fat', 'lemak', 'fat'],
      excludeKeywords: ['lemak jenuh', 'saturated', 'lemak trans', 'trans fat', 'energi dari lemak', 'dari lemak', 'lemak tak jenuh'],
    );
    saturatedFat = _extractMacro(
      lines: rawLines,
      primaryKeywords: ['lemak jenuh', 'saturated fat', 'sat fat', 'lemak jenun', 'lemak jenuh/saturated'],
      excludeKeywords: ['tidak jenuh', 'tak jenuh', 'unsaturated'],
    );
    protein = _extractMacro(
      lines: rawLines,
      primaryKeywords: ['protein', 'proteln', 'proteina'],
      excludeKeywords: [],
    );
    carbs = _extractMacro(
      lines: rawLines,
      primaryKeywords: ['karbohidrat total', 'total carbohydrate', 'total carbs', 'karbohidrat', 'carbohydrate', 'karbo', 'carbs'],
      excludeKeywords: ['serat pangan', 'dietary fiber', 'serat'],
    );
    sugars = _extractMacro(
      lines: rawLines,
      primaryKeywords: ['gula total', 'total sugars', 'total sugar', 'gula', 'sugars', 'sugar', 'sukrosa'],
      excludeKeywords: ['alkohol gula', 'sugar alcohol'],
    );
    sodium = _extractSodium(rawLines);

    return OcrNutritionResult(
      productName: productName ?? '',
      brand: brand,
      servingSize: servingSize > 0 ? servingSize : 100.0,
      servingUnit: servingUnit,
      servingsPerContainer: servingsPerContainer > 0 ? servingsPerContainer : 1.0,
      calories: calories,
      protein: protein,
      fat: fat,
      saturatedFat: saturatedFat,
      carbohydrates: carbs,
      sugars: sugars,
      sodium: sodium,
      ingredients: ingredients,
      rawText: rawText,
      imagePath: imagePath,
    );
  }

  String _normalizeOcrText(String text) {
    var t = text;
    // 1. Normalize colon and separators
    t = t.replaceAll('：', ':');

    // 2. Strip leading line noise like "4e LsProtein" -> "LsProtein", "moAK Garam" -> "Garam", "TO Garam" -> "Garam"
    t = t.replaceAll(RegExp(r'^\s*[0-9]+[a-zA-Z]{1,3}\s+', multiLine: true), '');
    t = t.replaceAll(RegExp(r'^\s*(?:moAK|TO|BU|COUA|TRATI|ONG)\s+', multiLine: true, caseSensitive: false), '');

    // 3. Normalize OCR comma in decimals e.g. "2,5 g" -> "2.5 g"
    t = t.replaceAllMapped(
      RegExp(r'(\d+),(\d+)'),
      (m) => '${m.group(1)}.${m.group(2)}',
    );

    // 4. Separate glued letters and numbers e.g. "Karbohidratotal0g" -> "Karbohidratotal 0g", "0Kkal" -> "0 Kkal"
    t = t.replaceAllMapped(
      RegExp(r'([a-zA-Z]+)(\d+[\.,]?\d*(?:kkal|kcal|cal|kj|mg|g|gr|gram|ml|l|saj)?)', caseSensitive: false),
      (m) => '${m.group(1)} ${m.group(2)}',
    );
    t = t.replaceAllMapped(
      RegExp(r'(\d+[\.,]?\d*)([a-zA-Z]+)'),
      (m) => '${m.group(1)} ${m.group(2)}',
    );

    // 5. Fix digit glued with sajan e.g. "15Sajan" or "15 Sajan" -> "1.5 sajian"
    t = t.replaceAllMapped(
      RegExp(r'\b15\s*(?:sajan|sajian)\b', caseSensitive: false),
      (m) => '1.5 sajian',
    );

    // 6. Fix OCR '9' after digit 0 representing 'g' e.g. "09 0%" -> "0g 0%"
    t = t.replaceAllMapped(
      RegExp(r'\b09\b(?=\s*(?:\d+%)|\s*$)'),
      (m) => '0g',
    );

    // 7. Normalize common Indonesian OCR typos on packaging labels:
    t = t.replaceAll(RegExp(r'\btakaran\s+sa\b', caseSensitive: false), 'takaran saji');
    t = t.replaceAll(RegExp(r'\btakaran\s+sai\b', caseSensitive: false), 'takaran saji');
    t = t.replaceAll(RegExp(r'\blemak\s+tota\b', caseSensitive: false), 'lemak total');
    t = t.replaceAll(RegExp(r'\blemak\s+jen\w*', caseSensitive: false), 'lemak jenuh');
    t = t.replaceAll(RegExp(r'\bsajan\b', caseSensitive: false), 'sajian');

    // 8. Normalize OCR letter O/o to 0 when next to units
    t = t.replaceAllMapped(
      RegExp(r'\b[Oo](\s*(?:g|gr|gram|mg|kkal|kcal|cal|ml|kj|%))\b', caseSensitive: false),
      (m) => '0${m.group(1)}',
    );
    return t;
  }

  ({double size, String unit, double servings}) _extractServingData(List<String> lines) {
    double size = 0.0;
    String unit = 'g';
    double servings = 1.0;

    // 1. Extract Servings Per Container (Porsi)
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      final nextLine = i + 1 < lines.length ? lines[i + 1] : '';

      final isServingsCountLine = lower.contains('sajian per kemasan') ||
          lower.contains('servings per container') ||
          lower.contains('jumlah sajian') ||
          lower.contains('porsi per kemasan') ||
          lower.contains('sajian per wadah') ||
          lower.contains('jumlah per kemasan');

      if (isServingsCountLine) {
        var match = RegExp(
          r'(?:sekitar|about|kurang lebih|±)?\s*(\d+[\.,]?\d*)',
          caseSensitive: false,
        ).firstMatch(line);

        if (match != null) {
          final val = _parseDouble(match.group(1));
          if (val > 0) servings = val;
        } else {
          match = RegExp(r'(\d+[\.,]?\d*)').firstMatch(nextLine);
          if (match != null) {
            final val = _parseDouble(match.group(1));
            if (val > 0) servings = val;
          }
        }
      }
    }

    // 2. Extract Serving Size (Takaran Saji)
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      final prevLine = i > 0 ? lines[i - 1] : '';
      final nextLine = i + 1 < lines.length ? lines[i + 1] : '';
      final nextLine2 = i + 2 < lines.length ? lines[i + 2] : '';

      final isServingSizeLine = lower.contains('takaran saji') ||
          lower.contains('takaran sai') ||
          lower.contains('serving size') ||
          lower.contains('ukuran porsi') ||
          lower.contains('porsi saji') ||
          lower.contains('takaran per') ||
          (lower.contains('sajian per') && !lower.contains('kemasan') && !lower.contains('wadah'));

      if (isServingSizeLine && size == 0.0) {
        // Forward check first (current line + next lines)
        final forwardText = '$line $nextLine $nextLine2';
        var matches = RegExp(
          r'(\d+[\.,]?\d*)\s*(g|gr|gram|ml|l|liter)\b',
          caseSensitive: false,
        ).allMatches(forwardText).toList();

        // Backward check if value was above label (e.g. ":250 ml" before "Takaran Sai")
        if (matches.isEmpty && prevLine.isNotEmpty) {
          matches = RegExp(
            r'(\d+[\.,]?\d*)\s*(g|gr|gram|ml|l|liter)\b',
            caseSensitive: false,
          ).allMatches(prevLine).toList();
        }

        if (matches.isNotEmpty) {
          final m = matches.first;
          size = _parseDouble(m.group(1));
          final unitStr = m.group(2)?.toLowerCase() ?? 'g';
          if (unitStr == 'l' || unitStr == 'liter') {
            size *= 1000;
            unit = 'ml';
          } else {
            unit = unitStr.startsWith('m') ? 'ml' : 'g';
          }
        }
      }
    }

    // 3. Fallback: Search for volume (ml/l) anywhere before ingredients
    if (size == 0.0) {
      for (final line in lines) {
        if (line.toLowerCase().contains('komposisi') || line.toLowerCase().contains('ingredients')) break;
        final volMatch = RegExp(
          r'(\d+[\.,]?\d*)\s*(ml|l|liter)\b',
          caseSensitive: false,
        ).firstMatch(line);

        if (volMatch != null) {
          final val = _parseDouble(volMatch.group(1));
          final unitStr = volMatch.group(2)?.toLowerCase() ?? 'ml';
          size = (unitStr == 'l' || unitStr == 'liter') ? (val * 1000) : val;
          unit = 'ml';
          break;
        }
      }
    }

    // 4. Fallback: Search top lines for standalone volume/weight before JUMLAH PER SAJIAN
    if (size == 0.0) {
      for (final line in lines.take(8)) {
        final lower = line.toLowerCase();
        if (lower.contains('jumlah per sajian') || lower.contains('energi total')) break;
        final match = RegExp(
          r'(\d+[\.,]?\d*)\s*(g|gr|gram|ml|l|liter)\b',
          caseSensitive: false,
        ).firstMatch(line);

        if (match != null) {
          size = _parseDouble(match.group(1));
          final unitStr = match.group(2)?.toLowerCase() ?? 'g';
          unit = unitStr.startsWith('m') ? 'ml' : 'g';
          break;
        }
      }
    }

    // 5. Fallback: Berat Bersih / Netto
    if (size == 0.0) {
      for (final line in lines) {
        final lower = line.toLowerCase();
        final isNettoLine = lower.contains('berat bersih') ||
            lower.contains('isi bersih') ||
            lower.contains('netto') ||
            lower.contains('net wt') ||
            lower.contains('net weight');

        if (isNettoLine) {
          final match = RegExp(
            r'(\d+[\.,]?\d*)\s*(g|gr|gram|ml|l|liter|kg)\b',
            caseSensitive: false,
          ).firstMatch(line);

          if (match != null) {
            final netVal = _parseDouble(match.group(1));
            final netUnit = match.group(2)?.toLowerCase() ?? 'g';
            if (netUnit == 'kg' || netUnit == 'l' || netUnit == 'liter') {
              size = netVal * 1000;
              unit = (netUnit == 'kg') ? 'g' : 'ml';
            } else {
              size = netVal;
              unit = netUnit.startsWith('m') ? 'ml' : 'g';
            }
            break;
          }
        }
      }
    }

    return (size: size, unit: unit, servings: servings);
  }

  double _extractEnergy(List<String> lines) {
    // Strategy 1: Line with 'energi total' / 'kalori'
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      if (lower.contains('kebutuhan energi') ||
          lower.contains('energi anda') ||
          lower.contains('berdasarkan kebutuhan') ||
          lower.contains('persen akg') ||
          lower.contains('percent daily') ||
          lower.contains('komposisi') ||
          lower.contains('ingredients')) {
        continue;
      }

      final isEnergy = lower.contains('energi total') ||
          lower.contains('energy total') ||
          lower.contains('total energy') ||
          lower.contains('kalori') ||
          lower.contains('calories') ||
          lower.contains('energl total') ||
          (lower.contains('energi') && !lower.contains('dari lemak') && !lower.contains('from fat'));

      if (!isEnergy) continue;

      final nextLine = i + 1 < lines.length ? lines[i + 1] : '';
      final nextLine2 = i + 2 < lines.length ? lines[i + 2] : '';
      var rowText = '$line $nextLine $nextLine2';

      final fatIdx = rowText.toLowerCase().indexOf(RegExp(r'energi\s+dari\s+lemak|energy\s+from\s+fat|dari\s+lemak|from\s+fat'));
      if (fatIdx != -1) {
        rowText = rowText.substring(0, fatIdx);
      }

      // Explicit kkal match
      final kcalMatch = RegExp(
        r'(\d+[\.,]?\d*)\s*(kkal|kcal|cal)\b',
        caseSensitive: false,
      ).firstMatch(rowText);

      if (kcalMatch != null) {
        return _parseDouble(kcalMatch.group(1));
      }

      // Explicit kJ match
      final kjMatch = RegExp(r'(\d+[\.,]?\d*)\s*kj\b', caseSensitive: false).firstMatch(rowText);
      if (kjMatch != null) {
        return _parseDouble(kjMatch.group(1)) / 4.184;
      }
    }

    // Strategy 2: Document-Level search for explicit kkal value (excluding footer 2150)
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('kebutuhan energi') ||
          lower.contains('energi anda') ||
          lower.contains('berdasarkan kebutuhan') ||
          lower.contains('persen akg') ||
          lower.contains('2150') ||
          lower.contains('2000')) {
        continue;
      }

      final kcalMatch = RegExp(
        r'(\d+[\.,]?\d*)\s*(kkal|kcal|cal)\b',
        caseSensitive: false,
      ).firstMatch(line);

      if (kcalMatch != null) {
        return _parseDouble(kcalMatch.group(1));
      }
    }

    return 0.0;
  }

  double _extractMacro({
    required List<String> lines,
    required List<String> primaryKeywords,
    required List<String> excludeKeywords,
  }) {
    // Strategy 1: Look forward on keyword row (current line, next 2 lines)
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      if (lower.contains('komposisi') ||
          lower.contains('ingredients') ||
          lower.contains('kebutuhan energi') ||
          lower.contains('persen akg')) {
        continue;
      }

      final matchedKw = primaryKeywords.cast<String?>().firstWhere(
            (k) => k != null && lower.contains(k),
            orElse: () => null,
          );
      if (matchedKw == null) continue;

      final isExcluded = excludeKeywords.any((ex) => lower.contains(ex));
      if (isExcluded) continue;

      final nextLine = i + 1 < lines.length ? lines[i + 1] : '';
      final nextLine2 = i + 2 < lines.length ? lines[i + 2] : '';
      var rowText = '$line $nextLine $nextLine2';

      // Find where keyword starts to ignore leading noise (e.g. "4e LsProtein" -> starts at "Protein")
      final kwIdx = rowText.toLowerCase().indexOf(matchedKw);
      final afterKeyword = kwIdx != -1 ? rowText.substring(kwIdx) : rowText;

      var textAfter = afterKeyword.length > matchedKw.length
          ? afterKeyword.substring(matchedKw.length)
          : afterKeyword;

      // Truncate before next nutrient keyword so values from next rows never bleed
      const nextNutrientMarkers = [
        'lemak total',
        'total fat',
        'lemak jenuh',
        'saturated',
        'protein',
        'karbohidrat',
        'carbohydrate',
        'gula',
        'sugars',
        'garam',
        'natrium',
        'sodium',
        'energi',
        'energy',
        'kalori',
        'calories',
      ];

      final currentNutrientAliases = primaryKeywords.map((k) => k.toLowerCase()).toList();
      final lowerTextAfter = textAfter.toLowerCase();
      int earliestNextMarker = textAfter.length;
      for (final marker in nextNutrientMarkers) {
        if (currentNutrientAliases.any((alias) => alias.contains(marker) || marker.contains(alias))) continue;
        final idx = lowerTextAfter.indexOf(marker);
        if (idx != -1 && idx < earliestNextMarker) {
          earliestNextMarker = idx;
        }
      }
      textAfter = textAfter.substring(0, earliestNextMarker);

      // 1. Explicit gram unit (e.g. "4.5 g", "0g", "2,5 gram", "0 g")
      final unitMatch = RegExp(
        r'(\d+[\.,]?\d*)\s*(?<![m\w])(?:g|gr|gram)\b(?!\s*%)',
        caseSensitive: false,
      ).firstMatch(textAfter);

      if (unitMatch != null) {
        return _parseDouble(unitMatch.group(1));
      }

      // 2. If no unit, strip % and take first number that appears after the keyword (and before next field)
      final cleanText = textAfter
          .replaceAll(RegExp(r'\([^)]*\)'), ' ')
          .replaceAll(RegExp(r'\d+[\.,]?\d*\s*%(?:\s*akg)?', caseSensitive: false), ' ');

      final numMatch = RegExp(r'(\d+[\.,]?\d*)').firstMatch(cleanText);
      if (numMatch != null) {
        final val = _parseDouble(numMatch.group(1));
        // Reject numbers that look like volumes/calories (e.g. 250 ml or 100 kkal)
        if (val < 150) {
          return val;
        }
      }
    }

    // Strategy 2: If document has separated column of 0g values, check if all gram values in value block are 0g
    final allGramMatches = lines
        .where((l) => !l.toLowerCase().contains('takaran') && !l.toLowerCase().contains('sajian'))
        .map((l) => RegExp(r'(\d+[\.,]?\d*)\s*(?<![m\w])(?:g|gr|gram)\b(?!\s*%)', caseSensitive: false).firstMatch(l))
        .whereType<RegExpMatch>()
        .map((m) => _parseDouble(m.group(1)))
        .toList();

    if (allGramMatches.isNotEmpty && allGramMatches.every((val) => val == 0.0)) {
      return 0.0;
    }

    return 0.0;
  }

  double _extractSodium(List<String> lines) {
    final keywords = [
      'garam (natrium)',
      'natrium (garam)',
      'garam/natrium',
      'natrium',
      'sodium',
      'garam',
      'salt',
    ];

    // Strategy 1: Look around sodium keyword line (forward)
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      if (lower.contains('komposisi') ||
          lower.contains('ingredients') ||
          lower.contains('kebutuhan energi') ||
          lower.contains('persen akg') ||
          lower.contains('tepung') ||
          lower.contains('minyak') ||
          lower.contains('gula pasir') ||
          lower.contains('pengemulsi')) {
        continue;
      }

      final matchesKeyword = keywords.any((k) => lower.contains(k));
      if (!matchesKeyword) continue;

      final nextLine = i + 1 < lines.length ? lines[i + 1] : '';
      final nextLine2 = i + 2 < lines.length ? lines[i + 2] : '';
      final rowText = '$line $nextLine $nextLine2';

      // 1. Explicit unit (mg, miligram, g, gr, gram)
      final unitMatch = RegExp(
        r'(\d+[\.,]?\d*)\s*(mg|miligram|g|gr|gram)\b(?!\s*%)',
        caseSensitive: false,
      ).firstMatch(rowText);

      if (unitMatch != null) {
        final val = _parseDouble(unitMatch.group(1));
        final unit = unitMatch.group(2)?.toLowerCase() ?? 'mg';
        if (unit == 'g' || unit == 'gr' || unit == 'gram') {
          return val * 1000;
        }
        return val;
      }
    }

    // Strategy 2: Document-Level search for explicit mg / miligram value (excluding ingredients)
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('komposisi') || lower.contains('ingredients')) continue;

      final unitMatch = RegExp(
        r'(\d+[\.,]?\d*)\s*(mg|miligram)\b(?!\s*%)',
        caseSensitive: false,
      ).firstMatch(line);

      if (unitMatch != null) {
        return _parseDouble(unitMatch.group(1));
      }
    }

    return 0.0;
  }

  String? _extractIngredients(String rawText) {
    final pattern = RegExp(
      r'(?:komposisi|ingredients|bahan-bahan|daftar bahan)\s*[:;]?\s*(.+)',
      caseSensitive: false,
      dotAll: true,
    );
    final match = pattern.firstMatch(rawText);
    if (match == null) return null;

    String content = match.group(1) ?? '';
    final stopMarkers = [
      'informasi nilai gizi',
      'nutrition facts',
      'diproduksi oleh',
      'manufactured by',
      'didistribusikan oleh',
      'distributed by',
      'bpom ri',
      'kode produksi',
      'baik digunakan',
      'best before',
      'simpan di',
      'petunjuk penyimpanan',
      'layanan konsumen',
      'customer care',
      'halal',
    ];

    int earliestStop = content.length;
    final lowerContent = content.toLowerCase();
    for (final marker in stopMarkers) {
      final idx = lowerContent.indexOf(marker);
      if (idx != -1 && idx < earliestStop) {
        earliestStop = idx;
      }
    }

    content = content.substring(0, earliestStop).trim();
    content = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (content.length > 5) {
      return content;
    }
    return null;
  }

  (String?, String?) _extractCandidateNames(List<String> lines) {
    // Left blank by default so user can fill the exact product and brand name
    return (null, null);
  }

  double _parseDouble(String? text) {
    if (text == null || text.trim().isEmpty) return 0.0;
    final normalized = text.replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0.0;
  }
}
