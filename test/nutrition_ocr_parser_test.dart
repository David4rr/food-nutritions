import 'package:flutter_test/flutter_test.dart';
import 'package:food_nutritions/features/ocr/data/nutrition_ocr_parser.dart';

void main() {
  group('NutritionOcrParser', () {
    const parser = NutritionOcrParser();

    test('parses Indonesian nutrition facts with serving size, servings per container, and macros', () {
      const sampleOcrText = '''
INFORMASI NILAI GIZI
Takaran Saji: 1 bungkus (30 g)
4 Sajian per Kemasan

JUMLAH PER SAJIAN
Energi Total 150 kkal
Energi dari Lemak 45 kkal
Lemak Total 5 g
Lemak Jenuh 2.5 g
Protein 3 g
Karbohidrat Total 22 g
Gula 8 g
Garam (Natrium) 120 mg

KOMPOSISI:
Tepung terigu, gula pasir, minyak nabati, susu bubuk skim, garam, pengemulsi lesitin kedelai.
Diproduksi oleh: PT Makanan Enak Indonesia
BPOM RI MD 123456789
''';

      final result = parser.parse(sampleOcrText);

      expect(result.servingSize, equals(30.0));
      expect(result.servingUnit, equals('g'));
      expect(result.servingsPerContainer, equals(4.0));
      expect(result.calories, equals(150.0));
      expect(result.fat, equals(5.0));
      expect(result.saturatedFat, equals(2.5));
      expect(result.protein, equals(3.0));
      expect(result.carbohydrates, equals(22.0));
      expect(result.sugars, equals(8.0));
      expect(result.sodium, equals(120.0));
      expect(result.ingredients, contains('Tepung terigu, gula pasir, minyak nabati'));
      expect(result.ingredients, isNot(contains('Diproduksi oleh')));

      final viewData = result.toProductViewData();
      expect(viewData.servingSize, equals('30 g'));
      expect(viewData.quantity, equals('120 g'));
      // 150 kcal per 30g = 500 kcal per 100g
      expect(viewData.calories, equals(500.0));
      expect(viewData.protein, equals(10.0));
      expect(viewData.ingredients, contains('Tepung terigu'));
    });

    test('parses beverage with volume in ml and Netto', () {
      const sampleLiquidText = '''
Ultra Milk Rasa Cokelat
INFORMASI NILAI GIZI
Takaran Saji: 250 ml
1 Sajian per Kemasan

Energi Total: 160 kkal
Lemak Total: 4.5 g
Lemak Jenuh: 3 g
Protein: 8 g
Karbohidrat: 24 g
Gula Total: 18 g
Natrium: 95 mg

Komposisi: Susu sapi segar (90%), sukrosa, kakao bubuk (0.9%), penstabil nabati, perisa sintetik cokelat.
''';

      final result = parser.parse(sampleLiquidText);

      expect(result.servingSize, equals(250.0));
      expect(result.servingUnit, equals('ml'));
      expect(result.servingsPerContainer, equals(1.0));
      expect(result.calories, equals(160.0));
      expect(result.protein, equals(8.0));
      expect(result.sugars, equals(18.0));
      expect(result.sodium, equals(95.0));
      expect(result.ingredients, contains('Susu sapi segar (90%)'));

      final viewData = result.toProductViewData();
      expect(viewData.servingSize, equals('250 ml'));
      expect(viewData.quantity, equals('250 ml'));
      // 160 kcal per 250ml = 64 kcal per 100ml
      expect(viewData.calories, equals(64.0));
    });

    test('accurately parses nutrient grams while ignoring % AKG and Energi dari Lemak', () {
      const sampleAkgText = '''
INFORMASI NILAI GIZI
Ukuran Porsi: 40g
Jumlah Sajian Per Kemasan: Sekitar 2

JUMLAH PER SAJIAN
Energi Total 190 kkal 9% AKG
Energi dari Lemak 70 kkal
Lemak Total 8g 12% AKG
Lemak Jenuh 4g 20% AKG
Protein 4g 7% AKG
Karbohidrat Total 26g 8% AKG
Gula Total 14g
Garam (Natrium) 160mg 11% AKG

KOMPOSISI:
Biji gandum utuh, oat, gula aren, madu murni, minyak nabati, perisa alami vanilla.
''';

      final result = parser.parse(sampleAkgText);

      expect(result.servingSize, equals(40.0));
      expect(result.servingUnit, equals('g'));
      expect(result.servingsPerContainer, equals(2.0));
      // Ensures 190 is picked, not 9 (% AKG) or 70 (lemak)
      expect(result.calories, equals(190.0));
      // Ensures 8 is picked, not 12 (% AKG)
      expect(result.fat, equals(8.0));
      // Ensures 4 is picked, not 20 (% AKG)
      expect(result.saturatedFat, equals(4.0));
      // Ensures 4 is picked, not 7 (% AKG)
      expect(result.protein, equals(4.0));
      // Ensures 26 is picked, not 8 (% AKG)
      expect(result.carbohydrates, equals(26.0));
      expect(result.sugars, equals(14.0));
      // Ensures 160 is picked, not 11 (% AKG)
      expect(result.sodium, equals(160.0));
      expect(result.ingredients, contains('Biji gandum utuh, oat, gula aren'));
    });

    test('parses multi-line split column OCR where labels and numbers are separated', () {
      const splitColumnText = '''
INFORMASI NILAI GIZI / NUTRITION FACTS
Takaran Saji / Serving Size
35 g
Jumlah Sajian Per Kemasan
3
JUMLAH PER SAJIAN / AMOUNT PER SERVING
Energi Total / Total Energy
140 kkal
Lemak Total / Total Fat
6 g
Lemak Jenuh / Saturated Fat
2.5 g
Protein
3 g
Karbohidrat Total / Total Carbohydrate
18 g
Gula / Sugars
5 g
Garam (Natrium) / Sodium
75 mg
''';

      final result = parser.parse(splitColumnText);

      expect(result.servingSize, equals(35.0));
      expect(result.servingsPerContainer, equals(3.0));
      expect(result.calories, equals(140.0));
      expect(result.fat, equals(6.0));
      expect(result.saturatedFat, equals(2.5));
      expect(result.protein, equals(3.0));
      expect(result.carbohydrates, equals(18.0));
      expect(result.sugars, equals(5.0));
      expect(result.sodium, equals(75.0));
    });

    test('preserves 0 values accurately without cross-polluting from adjacent lines', () {
      const zeroValuesText = '''
INFORMASI NILAI GIZI
Takaran Saji 200 ml
1 Sajian per Kemasan

JUMLAH PER SAJIAN
Energi Total 0 kkal
Lemak Total 0 g 0%
Lemak Jenuh 0 g 0%
Protein 0 g 0%
Karbohidrat Total 0 g 0%
Gula 0 g
Garam (Natrium) 15 mg 1%
''';

      final result = parser.parse(zeroValuesText);

      expect(result.servingSize, equals(200.0));
      expect(result.servingUnit, equals('ml'));
      expect(result.servingsPerContainer, equals(1.0));
      expect(result.calories, equals(0.0));
      expect(result.fat, equals(0.0));
      expect(result.saturatedFat, equals(0.0));
      expect(result.protein, equals(0.0));
      expect(result.carbohydrates, equals(0.0));
      expect(result.sugars, equals(0.0));
      expect(result.sodium, equals(15.0));
    });

    test('ignores BPOM 2150 kkal footer and ingredients mentioning garam/natrium', () {
      const fullPackageText = '''
INFORMASI NILAI GIZI
Takaran Saji 20 g
5 Sajian per Kemasan

JUMLAH PER SAJIAN
Energi Total 100 kkal
Energi dari Lemak 30 kkal
Lemak Total 3.5 g 5%
Lemak Jenuh 1.5 g 8%
Protein 2 g 3%
Karbohidrat Total 15 g 5%
Gula 6 g
Garam (Natrium) 75 mg 5%

*Persen AKG berdasarkan kebutuhan energi 2150 kkal. Kebutuhan energi anda mungkin lebih tinggi atau lebih rendah.

KOMPOSISI:
Tepung terigu, gula pasir, minyak nabati, garam dapur (1%), pengembang natrium bikarbonat.
''';

      final result = parser.parse(fullPackageText);

      expect(result.calories, equals(100.0));
      expect(result.sodium, equals(75.0));
      expect(result.fat, equals(3.5));
      expect(result.saturatedFat, equals(1.5));
      expect(result.protein, equals(2.0));
      expect(result.carbohydrates, equals(15.0));
      expect(result.sugars, equals(6.0));
      expect(result.servingSize, equals(20.0));
      expect(result.servingsPerContainer, equals(5.0));
    });

    test('correctly parses user real-world ML Kit OCR output with split label-value blocks', () {
      const userOcrSample = '''
TRATI
SProtein
ONG
INFORMASI NILAI GIZI
:250 ml
Takaran Sai
1.5 Sajian per Kemasan
JUMLAH PER SAJIAN
Energi Total
BU
COUA
Lemak Total
Lemak Jenuh
Gula
moAK Garam (Natrium)
Karbohidrat Total
:0 kkal
0g
0g
0g
0g
%AKG
0%
0%
0%
0%
0g
20 mg 1%
Persen AKG berdasarkan kebutuhan
energi 2150 kkal. Kebutuhan energi Anda
mungkin lebih tingai atau lebih rendah.
''';

      final result = parser.parse(userOcrSample);

      expect(result.servingSize, equals(250.0));
      expect(result.servingUnit, equals('ml'));
      expect(result.servingsPerContainer, equals(1.5));
      expect(result.calories, equals(0.0));
      expect(result.fat, equals(0.0));
      expect(result.saturatedFat, equals(0.0));
      expect(result.protein, equals(0.0));
      expect(result.carbohydrates, equals(0.0));
      expect(result.sugars, equals(0.0));
      expect(result.sodium, equals(20.0));
    });

    test('parses highly challenging real-world OCR scan with typos and glued words', () {
      const challengingOcrText = '''
NeZERO
INFORMASI NILAI GIZI
Takaran Sa
15Sajan per kemasan
JUMLAH PER SAJAN
Energi Total
Lemak Tota
Lemak Jengh
4e LsProtein
250 ml
Gula
0Kkal
Karbohidratotal0g
GAKG
0g 0%
0g 0%
09 05%
0%
TO Garam NaN 20 mg 19%
''';

      final result = parser.parse(challengingOcrText);

      expect(result.servingSize, equals(250.0));
      expect(result.servingUnit, equals('ml'));
      expect(result.servingsPerContainer, equals(1.5));
      expect(result.calories, equals(0.0));
      expect(result.fat, equals(0.0));
      expect(result.saturatedFat, equals(0.0));
      expect(result.protein, equals(0.0));
      expect(result.carbohydrates, equals(0.0));
      expect(result.sugars, equals(0.0));
      expect(result.sodium, equals(20.0));
    });
  });
}
