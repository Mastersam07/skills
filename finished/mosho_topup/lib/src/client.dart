import 'data_plan.dart';
import 'fake_backend.dart';
import 'network.dart';
import 'phone.dart';
import 'top_up_result.dart';

class MoshoTopUp {
  MoshoTopUp({
    required String apiKey,
    this.latency = const Duration(milliseconds: 600),
  }) {
    if (apiKey.trim().isEmpty) {
      throw ArgumentError.value(apiKey, 'apiKey', 'must not be empty');
    }
  }

  final Duration latency;
  final FakeBackend _backend = FakeBackend.instance;

  Future<List<DataPlan>> plans({required Network network}) async {
    await Future<void>.delayed(latency);
    return _backend.plansFor(network);
  }

  Future<TopUpResult> buyData({
    required String phone,
    required String planId,
    required String reference,
  }) async {
    if (!isNormalizedNigerianPhone(phone)) {
      throw ArgumentError.value(
        phone,
        'phone',
        'must be in +234 format. Pass it through normalizeNigerianPhone() first',
      );
    }
    if (reference.trim().isEmpty) {
      throw ArgumentError.value(
        reference,
        'reference',
        'must not be empty. Create one with newReference()',
      );
    }
    await Future<void>.delayed(latency);
    return _backend.buy(phone: phone, planId: planId, reference: reference);
  }

  Future<TopUpResult> status(String reference) async {
    await Future<void>.delayed(latency);
    return _backend.status(reference);
  }
}
