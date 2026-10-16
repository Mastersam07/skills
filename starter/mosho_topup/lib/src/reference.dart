import 'dart:math';

final _random = Random();

String newReference() {
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final noise = _random.nextInt(1 << 32).toRadixString(36);
  return 'mosho_${time}_$noise';
}
