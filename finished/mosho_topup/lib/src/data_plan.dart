import 'network.dart';

final class DataPlan {
  const DataPlan({
    required this.id,
    required this.network,
    required this.name,
    required this.amountInKobo,
    required this.validityDays,
  });

  final String id;
  final Network network;
  final String name;
  final int amountInKobo;
  final int validityDays;

  @override
  String toString() =>
      'DataPlan($id, ${network.label} $name, $amountInKobo kobo, $validityDays days)';
}
