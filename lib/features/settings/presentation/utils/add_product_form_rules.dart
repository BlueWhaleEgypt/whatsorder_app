/*
|--------------------------------------------------------------------------
| AddProductFormRules — what counts as a valid add-product input.
|
| Pure functions, so the widgets only turn a failed rule into a message.
|--------------------------------------------------------------------------
*/

class AddProductFormRules {
  AddProductFormRules._();

  static bool hasText(String? value) => (value ?? '').trim().isNotEmpty;

  /// The price as a number, or `null` when it is empty, not a number, not
  /// finite (`NaN`, `Infinity`) or not greater than zero.
  static double? parsePrice(String? value) {
    final price = double.tryParse((value ?? '').trim());
    if (price == null || !price.isFinite || price <= 0) return null;
    return price;
  }
}
