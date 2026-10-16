import 'data_plan.dart';

sealed class TopUpResult {
  const TopUpResult({required this.reference});

  final String reference;
}

final class TopUpSuccess extends TopUpResult {
  const TopUpSuccess({
    required super.reference,
    required this.phone,
    required this.plan,
  });

  final String phone;
  final DataPlan plan;
}

final class TopUpPending extends TopUpResult {
  const TopUpPending({required super.reference});
}

final class TopUpFailed extends TopUpResult {
  const TopUpFailed({required super.reference, required this.message});

  final String message;
}
