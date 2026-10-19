/// Finds the customer's mobile number inside an SMS body.
///
/// Understands Arabic-Indic digits and the `+20` / `0020` prefixes, and never
/// matches a longer digit run (so an order number cannot be mistaken for it).
/// Returns the local 11-digit form (e.g. `01551610944`) or null.
String? extractPhoneNumber(String text) {
  const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
  final normalized = text.split('').map((c) {
    final i = arabicIndic.indexOf(c);
    return i == -1 ? c : '$i';
  }).join();

  final match = RegExp(
    r'(?<!\d)(?:\+?20|0020)?(0?1[0125]\d{8})(?!\d)',
  ).firstMatch(normalized);
  if (match == null) return null;

  final number = match.group(1)!;
  return number.startsWith('0') ? number : '0$number';
}
