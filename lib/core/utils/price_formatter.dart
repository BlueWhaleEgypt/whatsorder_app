/*
|--------------------------------------------------------------------------
| PriceFormatter — "1,450 EGP" / "12.50 EGP".
|
| Whole amounts drop the decimals, fractional ones keep two.
|--------------------------------------------------------------------------
*/

class PriceFormatter {
  PriceFormatter._();

  static const String currency = 'EGP';

  static final RegExp _thousands = RegExp(r'\B(?=(\d{3})+(?!\d))');

  static String egp(double value) {
    final fixed = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts.first.replaceAllMapped(_thousands, (_) => ',');
    return '${[whole, ...parts.skip(1)].join('.')} $currency';
  }
}
