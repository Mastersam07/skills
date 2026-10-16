final _thousands = RegExp(r'\B(?=(\d{3})+(?!\d))');

String formatNaira(int kobo) {
  final sign = kobo < 0 ? '-' : '';
  final naira = (kobo.abs() ~/ 100).toString().replaceAll(_thousands, ',');
  final remainder = kobo.abs() % 100;
  final fraction = remainder == 0 ? '' : '.${remainder.toString().padLeft(2, '0')}';
  return '$sign₦$naira$fraction';
}
