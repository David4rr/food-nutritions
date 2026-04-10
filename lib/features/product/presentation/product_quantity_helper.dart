double? parseEstimatedGrams(String? quantity) {
  if (quantity == null || quantity.trim().isEmpty) return null;
  final text = quantity.toLowerCase().replaceAll(',', '.');
  final match = RegExp(
    r'([0-9]+(?:\.[0-9]+)?)\s*(kg|g|gr|gram|l|ml)',
  ).firstMatch(text);
  if (match == null) return null;

  final value = double.tryParse(match.group(1)!);
  final unit = match.group(2);
  if (value == null || unit == null) return null;

  switch (unit) {
    case 'kg':
      return value * 1000;
    case 'l':
      return value * 1000;
    case 'g':
    case 'gr':
    case 'gram':
    case 'ml':
      return value;
    default:
      return null;
  }
}
