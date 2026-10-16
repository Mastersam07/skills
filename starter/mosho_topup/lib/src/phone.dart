final _localOrInternational = RegExp(r'^(?:\+234|234|0)([789][01]\d{8})$');
final _normalized = RegExp(r'^\+234[789][01]\d{8}$');
final _separators = RegExp(r'[\s\-().]');

String normalizeNigerianPhone(String input) {
  final digits = input.replaceAll(_separators, '');
  final match = _localOrInternational.firstMatch(digits);
  if (match == null) {
    throw FormatException('Not a valid Nigerian mobile number', input);
  }
  return '+234${match.group(1)}';
}

bool isNormalizedNigerianPhone(String phone) => _normalized.hasMatch(phone);
