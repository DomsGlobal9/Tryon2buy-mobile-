/// The backend spells two categories its own way (`LEHANGA`, `KURTHI`).
/// Keys stay as the server wants them; this is the one place that turns a
/// key into what a shopper should read.
class CategoryNames {
  const CategoryNames._();

  static const _display = <String, String>{
    'SAREE': 'Saree',
    'LEHANGA': 'Lehenga',
    'LEHENGA': 'Lehenga',
    'ANARKALI': 'Anarkali',
    'KURTHI': 'Kurti',
    'KURTI': 'Kurti',
    'SHARARA': 'Sharara',
    'BLOUSE': 'Blouse',
    'DRESS': 'Dress',
  };

  /// "LEHANGA" → "Lehenga"; unknown keys are title-cased.
  static String display(String? key) {
    final k = key?.trim().toUpperCase();
    if (k == null || k.isEmpty) return 'Garment';
    return _display[k] ?? (k[0] + k.substring(1).toLowerCase());
  }
}
