/// Normalises a phone number the way the backend expects it: surrounding
/// whitespace and spaces are removed, and local numbers starting with `0`
/// get the country prefix `2` (`01012345678` → `201012345678`). Numbers
/// already starting with `20`, and any other input, are returned unchanged.
String normalizePhone(String phone) {
  phone = phone.trim().replaceAll(' ', '');

  if (phone.startsWith('0')) {
    return '2$phone';
  }

  return phone;
}
